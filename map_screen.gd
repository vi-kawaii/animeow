extends CanvasLayer

func activate():
	%map_screen.visible = true
	%map_container.visible = true

	var t = create_tween()
	t.set_parallel()
	t.tween_property(%map_container, "rotation", deg_to_rad(-90), .2)
	t.tween_property(%map_container, "position", Vector2(550, 140), .2)
	t.tween_property(%map_container, "scale", Vector2(2, 2), .2)

func deactivate():
	%map_container.rotation = deg_to_rad(0)
	%map_container.position = Vector2(0, 140)
	%map_container.scale = Vector2(1, 1)
	%map_container.modulate = Color(1, 1, 1, 1)

func _process(_delta):
	%map_camera.position = Player.player.position
	%map_camera.position.y = 10

	%map_screen_map_camera.position.y = 10

func _input(e):
	if not Input.is_action_pressed("shoot"):
		return

	if not %map_screen.visible:
		return

	var delta = 0
	if Input.is_action_just_pressed("mouse_scroll_down"):
		delta = 0.2
	if Input.is_action_just_pressed("mouse_scroll_up"):
		delta = -0.2
	%map_screen_map_camera.size += delta
	%map_screen_map_camera.size = clamp(%map_screen_map_camera.size, 10, 30)

	if e.is_class("InputEventMouseMotion"):
		%map_screen_map_camera.position.x -= e.get_relative().x * 0.01
		%map_screen_map_camera.position.z -= e.get_relative().y * 0.01
