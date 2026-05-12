#include <chrono>
#include <cmath>
#include <memory>
#include <string>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/joint_state.hpp>

using namespace std::chrono_literals;

class JointPublisher : public rclcpp::Node {
public:
    JointPublisher() : Node("joint_publisher"), t_(0.0) {
        publisher_ = this->create_publisher<sensor_msgs::msg::JointState>(
            "joint_states",
            10
        );

        timer_ = this->create_wall_timer(
            20ms,
            std::bind(&JointPublisher::publish_joint_state, this)
        );

        RCLCPP_INFO(
            this->get_logger(),
                    "Joint publisher started - publishing at 50Hz"
        );
    }

private:
    void publish_joint_state(){
        auto msg = sensor_msgs::msg::JointState();

        msg.header.stamp = this->now();
        msg.header.frame_id = "base_link";

        msg.name = {
            "joint_1",
            "joint_2",
            "joint_3",
            "joint_4",
            "joint_5",
            "joint_6"
        };

        for (size_t i = 0; i < 6; ++i){
            double phase = static_cast<double>(i) * M_PI / 3.0;

            msg.position.push_back(std::sin(t_ + phase));
            msg.velocity.push_back(std::cos(t_ + phase));
            msg.effort.push_back(0.0);
        }

        publisher_->publish(msg);
        t_ += 0.02;
    }

    rclcpp::Publisher<sensor_msgs::msg::JointState>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
    double t_;
};

int main(int argc, char ** argv) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<JointPublisher>());
    rclcpp::shutdown();
    return 0;
}
