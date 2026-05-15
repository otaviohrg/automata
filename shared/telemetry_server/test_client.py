#!/usr/bin/env python3
"""
Test client for the Go telemetry gRPC server.
Runs inside the helix-base container.
The server runs natively on the host.
network_mode: host in docker-compose means localhost resolves to the host.
"""

import sys
import time
import grpc

sys.path.insert(0, "/workspace/shared/telemetry_server")

from proto import telemetry_pb2 as pb
from proto import telemetry_pb2_grpc as pb_grpc


def run():
    channel = grpc.insecure_channel("localhost:50051")
    stub = pb_grpc.TelemetryServiceStub(channel)

    print("Sending 5 telemetry messages...")
    for i in range(5):
        req = pb.JointTelemetry(
            robot_id="test_arm",
            timestamp=time.time(),
            joint_names=["joint1", "joint2", "joint3", "joint4", "joint5", "joint6"],
            positions=[0.1 * i, 0.2 * i, 0.3 * i, 0.4 * i, 0.5 * i, 0.6 * i],
            velocities=[9.5, 0.1, 8.8, 0.2, 9.1, 0.3],
            efforts=[0.0] * 6,
        )
        ack = stub.PublishJointData(req)
        print(f"    message{i}: ack={ack.success}")
        time.sleep(0.1)

    print("\nStreaming anomaly alerts...")
    req = pb.JointTelemetry(
        robot_id="test_arm",
        timestamp=time.time(),
        joint_names=["joint1", "joint2", "joint3", "joint4", "joint5", "joint6"],
        positions=[0.0] * 6,
        velocities=[9.5, 0.1, 8.8, 0.2, 9.1, 0.3],
        efforts=[0.0] * 6,
    )
    alerts = list(stub.StreamAlerts(req))

    print(f"    received {len(alerts)} anomaly alerts:")
    for alert in alerts:
        print(
            f"{alert.joint_name}: score={alert.anomaly_score:.2f}fault={alert.is_fault}"
        )

    print("\nAll tests passed.")


if __name__ == "__main__":
    run()
