extends Node

var is_body_to_interact = false
var is_interact_key_pressed = false
var is_input_ignored = false
var is_near_to_vehicle_door = false
var is_interacting_finished = false
var is_inside_vehicle = false
var is_exiting_from_vehicle = false
var shooted = false

var interactable_objects = []

var body_to_interact
var current_camera_target
var player
var crosshair

var map_camera

var input_dir
var is_mobile_buttons_pressed = false
var is_running = false

var camera

func go_up(f):
	is_mobile_buttons_pressed = f
	if f:
		input_dir = Vector2(0, -1)
	else:
		input_dir = Vector2(0, 0)
		player.stop_run()

func go_down(f):
	is_mobile_buttons_pressed = f
	if f:
		input_dir = Vector2(0, 1)
	else:
		input_dir = Vector2(0, 0)
		player.stop_run()

func go_left(f):
	is_mobile_buttons_pressed = f
	if f:
		input_dir = Vector2(-1, 0)
	else:
		input_dir = Vector2(0, 0)
		player.stop_run()

func go_right(f):
	is_mobile_buttons_pressed = f
	if f:
		input_dir = Vector2(1, 0)
	else:
		input_dir = Vector2(0, 0)
		player.stop_run()

func skill():
	pass

func ult():
	pass

func change_character():
	pass

func atk():
	pass

func run(_f):
	player.start_run()

func jump():
	player.jump()

func get_player():
	return player.get()

func set_is_input_ignored(a):
	is_input_ignored = a

func set_gun(g):
	player.set_gun(g)

func _ready():
	interactable_objects.append("Vehicle")
	player = get_node("character")

	player.set_is_player(true)
	player.set_position(Save.state.character_position)
	current_camera_target = player
	crosshair = get_node("Crosshair")

	get_node("character/Marker").set_visible(true)

	camera = %camera

func timer_timeout():
	shooted = false

func _process(_delta):
	var map_camera_position = player.get_position()
	map_camera_position.y = 10

	RenderingServer.global_shader_parameter_set("player_position", player.get_global_position())
	Save.state.character_position = player.get_global_position()
	%camera.set_target_position(current_camera_target.get_global_position())
	set_player_direction_relative_to_camera()

	if Input.is_action_just_pressed("aim") and $gun_selector.is_gun_selected and not $gun_selector.is_selector_mode:
		%camera.tween_to_aim()
		$gun_selector.is_ignoring_input = true

	if Input.is_action_just_released("aim") and $gun_selector.is_gun_selected and not $gun_selector.is_selector_mode:
		%camera.tween_to_normal()
		$gun_selector.is_ignoring_input = false

	crosshair.set_visible(false)
	if Input.is_action_pressed("aim") and $gun_selector.is_gun_selected and not Input.is_action_just_pressed("$gun_selector"):
		crosshair.set_visible(true)
		if Input.is_action_pressed("shoot"):
			var mouse_pos = get_viewport().get_mouse_position()
			player.shoot(
				%camera.project_ray_origin(mouse_pos) + -%camera.get_global_transform().basis.z * 2,
				%camera.project_ray_origin(mouse_pos) + %camera.project_ray_normal(mouse_pos) * 100
			)

	if Input.is_action_just_pressed("shoot") and $gun_selector.is_melee_selected and not Input.is_action_just_pressed("$gun_selector"):
		if $gun_selector.is_melee_selected:
			pass
			#var mouse_pos = get_viewport().get_mouse_position()
			#player.get().hit()

	input()

func interact_with_bodies():
	return is_body_to_interact and is_interact_key_pressed

func input():
	if Input.is_action_just_pressed("run"):
		if is_running:
			is_running = false
			player.stop_run()
		else:
			is_running = true
			player.start_run()

	if Input.is_action_just_pressed("jump") and not player.get_current_vehicle() and not is_input_ignored:
		player.jump()
		player.start_vehicle_brake()

	if Input.is_action_just_released("jump"):
		player.stop_vehicle_brake()

	if Input.is_action_just_pressed("interact"):
		match player.interact():
			"Vehicle_Enter":
				player.set_visible(false)
				current_camera_target = player.get_current_vehicle()
				Vehicles.current_vehicle = player.get_current_vehicle()
				%camera.ignore_collision_for(player.get_current_vehicle())

			"Vehicle_Exit":
				player.set_visible(true)
				current_camera_target = player
				Vehicles.current_vehicle = null
				%camera.remove_last_ignored_collision()

			"Dialog_Start":
				ignore_input()

	if not is_mobile_buttons_pressed:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if is_input_ignored:
		input_dir = Vector2(0.0, 0.0)

	if input_dir == Vector2(0, 0):
		is_running = false
		player.stop_run()

	player.set_input_dir(input_dir)

func ignore_input():
	is_input_ignored = true

func listen_input():
	is_input_ignored = false

func set_player_direction_relative_to_camera():
	var forward = %camera.get_global_transform().basis.z.normalized()
	forward.y = 0
	forward = forward.normalized()

	var left = %camera.get_global_transform().basis.x.normalized()
	left.y = 0
	left = left.normalized()

	var first_params = []
	first_params.append(forward)

	player._set_forward(forward)
	player._set_left(left)
