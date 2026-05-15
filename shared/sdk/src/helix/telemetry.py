"""
gRPC client for the helix telemetry server.

Usage:
    client = TelemetryClient(server_address="localhost:50051")
    client.publish_joint_data(
        robot_id="wheeled_robot",
        joint_names=["left_wheel", "right_wheel"],
        positions=[0.0, 0.0],
        velocities=[1.0, 1.0],
    )
"""

from __future__ import annotations
import time
import grpc


class TelemetryClient:
    """
    Client for the helix Go telemetry server.

    The server runs natively on the workstation or second machine.
    Robots connect via Tailscale. Python projects connect via localhost.

    Args:
        server_address: host:port of the telemetry server
        robot_id: identifier for this system — used as Prometheus label
    """

    def __init__(
        self,
        server_address: str = "localhost:50051",
        robot_id: str = "unknown",
    ):
        self.server_address = server_address
        self.robot_id = robot_id
        self._channel = None
        self._stub = None
        self._connect()

    def _connect(self) -> None:
        """Lazy import of generated proto stubs."""
        try:
            # Proto stubs are generated from helix/shared/telemetry_server
            # and published alongside the SDK or generated at install time
            from helix._proto import telemetry_pb2, telemetry_pb2_grpc

            self._pb = telemetry_pb2
            self._channel = grpc.insecure_channel(self.server_address)
            self._stub = telemetry_pb2_grpc.TelemetryServiceStub(self._channel)
        except ImportError:
            # Server not available — silent fail, log locally only
            self._stub = None

    def publish_joint_data(
        self,
        joint_names: list[str],
        positions: list[float],
        velocities: list[float],
        efforts: list[float] | None = None,
    ) -> bool:
        """
        Publish joint telemetry to the server.
        Returns True if successful, False if server unavailable.
        """
        if self._stub is None:
            return False

        try:
            req = self._pb.JointTelemetry(
                robot_id=self.robot_id,
                timestamp=time.time(),
                joint_names=joint_names,
                positions=positions,
                velocities=velocities,
                efforts=efforts or [0.0] * len(joint_names),
            )
            ack = self._stub.PublishJointData(req, timeout=1.0)
            return ack.success
        except grpc.RpcError:
            return False

    def close(self) -> None:
        if self._channel:
            self._channel.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
