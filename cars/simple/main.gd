extends VehicleBody3D

@onready var sounds = get_node("sounds")
@onready var pathes = get_parent().get_node("Pathes")

var left_right_axis: float = 0
var forward_back_axis: float = 0

var current_node = 0
@export var path: String

func start_engine():
	sounds.get_node("engine-start").finished.connect(func():
		if is_engine_stopped:
			return
		sounds.get_node("engine-started").play()
	)
	sounds.get_node("engine-started").finished.connect(func():
		if is_engine_stopped:
			return
		sounds.get_node("engine-process").play()
	)
	sounds.get_node("engine-start").play()
	is_engine_stopped = false

var is_engine_stopped = true

func stop_engine():
	is_engine_stopped = true
	sounds.get_node("engine-process").stop()
	sounds.get_node("engine-stop").play()

func play_sound(sound):
	if sound == "engine-stop":
		sounds.get_node("engine-process").stop()

	sounds.get_node(sound).play()

#func _ready() -> void:
	#get_node("car2/Door").body_entered.connect(body_entered)
	#get_node("car2/Door").body_exited.connect(body_exited)

func set_vehicle_direction_relative_to_path():
	var n = pathes.get_next_node_from_path_if_close(self, path, current_node, 2)
	current_node = n[1]
	var x = n[0].global_position - global_position
	var b = -global_transform.basis.z.normalized()
	b.y = 0
	x = x.normalized()
	x.y = 0
	n[0].global_position.y = 2
	var a = b.signed_angle_to(x, Vector3.UP)
	#a = rad_to_deg(a)
	#if a < 0:
		#a += 360
	#if a >= 0 and a < 180:
		#left_right_axis = 1.5
		#if a < 10:
			#left_right_axis = 0
	#if a >= 180 and a < 360:
		#left_right_axis = -1.5
		#if a < 180 + 10:
			#left_right_axis = 0
	left_right_axis = a
	forward_back_axis = -0.2

func _physics_process(_delta: float) -> void:
	if path:
		set_vehicle_direction_relative_to_path()
	steering = left_right_axis * 0.4
	engine_force = forward_back_axis * 100

	if linear_velocity.length() < 1 and linear_velocity.length() > 0 and steering == 0:
		brake = 0.1

	if is_braking:
		engine_force = 0
		brake = 1
	else:
		brake = 0

func body_entered(body):
	if body.name == "Character":
		body.get_parent().is_near_to_vehicle_door = true

func body_exited(body):
	if body.name == "Character":
		body.get_parent().is_near_to_vehicle_door = false

var is_braking = false

func start_braking():
	is_braking = true

func stop_braking():
	is_braking = false
