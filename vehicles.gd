extends Node

var current_vehicle = null

func _input(_event):
	if not current_vehicle:
		return

	current_vehicle.left_right_axis = Input.get_axis("move_right", "move_left")
	current_vehicle.forward_back_axis = Input.get_axis("move_forward", "move_back")
