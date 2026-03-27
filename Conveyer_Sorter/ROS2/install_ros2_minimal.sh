#!/bin/bash
##############################################################################
# Automatically figure out which ROS distro you need.

. /etc/os-release

MAJOR=`echo $VERSION_ID | sed -n 's/\([0-9]\+\)\(\.[0-9]\+\)\?/\1/p'`

if [[ "$ID" == "ubuntu" ]]
then
  if (( $MAJOR == 24 ))
  then
    ROS_DISTRO='jazzy'
  elif (( $MAJOR == 22 ))
  then
    ROS_DISTRO=humble
  elif (( $MAJOR == 20 ))
  then
    ROS_DISTRO=galactic
  else
    echo "Not supported version!"
    exit 1
  fi
elif [[ "$ID" == "debian" ]]
then
  if (( $MAJOR == 12 ))
  then
    ROS_DISTRO=humble
  else
    echo "Not supported version!"
    exit 1
  fi
else
  echo "Not supported OS!"
  exit 1
fi

echo "ROS_DISTRO=$ROS_DISTRO"

##############################################################################



# URL:
# https://docs.ros.org/en/${ROS_DISTRO}/Installation/Ubuntu-Install-Debians.html

locale  # check for UTF-8

sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
#export LANG=en_US.UTF-8

locale  # verify settings

sudo apt -y install software-properties-common
sudo add-apt-repository universe -y

sudo apt update
sudo apt -y install curl
curl -L https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o ros.key
sudo mv ros.key /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update

#FIXME python3-paraview use python3-vtk7,
# but ros-${ROS_DISTRO}-desktop needs python3-vtk9,
# and that is where conflict occurs.
sudo apt -y purge python3-paraview

#TODO More cut.
sudo apt -y install \
    python3-rosdep2 \
    python3-colcon-ros \
    python3-colcon-package-selection \
    ros-${ROS_DISTRO}-desktop \
    ros-${ROS_DISTRO}-controller-manager \
    ros-${ROS_DISTRO}-controller-manager-msgs \
    ros-${ROS_DISTRO}-control-msgs \
    ros-${ROS_DISTRO}-control-toolbox \
    ros-${ROS_DISTRO}-hardware-interface \
    ros-${ROS_DISTRO}-backward-ros \
    ros-${ROS_DISTRO}-launch-param-builder

