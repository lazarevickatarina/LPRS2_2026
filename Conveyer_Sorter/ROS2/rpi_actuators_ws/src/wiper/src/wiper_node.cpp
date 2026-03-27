
#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/joy.hpp"

#include <chrono>

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#include "../../../../common.h"

rclcpp::Node::SharedPtr node;

int gpio_write(int fd, uint8_t pin, uint8_t value) {
	uint8_t pkg[3];
	pkg[0] = 'w';
	pkg[1] = pin;
	pkg[2] = value;
	

	if (write(fd, &pkg, 3) != 3) {
		perror("Failed to write to GPIO");
		return -1;
	}
	return 0;
}

void joy__cb(const sensor_msgs::msg::Joy::SharedPtr joy_msg) {
	if(joy_msg->buttons[BUTTON_CW]){
		RCLCPP_INFO_STREAM(node->get_logger(), "CW");
		//TODO rotate wiper motor CW
	}
	if(joy_msg->buttons[BUTTON_CCW]){
		RCLCPP_INFO_STREAM(node->get_logger(), "CCW");
		//TODO rotate wiper motor CCW
	}
	if(joy_msg->buttons[BUTTON_STOP]){
		RCLCPP_INFO_STREAM(node->get_logger(), "STOP");
		//TODO STOP wiper motor
	}
}

// TODO Extra: watchdog if no CW or CCW for longer time, go to STOP. Use timer.

int main(int argc, char * argv[]) {
	rclcpp::init(argc, argv);
	node = std::make_shared<rclcpp::Node>("wiper_node");

	// Subscribe.
	rclcpp::Subscription<sensor_msgs::msg::Joy>::SharedPtr subscription 
		= node->create_subscription<sensor_msgs::msg::Joy>( //TODO std_msgs::String
		"joy", //TODO select
		1,
		&joy__cb
	);

	// Open GPIO device
	int gpio_fd = open("/dev/gpio_stream", O_RDWR);
	if (gpio_fd < 0) {
		perror("Failed to open /dev/gpio_stream");
		return EXIT_FAILURE;
	}

	rclcpp::spin(node);

	return 0;
}
