


model_pt_fn = 'potato_m.pt'

camera_or_video_path = 0

import rclpy
from rclpy.node import Node

from std_msgs.msg import Int32, String, Bool

from geometry_msgs.msg import TwistStamped

from ultralytics import YOLO
import cv2

from ament_index_python.packages import get_package_share_directory

from os.path import join, abspath



class Vision_Picker(Node):
	def __init__(self):
		super().__init__('vision_sorter')
		self.get_logger().info('vision_sorter loaded')
		
		cv2.namedWindow("Selection", cv2.WINDOW_NORMAL) 
		cv2.resizeWindow("Selection", 480, 640)

		self.select__pub = self.create_publisher(
			String,
			'/select',
			1
		)

		all_agro = abspath(join(
			get_package_share_directory('vision_teleop'),
			'../../../../../../../../' #TODO
		))
		full_model_pt_fn = join(all_agro, model_pt_fn)
		
		self.get_logger().info(f'full_model_pt_fn = {full_model_pt_fn}')
		
		self.model = YOLO(full_model_pt_fn)
		
		self.cap = cv2.VideoCapture(camera_or_video_path)


		self.timer = self.create_timer(1e-3, self.timer__cb)


	def destroy_node(self):
		super().destroy_node(self)
		self.get_logger().info(f'Cleaning up...')
		self.cap.release()
		cv2.destroyAllWindows()

	def timer__cb(self):
		if self.cap.isOpened():
			success, frame = self.cap.read()

			if success:
				frame_size = (frame.shape[1], frame.shape[0])
				def marker_coord(xy):
					return (
						int(xy[0]*frame_size[0]), # x
						int(xy[1]*frame_size[1]), # y
					)

				# Run YOLOv8 tracking on the frame, persisting tracks between frames
				results = self.model.track(
					frame,
					persist = True,
					verbose = False 
				)

				if results[0].boxes.id != None:
					track_ids = results[0].boxes.id.int().cpu().tolist()
					conf = results[0].boxes.conf.cpu().tolist()
					boxes = results[0].boxes.xywh.cpu()
				else:
					track_ids = []
					conf = []
					boxes = []
				def get_box(track_id):
					i = track_ids.index(track_id)
					box = boxes[i]
					x_p = box[0]
					y_p = box[1]
					w_p = box[2]
					h_p = box[3]
					x = x_p/frame_size[0]
					y = y_p/frame_size[1]
					w = w_p/frame_size[0]
					h = h_p/frame_size[1]
					return x, y, w, h

				# Visualize the results on the frame
				annotated_frame = results[0].plot()

				if len(track_ids) != 0:
					# There is something on conveyer belt


					x, y, w, h = get_box(track_ids[1])
					cv2.drawMarker(
						annotated_frame,
						marker_coord((x, y)),
						color = (255, 0, 0), # Blue
						thickness = 1, 
						markerType = cv2.MARKER_DIAMOND,
						line_type = cv2.LINE_AA,
						markerSize = 20
					)

					if len(track_ids) >= 2:
						# Target.
						cv2.drawMarker(
							annotated_frame,
							marker_coord((x, y)),
							color = (255, 0, 255), # Magenta
							thickness = 1, 
							markerType = cv2.MARKER_TILTED_CROSS,
							line_type = cv2.LINE_AA,
							markerSize = 20
						)

						#TODO Do sorting according to the class
						msg = String()
						msg.data = 'left'
						self.get_logger().info('Selecting ', left)
						self.select__pub.publish(msg)
					
				cv2.imshow("Selection", annotated_frame)
				

				k = cv2.waitKey(1)
				if k != -1:
					if k == 27: # ESC
						#TODO Maybe stop everything.
						pass
			


def main(args = None):
	rclpy.init(args = args)
	try:
		sorter = Vision_Picker()

		rclpy.spin(sorter)
	finally:
		# Destroy the node explicitly
		sorter.destroy_node()
		rclpy.shutdown()


if __name__ == '__main__':
	main()