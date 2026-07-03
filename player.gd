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

var shooter_component

func _ready():
	interactable_objects.append("Vehicle")
	player = get_node("character")
	player.set_is_player(true)
	player.set_position(Save.state.character_position)

	# Настройка слоев и масок для игрока
	# Сначала сбрасываем все слои, чтобы включить только нужные
	for i in range(1, 33):
		player.set_collision_layer_value(i, false)
		player.set_collision_mask_value(i, false)

	# Layer 2: Player (кем является игрок)
	player.set_collision_layer_value(2, true)

	# Mask 1 (World) и 3 (Enemies) (обо что бьется ногами)
	player.set_collision_mask_value(1, true)
	player.set_collision_mask_value(3, true)

	current_camera_target = player
	crosshair = get_node("Crosshair")
	get_node("character/Marker").set_visible(true)
	camera = %camera

	shooter_component = player.get_node("shooter_component")

func timer_timeout():
	shooted = false

func _process(_delta):
	var map_camera_position = player.get_position()
	map_camera_position.y = 10

	RenderingServer.global_shader_parameter_set("player_position", player.get_global_position())
	Save.state.character_position = player.get_global_position()
	_process_shoot(_delta)
	#%camera.set_target_position(current_camera_target.get_global_position())
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

	crosshair.set_visible(true)

func interact_with_bodies():
	return is_body_to_interact and is_interact_key_pressed

var camera_recoil_offset: Vector3 = Vector3.ZERO
var camera_recoil_speed: float = 20.0

func _process_shoot(delta):
	var shooter = shooter_component
	var current_progressive_up: float = 0.0

	if shooter:
		# 1. Забираем мгновенную вспышку тряски (отрабатывает один раз за выстрел)
		if shooter.recoil_vector != Vector3.ZERO:
			camera_recoil_offset += shooter.recoil_vector
			shooter.recoil_vector = Vector3.ZERO

		# 2. Считываем текущее значение постоянного увода вверх при зажиме
		current_progressive_up = shooter.progressive_recoil_offset

	# Плавное сглаживание мгновенной тряски
	camera_recoil_offset = lerp(camera_recoil_offset, Vector3.ZERO, camera_recoil_speed * delta)

	# Собираем финальную позицию цели
	var final_target_pos = current_camera_target.get_global_position()

	# Складываем мгновенную тряску (X и Y) и прогрессивный увод вверх (добавляется к Y)
	var total_recoil = camera_recoil_offset
	total_recoil.y += current_progressive_up

	# Переводим в локальные координаты вашей цели
	var local_offset = current_camera_target.global_transform.basis * total_recoil
	final_target_pos += local_offset

	# Ваша родная строчка
	%camera.set_target_position(final_target_pos)

func _shoot():
	shooter_component.fire()

func input():
	if Input.is_action_pressed("shoot"):
		_shoot()

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
