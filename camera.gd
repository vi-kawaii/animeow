extends Camera3D

var target_position
var radius

var angle_y
var angle_x

var new_angle_y
var new_angle_x

var x_rotation_speed = 0.003
var y_rotation_speed = 0.005 / 2
var ignored_objects = []
var current_radius

var is_aim_mode
var ignore_input
var is_aim_toggling
var is_mouse_follow = true

var _pause_camera_mode = false

func pause_mode(f):
	if f:
		is_mouse_follow = false
		pass
	else:
		is_mouse_follow = true
		pass

func pause_camera_mode(f):
	_pause_camera_mode = f

	if f:
		position = position + basis.x * .5
	else:
		position = position + basis.x * .5

func _set_position(p):
	if _pause_camera_mode:
		return

	position = p

func mouse_follow(f):
	is_mouse_follow = f

func _ready():
	is_aim_mode = false
	ignore_input = false
	is_aim_toggling = false

	current_radius = Save.state.camera_data.current_radius

	angle_y = Save.state.camera_data.angle_y
	angle_x = Save.state.camera_data.angle_x

	new_angle_y = Save.state.camera_data.angle_y
	new_angle_x = Save.state.camera_data.angle_x

	radius = current_radius

func _process(_delta):
	var FOLLOW_SPEED = 12.

	var weight = _delta * FOLLOW_SPEED

	angle_y = lerp(angle_y, new_angle_y, weight)
	angle_x = lerp(angle_x, new_angle_x, weight)

	Save.state.camera_data.current_radius = current_radius
	Save.state.camera_data.angle_y = angle_y
	Save.state.camera_data.angle_x = angle_x

	if not _pause_camera_mode:
		if target_position:
			set_global_position(get_camera_position(target_position))

	if not is_mouse_follow:
		return

	if not _pause_camera_mode:
		if target_position:
			look_at(target_position, Vector3(0.0, 1.0, 0.0))

	if is_aim_mode:
		position = position + basis.x * 0.3 + -basis.z * 1.4 + Vector3(0, 0.2, 0) + basis.x * 0.2

func set_target_position(t):
	target_position = t

func tween_to_aim():
	is_aim_mode = true

func tween_to_normal():
	is_aim_mode = false

func _input(p_event):
	if ignore_input:
		return

	if not is_mouse_follow:
		return

	if p_event.is_class("InputEventMouseMotion") and not get_tree().is_paused() and not is_aim_toggling:
		new_angle_y -= p_event.get_relative().x * x_rotation_speed
		new_angle_x += p_event.get_relative().y * y_rotation_speed
		new_angle_x = clamp(new_angle_x, -0.5, 1.2)

func ignore_collision_for(target):
	ignored_objects.append(target)

func remove_last_ignored_collision():
	ignored_objects.remove_at(ignored_objects.size() - 1)

func get_camera_position(pos):
	var new_x = pos.x + radius * cos(angle_x) * sin(angle_y)
	var new_y = pos.y + radius * sin(angle_x)
	var new_z = pos.z + radius * cos(angle_x) * cos(angle_y)

	var new_camera_position = Vector3(new_x, new_y, new_z)

	var v1 = pos
	var v2 = new_camera_position

	var space_state = get_world_3d().get_direct_space_state()
	var query = PhysicsRayQueryParameters3D.create(v1, v2)

	#["position", "normal", "face_index", "collider_id", "collider", "shape", "rid"]
	var result = space_state.intersect_ray(query)

	if result.size() and not ignored_objects.has(result.get("collider", true)):
		var new_radius = (result.get("position", v1) - v1).length() - 1

		if new_radius < 0.1:
			new_radius = 0.1

		new_x = pos.x + new_radius * cos(angle_x) * sin(angle_y)
		new_y = pos.y + new_radius * sin(angle_x)
		new_z = pos.z + new_radius * cos(angle_x) * cos(angle_y)

		new_camera_position = Vector3(new_x, new_y, new_z)

		current_radius = new_radius
	else:
		current_radius = lerp(current_radius, radius, 0.05)

		new_x = pos.x + current_radius * cos(angle_x) * sin(angle_y)
		new_y = pos.y + current_radius * sin(angle_x)
		new_z = pos.z + current_radius * cos(angle_x) * cos(angle_y)

		new_camera_position = Vector3(new_x, new_y, new_z)

	return new_camera_position
