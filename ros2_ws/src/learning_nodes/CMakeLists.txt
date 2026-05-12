cmake_minimum_required(VERSION 3.8)
project(learning_nodes)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

add_executable(joint_publisher src/joint_publisher.cpp)
ament_target_dependencies(joint_publisher rclcpp std_msgs sensor_msgs)

install(TARGETS joint_publisher
  DESTINATION lib/${PROJECT_NAME}
)

ament_environment_hooks(
  "${ament_cmake_package_templates_ENVIRONMENT_HOOK_AMENT_PREFIX_PATH}"
)

ament_package()
