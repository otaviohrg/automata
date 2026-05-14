#!/usr/bin/env python3
"""
MuJoCo-ROS2 bridge.
Steps a 6-DOF MuJoCo arm simulation at 50Hz and publishes
joint states to /joint_states via ROS2.
Run with: docker compose run --rm automata-base python3\
           projects/phase1_foundations/mujoco_bridge.py
"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
import mujoco
import mujoco.viewer
import numpy as np

# import threading
import pathlib


def _load_model(model_path) -> mujoco.MjModel:
    if not model_path.exists():
        raise FileNotFoundError(
            f"MJCF model not found at {model_path}\n"
            f"Expected: projects/phase1_foundations/models/arm_6dof.xml"
        )
    return mujoco.MjModel.from_xml_path(str(model_path))


_MODEL_PATH = pathlib.Path(__file__).parent / "models" / "arm_6dof.xml"
JOINT_NAMES = ["joint1", "joint2", "joint3", "joint4", "joint5", "joint6"]


class MuJoCoROS2Bridge(Node):
    def __init__(self, model: mujoco.MjModel, data: mujoco.MjData):
        super().__init__("mujoco_bridge")
        self.model = model
        self.data = data
        self.t = 0.0

        self.pub = self.create_publisher(JointState, "joint_states", 10)
        self.timer = self.create_timer(0.02, self.step_and_publish)

        self.get_logger().info("MuJoCo-ROS2 bridge running at 50Hz")

    def step_and_publish(self):
        for i in range(self.model.nu):
            phase = i * np.pi / 3.0
            self.data.ctrl[i] = np.sin(self.t + phase) * 0.5

        for _ in range(10):
            mujoco.mj_step(self.model, self.data)

        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = "base_link"
        msg.name = JOINT_NAMES
        msg.position = self.data.qpos[:6].tolist()
        msg.velocity = self.data.qvel[:6].tolist()
        msg.effort = self.data.actuator_force[:6].tolist()

        self.pub.publish(msg)
        self.t += 0.02


def main():
    model = _load_model(_MODEL_PATH)
    data = mujoco.MjData(model)

    rclpy.init()
    node = MuJoCoROS2Bridge(model, data)

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
