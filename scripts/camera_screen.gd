extends CanvasLayer

var active = false

func activate():
	active = true

	%character.get_node("CollisionShape3D").set_disabled(false)
	%character.get_node("CollisionShape3D").set_physics_process(true)

	%character.position = get_camera_spawn_position()

	%phone_camera.rotation = Player.camera.rotation
	%phone_camera.rotation.x = 0
	%phone_camera.look_at(Player.player.position)

	%phone_camera.make_current()

func deactivate():
	active = false

	Player.camera.make_current()

	%character.get_node("CollisionShape3D").set_disabled(true)
	%character.get_node("CollisionShape3D").set_physics_process(false)

func _physics_process(_delta):
	if not active:
		return

	set_player_direction_relative_to_camera()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	%character.set_input_dir(input_dir)

	%character.fly_up = Input.is_action_pressed("ui_up")
	%character.fly_down = Input.is_action_pressed("ui_down")

	return

	var direction = %phone_camera.basis * Vector3(input_dir.x, -input_dir.y, 0)
	var movement = (%phone_camera.basis.y * direction.y + %phone_camera.basis.x * direction.x)

	%phone_camera.position += movement

	#if e.is_class("InputEventMouseMotion"):
		#%map_screen_map_camera.position.x -= e.get_relative().x * 0.01
		#%map_screen_map_camera.position.z -= e.get_relative().y * 0.01

func set_player_direction_relative_to_camera():
	var forward = %phone_camera.get_global_transform().basis.z.normalized()
	forward.y = 0
	forward = forward.normalized()

	var left = %phone_camera.get_global_transform().basis.x.normalized()
	left.y = 0
	left = left.normalized()

	var first_params = []
	first_params.append(forward)

	%character._set_forward(forward)
	%character._set_left(left)

func can_be_opened():
	var space_state = get_tree().get_root().get_world_3d().direct_space_state

	var from = Player.player.position
	var to = from + Player.player.forward.normalized() * 2
	var query = PhysicsRayQueryParameters3D.create(from, to)

	return not space_state.intersect_ray(query)

func get_camera_spawn_position():
	var from = Player.player.position
	var to = from + Player.player.forward.normalized() * 2

	return to
