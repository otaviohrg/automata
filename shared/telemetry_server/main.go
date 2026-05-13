package main

import (
	"context"
	"log"
	"math"
	"net"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "google.golang.org/grpc"
    pb "telemetry_server/proto"
)

var (
	messagesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "telemetry_messages_total",
			Help: "Total telemetry messages received per robot",
		}, []string{"robot_id"},
	)

	anomaliesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "telemetry_anomalies_total",
			Help: "Total anomaly alerts generated per robot and joint",
		}, []string{"robot_id", "joint_name"},
	)

	jointPosition = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "telemetry_joint_position_rad",
			Help: "Latest joint position in radians",
		}, []string{"robot_id", "joint_name"},
	)

	jointVelocity = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "telemetry_joint_velocity_rad_per_s",
			Help: "Latest joint velocity in radians per second",
		}, []string{"robot_id", "joint_name"},
	)
)

type server struct {
	pb.UnimplementedTelemetryServiceServer
}

func (s *server) PublishJointData(ctx context.Context, req *pb.JointTelemetry) (*pb.Ack, error) {
	messagesTotal.WithLabelValues(req.RobotId).Inc()

	for i, name := range req.JointNames {
		if i < len(req.Positions) {
			jointPosition.
			WithLabelValues(req.RobotId, name).
			Set(req.Positions[i])
		}
		if i < len(req.Velocities) {
			jointVelocity.
			WithLabelValues(req.RobotId, name).
			Set(req.Velocities[i])
		}
	}

	log.Printf("[%s] received %d joints at t=%.3f", req.RobotId, len(req.JointNames), req.Timestamp)

	return &pb.Ack{Success: true}, nil
}

func (s *server) StreamAlerts(req *pb.JointTelemetry, stream pb.TelemetryService_StreamAlertsServer) error {
	for i, name := range req.JointNames {
		if i >= len(req.Velocities) {
			continue
		}
		score := math.Abs(req.Velocities[i]) / 10.0

		if score > 0.7 {
			anomaliesTotal.WithLabelValues(req.RobotId, name).Inc()
			alert := &pb.AnomalyAlert{
				RobotId:		req.RobotId,
				Timestamp:		float64(time.Now().UnixMilli()) / 1000.0,
				JointName:		name,
				AnomalyScore:	score,
				IsFault:		score > 0.9,
			}
			if err := stream.Send(alert); err != nil {
				return err
			}
		}
	}
	return nil;
}

func main() {
	go func() {
		http.Handle("/metrics", promhttp.Handler())
		log.Println("metrics server listening on :9090")
		if err := http.ListenAndServe(":9090", nil); err != nil {
			log.Fatalf("metrics server failer: %v", err)
		}
	}()

	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterTelemetryServiceServer(s, &server{})

	log.Println("telemetry gRPC server listening on :50051")
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

