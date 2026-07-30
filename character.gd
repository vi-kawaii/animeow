extends CharacterBody3D

@export var is_flying = false
@export var is_camera_mode = false

var fly_up = false
var fly_down = false

var SPEED = 3.
var forward = Vector3.FORWARD
var left = Vector3.LEFT
var input_dir = Vector2.ZERO
var hp = 100
var armor = 100
var health = hp + armor
var gun
var swim_height = 0.5
var jump_impulse = 3
var run_speed = 1.5

var passed_time = 0
var current_gun = 0

var prev_input_dir = Vector2.ZERO
var prev_basis = Basis()
var prev_forward = Vector3.ZERO
var prev_left = Vector3.ZERO
var direction = Vector3.ZERO
var movement = Vector3.ZERO

var current_node = 0

var is_body_to_interact = false
var is_interact_key_pressed = false
var is_input_ignored = false
var is_near_to_vehicle_door = false
var is_interacting_finished = false
var is_inside_vehicle = false
var is_exiting_from_vehicle = false
var shooted = false
var is_player = false
var is_in_vehicle = false
var is_in_stop_running_demand = false
var is_running = false

var interactable_objects = []

var body_to_interact
@export var guns: GunsResource
@export var path: String = ""

var current_vehicle

var bullet_holes
var current_hole = -1
var max_holes = 12

func get_guns():
	return guns

func set_guns(g):
	guns = g

func get_is_player():
	return is_player

func set_is_player(a):
	is_player = a

func set_input_dir(d):
	input_dir = d

func _set_forward(f):
	forward = f

func _set_left(l):
	left = l

func _ready():
	if name.begins_with("enemy"):
		get_node("Sprite3D").set_visible(true)

	if is_camera_mode:
		get_node("MeshInstance3D").queue_free()
		get_node("CollisionShape3D").set_disabled(true)
		get_node("CollisionShape3D").set_physics_process(false)

func set_character_direction_relative_to_path():
	var n = Pathes.get_next_node_from_path_if_close(get_global_position(), path, current_node, 2)
	current_node = n[1]
	direction = n[0] - get_global_position()
	direction = direction.normalized()
	movement.x = direction.x
	movement.z = direction.z

func _physics_process(delta):
	if is_in_vehicle:
		return

	if not is_flying:
		if !is_on_floor():
			set_velocity(get_velocity() + get_gravity() * delta)

	if is_on_floor() or is_flying:
		prev_input_dir = input_dir
		prev_basis = get_basis()
		prev_forward = forward
		prev_left = left

	if not is_camera_mode:
		direction = prev_basis * Vector3(prev_input_dir.x, 0, prev_input_dir.y).normalized()
	else:
		direction = prev_basis * Vector3(prev_input_dir.x, 0, 0).normalized()
	movement = (prev_forward * direction.z + prev_left * direction.x)

	if get_node_or_null("MeshInstance3D") and input_dir != Vector2.ZERO:
		var resulting_rotation = Player.camera.rotation.y

		var r = get_node("MeshInstance3D").rotation.y

		var FOLLOW_SPEED = 16.

		var from = r
		var to = from
		var weight = delta * FOLLOW_SPEED

		var deg = 0

		if input_dir.y > 0:
			if input_dir.x > 0:
				# back right
				deg = 90 + 45
				#resulting_rotation += deg_to_rad(90 + 45 + 180)
			elif input_dir.x == 0:
				# back
				deg = 90
				#resulting_rotation += deg_to_rad(90)
		elif input_dir.y < 0:
			if input_dir.x < 0:
				# front left
				deg = -90 + 45
				#resulting_rotation += deg_to_rad(-45)
			elif input_dir.x == 0:
				# front
				deg = -90
				#resulting_rotation += deg_to_rad(-90)

		if input_dir.x > 0:
			if input_dir.y < 0:
				# front right
				deg = 180 + 45
				#resulting_rotation += deg_to_rad(-45)
			elif input_dir.y == 0:
				# right
				deg = 180
				#resulting_rotation += deg_to_rad(-180)
		elif input_dir.x < 0:
			if input_dir.y > 0:
				# back left
				deg = -45 + 90
				#resulting_rotation += deg_to_rad(-180 - 45 + 180)
			elif input_dir.y == 0:
				# left
				deg = 0

		to = resulting_rotation + deg_to_rad(deg)
		r = lerp_angle(from, to, weight)
		resulting_rotation = r

		get_node("MeshInstance3D").rotation.y = resulting_rotation

	if is_camera_mode:
		if fly_up:
			velocity.y = SPEED
		elif fly_down:
			velocity.y = -SPEED
		else:
			velocity.y = 0

	if path != "":
		set_character_direction_relative_to_path()

	if direction != Vector3.ZERO:
		set_velocity(Vector3(
			movement.x * SPEED * (run_speed if is_running else 1.),
			get_velocity().y,
			movement.z * SPEED * (run_speed if is_running else 1.)
		))
	else:
		set_velocity(Vector3(
			move_toward(get_velocity().x, 0.0, SPEED * (run_speed if is_running else 1.)),
			get_velocity().y,
			move_toward(get_velocity().z, 0.0, SPEED * (run_speed if is_running else 1.))
		))

	if get_position().y < swim_height:
		set_velocity(
			Vector3(
				get_velocity().x,
				swim_height,
				get_velocity().z
			)
		)
		position.y = swim_height
	move_and_slide()

func _process(delta):
	passed_time += delta

	if guns != null:
		var g_d = guns.data
		var g = g_d[current_gun]
		var current_timing = g.timing

		if passed_time > current_timing:
			passed_time = 0
			shooted = false

	if is_on_floor() and is_in_stop_running_demand:
		is_in_stop_running_demand = false
		is_running = false

	if health <= 0:
		queue_free()

	var c = get_viewport().get_camera_3d()
	if get_node_or_null("Label3D") and c:
		var l = get_node("Label3D")
		var distance = get_position().distance_to(c.get_position())
		l.set_text(str(floor(distance)))

func damage(n):
	print("damage is ", n, ", ", health, " health left")
	var p = get_node("SubViewport/CanvasLayer/Polygon2D3")
	health -= n
	var v = []
	v.append(Vector2(65, 1))
	v.append(Vector2(65, 5))
	# min = 1, max = 65
	# 1 = 0%, 65 = 100%
	# or 0 = 0%, 64 = 100%, and then +1
	var current_health = health / 200.0 * 64
	current_health += 1
	v.append(Vector2(current_health, 5))
	v.append(Vector2(current_health, 1))
	p.set_polygon(PackedVector2Array(v))
	p.queue_redraw()

func set_gun(g):
	gun = g

	#for i in range(guns.data.size()):
		#if guns.data[i].get_title() == gun:
			#current_gun = i
			#break

func shoot(from, to):
	var space_state = get_world_3d().get_direct_space_state()

	#var mouse_pos = get_viewport().get_mouse_position()
	#var ray_length = 100

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.set_hit_from_inside(true)
	var e = []
	e.append(self)
	query.set_exclude(e)
	var result = space_state.intersect_ray(query)

	if result.size():
		var c = result.get("collider", false)
		var n = c.get_name()

		if n.begins_with("enemy"):
			if shooted:
				return

			var g = guns.data
			print(gun)
			for i in range(g.size()):
				if g[i].title == gun:
					print("damaged")
					c.damage(g[i].damage)
					shooted = true

	current_hole += 1
	if current_hole == max_holes:
		current_hole = 0

func hit():
	var space_state = get_world_3d().get_direct_space_state()

	#var mouse_pos = get_viewport().get_mouse_position()
	#var ray_length = 100

	var query = PhysicsRayQueryParameters3D.create(
		get_global_position(),
		get_global_position() + -forward * 4
	)
	query.set_hit_from_inside(true)
	var e = []
	e.append(self)
	query.set_exclude(e)

	#["position", "normal", "face_index", "collider_id", "collider", "shape", "rid"]
	var result = space_state.intersect_ray(query)

	if result.size():
		var c = result.get("collider", false)
		var n = c.get_name()
		print(n)

		if n.begins_with("enemy"):
			if shooted:
				return

			var g = guns.data
			for i in range(g.size()):
				if g[i].title == gun:
					break

			#c.damage(g[i]).get_damage()
			shooted = true

	current_hole += 1
	if current_hole == max_holes:
		current_hole = 0

func closest(type):
	var areas = %area.get_overlapping_areas()
	var min_distance = 100.0
	var index_of_min_distance = -1

	for i in range(areas.size()):
		if areas[i].name == "area":
			continue

		if areas[i].name == "grass_area":
			continue

		if areas[i].name.begins_with(type):
			continue

		var d = get_global_position().distance_to(areas[i].get_global_position())
		if d > min_distance:
			continue

		min_distance = d
		index_of_min_distance = i

	var return_value = []
	if index_of_min_distance == -1:
		return_value.append(false)
		return_value.append(true)
	else:
		return_value.append(areas[index_of_min_distance])
		return_value.append(false)

	return return_value

func interact():
	if Dialogs.is_dialog():
		Dialogs.next_dialog()
		return ""

	if is_in_vehicle:
		exit_from_vehicle()
		return "Vehicle_Exit"

	var check_list = []
	check_list.append("vehicle")
	check_list.append("dialog")
	var return_value = ""
	for i in range(check_list.size()):
		var x = closest(check_list[i])
		if x[1]:
			continue

		var area_name = x[0].name

		if area_name.begins_with("vehicle"):
			sit_in_vehicle(x[0])
			return_value = "Vehicle_Enter"
			break

		if area_name.begins_with("dialog"):
			if Dialogs.is_dialog():
				break

			Dialogs.set_dialog(area_name)
			Dialogs.talkers = [x[0].get_parent()]
			Dialogs.load_dialog()
			return_value = "Dialog_Start"
			break

	return return_value

func get_current_vehicle():
	if not current_vehicle:
		return null

	return current_vehicle

func sit_in_vehicle(x):
	get_node("CollisionShape3D").set_disabled(true)
	get_node("CollisionShape3D").set_physics_process(false)

	current_vehicle = x.get_parent()
	is_in_vehicle = true

	current_vehicle.start_engine()

func jump():
	if !is_on_floor():
		return

	set_velocity(Vector3(
		get_velocity().x,
		get_velocity().y + jump_impulse,
		get_velocity().z
	))

func exit_from_vehicle():
	current_vehicle.stop_engine()
	set_global_position(current_vehicle.find_child("DriverDoor").get_global_position())
	set_global_rotation(Vector3(0, 0, 0))

	current_vehicle = null
	get_node("CollisionShape3D").set_disabled(false)
	get_node("CollisionShape3D").set_physics_process(true)

	is_in_vehicle = false

func start_vehicle_brake():
	if not current_vehicle:
		return

	current_vehicle.start_braking()

func stop_vehicle_brake():
	if not current_vehicle:
		return

	current_vehicle.stop_braking()

func start_run():
	if not is_on_floor():
		return

	is_running = true

func stop_run():
	if not is_on_floor():
		is_in_stop_running_demand = true
		return

	is_running = false
