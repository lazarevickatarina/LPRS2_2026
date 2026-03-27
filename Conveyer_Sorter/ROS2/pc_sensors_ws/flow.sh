#!/bin/bash

exit 0


source /opt/ros/jazzy/setup.bash

# Build.
colcon build


# Run.
source /opt/ros/jazzy/setup.bash
source install/setup.sh

ros2 launch vision_teleop vision.launch.py

# Debug

ros2 topic echo /select