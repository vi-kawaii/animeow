extends Node

var cameras
var main_camera


func set_dialog(d):
	main_camera = get_viewport().get_camera_3d()
	var dialog_area = get_tree().get_root().find_child(d, true, false)
	if dialog_area == null:
		cameras = null
		return
	cameras = dialog_area.get_node_or_null("cameras")


func next(line_id):
	if cameras == null:
		return

	var cam = cameras.find_child(str(line_id), true, false)
	if cam == null and cameras.get_child_count() > 0:
		cam = cameras.get_child(0)
	if cam == null:
		return

	cam.make_current()


func end():
	cameras = null
	if main_camera:
		main_camera.make_current()
