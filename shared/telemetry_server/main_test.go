package main

import (
	"context"
	//"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	pb "telemetry_server/proto"
)

type mockStream struct {
	alerts []*pb.AnomalyAlert
	pb.TelemetryService_StreamAlertsServer
}

func (m *mockStream) Send(alert *pb.AnomalyAlert) error {
	m.alerts = append(m.alerts, alert)
	return nil
}

func TestPublishJointData_returnSuccess(t *testing.T) {
	s := &server{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_success",
		Timestamp:  float64(time.Now().UnixMilli()) / 1000.0,
		JointNames: []string{"joint1", "joint2"},
		Positions:  []float64{1.0, 2.0},
		Velocities: []float64{0.1, 0.2},
		Efforts:    []float64{0.0, 0.0},
	}

	ack, err := s.PublishJointData(context.Background(), req)

	require.NoError(t, err)
	assert.True(t, ack.Success)
}

func TestPublishJointData_incrementsMessageCounter(t *testing.T) {
	s := &server{}
	robotID := "robot_counter"
	req := &pb.JointTelemetry{
		RobotId:    robotID,
		JointNames: []string{"joint1"},
		Positions:  []float64{0.0},
		Velocities: []float64{0.0},
	}

	_, err := s.PublishJointData(context.Background(), req)
	require.NoError(t, err)
	_, err = s.PublishJointData(context.Background(), req)
	require.NoError(t, err)

	count := testutil.ToFloat64(messagesTotal.WithLabelValues(robotID))
	assert.Equal(t, 2.0, count)
}

func TestPublishJointData_recordsJointPosition(t *testing.T) {
	s := &server{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_position",
		JointNames: []string{"joint1", "joint2"},
		Positions:  []float64{1.57, 3.14},
		Velocities: []float64{0.0, 0.0},
	}

	_, err := s.PublishJointData(context.Background(), req)
	require.NoError(t, err)

	assert.Equal(
		t,
		1.57,
		testutil.ToFloat64(jointPosition.WithLabelValues("robot_position", "joint1")),
	)
	assert.Equal(
		t,
		3.14,
		testutil.ToFloat64(jointPosition.WithLabelValues("robot_position", "joint2")),
	)
}

func TestPublishJointData_recordsJointVelocity(t *testing.T) {
	s := &server{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_velocity",
		JointNames: []string{"joint1"},
		Positions:  []float64{0.0},
		Velocities: []float64{2.5},
	}

	_, err := s.PublishJointData(context.Background(), req)
	require.NoError(t, err)

	assert.Equal(
		t,
		2.5,
		testutil.ToFloat64(jointVelocity.WithLabelValues("robot_velocity", "joint1")),
	)
}

func TestPublishJointData_handlesMoreJointsThanPositions(t *testing.T) {
	s := &server{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_mismatch",
		JointNames: []string{"joint1", "joint2", "joint3"},
		Positions:  []float64{1.0},
		Velocities: []float64{0.1, 0.2},
	}

	ack, err := s.PublishJointData(context.Background(), req)

	require.NoError(t, err)
	assert.True(t, ack.Success)
	assert.Equal(
		t,
		1.0,
		testutil.ToFloat64(jointPosition.WithLabelValues("robot_mismatch", "joint1")),
	)
}

func TestStreamAlerts_highVelocityTriggersAlert(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_alert",
		JointNames: []string{"joint1"},
		Velocities: []float64{9.5},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	require.Len(t, stream.alerts, 1)
	assert.Equal(t, "robot_alert", stream.alerts[0].RobotId)
	assert.Equal(t, "joint1", stream.alerts[0].JointName)
	assert.InDelta(t, 0.95, stream.alerts[0].AnomalyScore, 0.001)
	assert.True(t, stream.alerts[0].IsFault)
}

func TestStreamAlerts_lowVelocityNoAlert(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_no_alert",
		JointNames: []string{"joint1"},
		Velocities: []float64{0.5},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	assert.Empty(t, stream.alerts)
}

func TestStreamAlerts_borderlineVelocityIsAlert(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_border",
		JointNames: []string{"joint1"},
		Velocities: []float64{7.1},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	require.Len(t, stream.alerts, 1)
	assert.False(t, stream.alerts[0].IsFault)
}

func TestStreamAlerts_faultThresholdAt0point9(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_fault",
		JointNames: []string{"joint1"},
		Velocities: []float64{9.0},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	require.Len(t, stream.alerts, 1)
	assert.False(t, stream.alerts[0].IsFault)
}

func TestStreamAlerts_multipleJoints(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_multi",
		JointNames: []string{"joint1", "joint2", "joint3"},
		Velocities: []float64{9.5, 0.5, 8.0},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	require.Len(t, stream.alerts, 2)
	assert.Equal(t, "joint1", stream.alerts[0].JointName)
	assert.Equal(t, "joint3", stream.alerts[1].JointName)
}

func TestStreamAlerts_fewerVelocitiesThanJoints(t *testing.T) {
	s := &server{}
	stream := &mockStream{}
	req := &pb.JointTelemetry{
		RobotId:    "robot_fewer",
		JointNames: []string{"joint1", "joint2"},
		Velocities: []float64{9.5},
	}

	err := s.StreamAlerts(req, stream)

	require.NoError(t, err)
	require.Len(t, stream.alerts, 1)
	assert.Equal(t, "joint1", stream.alerts[0].JointName)
}
