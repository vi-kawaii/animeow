extends Node

var cameras

var main_camera

func set_dialog(d):
	main_camera = get_viewport().get_camera_3d()
	cameras = get_tree().get_root().find_child(d, true, false).get_node("cameras")

func next(line_id):
	cameras.find_child(line_id).make_current()

func end():
	cameras = null

	main_camera.make_current()
