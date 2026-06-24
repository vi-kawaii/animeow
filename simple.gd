extends CharacterBody3D

const SPEED = 3.0
var forward = Vector3.FORWARD
var left = Vector3.LEFT
var input_dir: Vector2
var hp = 100
var armor = 100
var health = hp + armor
var gun = ""
var swim_height = 0
var jump_impulse = 3
var run_speed = 1.5

var is_body_to_interact = false
var is_interact_key_pressed = false
var is_input_ignored = false
var is_near_to_vehicle_door = false
var is_interacting_finished = false
var is_inside_vehicle = false
var is_exiting_from_vehicle = false
var shooted = false
var is_player = false

var interactable_objects = ["Vehicle"]

var body_to_interact: Node3D

#@onready var guns = ConfigFile.new()
@export var guns: Guns
@export var path: String

@onready var dialogs = get_tree().root.get_node("World").find_child("Dialogs")
@onready var pathes = get_tree().root.get_node("World").find_child("Pathes", true, false)

var bullet_holes = []
var current_hole = -1
var max_holes = 12

func get_vehicles():
	return get_tree().root.get_node("World").find_child("Vehicles", true, false)

func set_input_dir(d):
	input_dir = d

func set_forward(f):
	forward = f

func set_left(l):
	left = l

func _ready() -> void:
	#guns.load("res://guns/guns.txt")
	var i = -1
	while true:
		i += 1
		if i == max_holes:
			break
		var hole = load("res://bullet_hole_decal.tscn").instantiate()
		get_tree().root.add_child(hole)
		bullet_holes.append(hole)
		hole.set_visible(false)

var prev_input_dir: Vector2
var prev_basis: Basis
var prev_forward: Vector3
var prev_left: Vector3
var direction: Vector3
var movement: Vector3

func get_direction():
	return direction

func get_forward():
	return prev_forward

var current_node = 0

func set_character_direction_relative_to_path():
	var n = pathes.get_next_node_from_path_if_close(self, path, current_node, 1)
	current_node = n[1]
	direction = (global_position - n[0].global_position).normalized()
	#var x = n[0].global_position - global_position
	#var b = -global_transform.basis.z.normalized()
	#b.y = 0
	#x = x.normalized()
	#x.y = 0
	#n[0].global_position.y = 2
	#var a = b.signed_angle_to(x, Vector3.UP)
	#a = rad_to_deg(a)
	#if a < 0:
		#a += 360
	#if a >= 0 and a < 180:
		#left = Vector3.LEFT
	#if a >= 180 and a < 360:
		#left = Vector3.RIGHT
	#forward = Vector3.FORWARD

func _physics_process(delta: float) -> void:
	if is_in_vehicle:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		prev_input_dir = input_dir
		prev_basis = transform.basis
		prev_forward = forward
		prev_left = left
	direction = (prev_basis * Vector3(prev_input_dir.x, 0, prev_input_dir.y)).normalized()
	if path:
		set_character_direction_relative_to_path()
	movement = (prev_forward * direction.z + prev_left * direction.x)

	if direction:
		velocity.x = movement.x * SPEED * (run_speed if is_running else 1)
		velocity.z = movement.z * SPEED * (run_speed if is_running else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * (run_speed if is_running else 1))
		velocity.z = move_toward(velocity.z, 0, SPEED * (run_speed if is_running else 1))

	move_and_slide()
	if position.y < swim_height:
		position.y = swim_height

func _process(_delta: float) -> void:
	if is_on_floor() and is_in_stop_running_demand:
		is_in_stop_running_demand = false
		is_running = false
	if health <= 0:
		queue_free()

func damage(n: int):
	health -= n

func set_gun(g):
	gun = g

func get_in_vehicle():
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
	get_node("CollisionShape3D").disabled = true
	set_physics_process(false)
	reparent(body_to_interact.get_node("car2/MeshInstance3D"))
	tween.tween_property(self, "global_position", body_to_interact.get_node("car2/MeshInstance3D").global_transform.origin, 1)
	tween.tween_callback(func():
		body_to_interact.get_parent().interacting = true
	)

func get_out_vehicle():
	body_to_interact.get_parent().interacting = false
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
	reparent(get_tree().get_root().get_node("."))
	tween.tween_property(self, "global_position", body_to_interact.get_node("car2/Door").global_transform.origin, 1)
	tween.tween_callback(func():
		get_node("CollisionShape3D").disabled = false
		set_physics_process(true)
		listen_input()
		is_body_to_interact = true
		is_interact_key_pressed = false
		is_input_ignored = false
		is_near_to_vehicle_door = false
		is_interacting_finished = false
		is_inside_vehicle = false
		is_exiting_from_vehicle = false
	)

func shoot(params):
	var space_state = get_world_3d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 100
	var from = params.from
	var to = params.to

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.hit_from_inside = true
	query.exclude = [self]

	var collision = space_state.intersect_ray(query)
	if collision:
		var target = collision.collider
		match collision.collider.name:
			"Vehicle":
				target = collision.collider.get_node("car2")
				print(collision.position)
			var title when title.begins_with("Enemy"):
				collision.collider.damage(guns.data[guns.data.find_custom(func(x):
					x.name == gun
				)].damage)

		current_hole += 1
		if current_hole == max_holes:
			current_hole = 0
		var bullet_hole = bullet_holes[current_hole]
		#get_tree().get_root().get_node(".").add_child(bullet_hole)

		bullet_hole.global_transform.origin = collision.position
		bullet_hole.look_at(bullet_hole.global_transform.origin + collision.normal, Vector3.UP)
		bullet_hole.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		bullet_hole.set_visible(true)

func hit(params):
	var space_state = get_world_3d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 100
	var from = params.from
	var to = params.to

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.hit_from_inside = true
	query.exclude = [self]

	var collision = space_state.intersect_ray(query)
	if collision:
		var target = collision.collider
		match collision.collider.name:
			"Vehicle":
				target = collision.collider.get_node("car2")
				print(collision.position)
			var title when title.begins_with("Enemy"):
				collision.collider.damage(guns.data[guns.data.find_custom(func(x):
					x.name == gun
				)].damage)

		current_hole += 1
		if current_hole == max_holes:
			current_hole = 0
		var bullet_hole = bullet_holes[current_hole]
		#get_tree().get_root().get_node(".").add_child(bullet_hole)

		bullet_hole.global_transform.origin = collision.position
		bullet_hole.look_at(bullet_hole.global_transform.origin + collision.normal, Vector3.UP)
		bullet_hole.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		bullet_hole.set_visible(true)

func ignore_input():
	is_input_ignored = true

func listen_input():
	is_input_ignored = false

#func body_entered(body):
	#match body.name:
		#"Vehicle":
			#pass
	##if body.name not in interactable_objects:
		##return
#
	##is_body_to_interact = true
	##body_to_interact = body
#
#func body_exited(_body):
	#pass
	##is_body_to_interact = false

var i = -1

func closest(type):
	var areas = $Area3D.get_overlapping_areas()
	areas = areas.filter(func(x):
		return x.name == type
	)
	if areas.size() == 0:
		return [null, true]
	i = -1

	var areas_mapped = areas.map(func(x):
		i += 1
		return [global_position.distance_to(x.global_position), i]
	)
	areas_mapped.sort_custom(func(a, b):
		return a[0] < b[0]
	)

	return [areas[areas_mapped[0][1]], false]

func interact():
	if is_in_vehicle:
		exit_from_vehicle()
		is_in_vehicle = false
		return "Vehicle_Exit"

	var check_list = ["Vehicle", "Dialog"]
	i = -1
	var return_value = null
	while true:
		i += 1
		if i == check_list.size():
			break

		var x = closest(check_list[i])
		if x[1]:
			continue

		match x[0].name:
			"Vehicle":
				sit_in_vehicle(x[0])
				is_in_vehicle = true
				return_value = "Vehicle_Enter"
				break
			"Dialog":
				if dialogs.is_dialog():
					break
				dialogs.set_dialog(x[0].get_parent().dialog_name)
				dialogs.talkers = [x[0].get_parent().get_parent()]
				#dialogs.set_end_callback(x[0].get_parent().callback)
				return_value = "Dialog_Start"
				break

	return return_value

var current_vehicle = null

func sit_in_vehicle(x):
	get_node("CollisionShape3D").disabled = true
	get_node("CollisionShape3D").set_physics_process(false)

	current_vehicle = x.get_parent()
	var seat = current_vehicle.find_child("DriverSeat")
	#reparent(seat)
	#position = Vector3.ZERO
	#rotation = Vector3.ZERO

	get_vehicles().interacting = true
	current_vehicle.start_engine()

func jump():
	if not is_on_floor():
		return
	velocity.y += jump_impulse

var is_in_vehicle = false

func exit_from_vehicle():
	var door = current_vehicle.find_child("DriverDoor")
	#reparent(get_tree().root)
	current_vehicle.stop_engine()
	position = door.global_position
	global_rotation = Vector3.ZERO

	#get_tree().create_timer(0.1).timeout.connect(func():
	get_vehicles().interacting = false
	current_vehicle = null
	get_node("CollisionShape3D").disabled = false
	get_node("CollisionShape3D").set_physics_process(true)
	#)

func start_vehicle_brake():
	if not current_vehicle:
		return
	current_vehicle.start_braking()

func stop_vehicle_brake():
	if not current_vehicle:
		return
	current_vehicle.stop_braking()

var is_running = false

func start_run():
	if not is_on_floor():
		return
	is_running = true

var is_in_stop_running_demand = false

func stop_run():
	if not is_on_floor():
		is_in_stop_running_demand = true
		return
	is_running = false
