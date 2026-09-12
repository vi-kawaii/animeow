extends VehicleBody3D

var left_right_axis = 0
var forward_back_axis = 0
var current_node = 0

@export var path: String

var is_engine_stopped = true
var is_braking = false

func _ready():
	%engine_start.connect("finished", on_engine_start_finished)
	%engine_started.connect("finished", on_engine_started_finished)
	sleeping = false

func start_engine():
	is_engine_stopped = false
	%engine_start.play()

func on_engine_start_finished():
	if is_engine_stopped:
		return

	%engine_started.play()

func on_engine_started_finished():
	if is_engine_stopped:
		return

	%engine_process.play()

func stop_engine():
	is_engine_stopped = true
	%engine_process.stop()
	%engine_stop.play()

func set_vehicle_direction_relative_to_path():
	var n = Pathes.get_next_node_from_path_if_close(get_global_position(), path, current_node, 2.0)
	current_node = n[1]
	var dir = n[0].direction_to(get_global_position())
	var fwd = basis.z
	fwd.y = 0
	dir = dir.normalized()
	dir.y = 0
	left_right_axis = fwd.signed_angle_to(dir, Vector3(0, 1, 0))
	forward_back_axis = -0.2

func _physics_process(_delta):
	if path != "":
		set_vehicle_direction_relative_to_path()

	set_steering(left_right_axis * 0.4)
	set_engine_force(forward_back_axis * 100)

	if get_linear_velocity().length() < 1 && get_linear_velocity().length() > 0 && get_steering() == 0:
		set_brake(0.1)

	if is_braking:
		set_engine_force(0)
		set_brake(1)
	else:
		set_brake(0)

func start_braking():
	is_braking = true

func stop_braking():
	is_braking = false
