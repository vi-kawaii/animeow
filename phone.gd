extends Node

var visible = false

func _ready():
	if __.game_editor():
		queue_free()
		return

	%unlock.connect("pressed", func():
		%lock_screen.visible = false
		%main_screen.visible = true
	)

	%quit.connect("pressed", func():
		get_tree().quit()
	)

	%camera.connect("pressed", func():
		if not %camera_screen.can_be_opened():
			Log.log("Camera can't be opened in this state")
			return

		Player.ignore_input()

		%lock_screen.visible = false
		%camera_screen.activate()
	)

	%background.connect("pressed", close_phone)

func update():
	var time = "%s:%s"
	var hours = str(GlobalTime.hours).pad_zeros(2).pad_decimals(0)
	var minutes = str(GlobalTime.minutes).pad_zeros(2)
	%clock.text = time % [hours, minutes]

func _input(_event):
	if Input.is_action_just_pressed("esc"):
		if visible:
			close_phone()
		else:
			open_phone()

func open_phone():
	%background.visible = true

	if not can_be_opened():
		return

	visible = true

	var t = create_tween()
	t.set_parallel()
	t.tween_property(%hud_container, "modulate", Color(1, 1, 1, 0), .1)

	t.tween_property(%lock_screen_container, "modulate", Color(1, 1, 1, 1), .1)
	t.tween_property(%lock_screen_container, "position:y", 140, .1).from(400)

	var screens = [
		%main_screen_container,
		%quests_screen_container,
		%music_screen_container,
	]

	for i in screens:
		i.modulate = Color(1, 1, 1, 1)
		i.position.y = 140

	Player.camera.pause_mode(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GlobalTime.trigger_callback = update

func close_phone(from_start_interaction = false):
	%background.visible = false

	visible = false

	%quests_screen.deactivate()

	var t = create_tween()
	t.set_parallel()
	t.tween_property(%hud_container, "modulate", Color(1, 1, 1, 1), .1)

	var screens = [
		%lock_screen_container,
		%main_screen_container,
		%quests_screen_container,
		%music_screen_container,
		%map_container,
	]

	for i in screens:
		t.tween_property(i, "modulate", Color(1, 1, 1, 0), .1)
		t.tween_property(i, "position:y", 400, .1).from(140).connect("finished", func():
			%lock_screen.visible = true

			%main_screen.visible = false
			%music_screen.visible = false
			%quests_screen.visible = false

			%map_screen.visible = false
			%map_screen.deactivate()

			if %camera_screen.active:
				%camera_screen.deactivate()

			if not from_start_interaction:
				Player.listen_input()
		)

	Player.camera.pause_mode(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GlobalTime.trigger_callback = func(): pass

func hud():
	return %hud_container

func can_be_opened():
	if Dialogs.is_dialog():
		return false

	if Intro != null and not Intro.continue_pressed:
		return false

	return true
