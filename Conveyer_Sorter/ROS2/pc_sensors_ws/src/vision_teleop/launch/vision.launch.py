
from launch import LaunchDescription
from launch.actions import OpaqueFunction
from launch_ros.actions import Node
from launch.substitutions import LaunchConfiguration


def launch_setup(context, *args, **kwargs):
	
	launches = [
		Node(
			package = 'vision_teleop',
			executable = 'ai_sorter',
			output = 'screen',
			#FIXME does not quite work.
			#arguments = [('--ros-args --log-level debug')],
		)
	]
	return launches
		
def generate_launch_description():
	ld = LaunchDescription([
		OpaqueFunction(function = launch_setup)
	])

	return ld