extends Node

var response_example = "ExampleBalloon/MarginContainer/MarginContainer2/VBoxContainer/Button"

var previous_camera_mode = ""

var text_pointer
var i
var title
var showing_response = false
var responses
var response_i
var _is_dialog = false
var dialog

var is_tweening = false

func set_dialog(d):
	dialog = d

func get_dialog():
	return dialog

func _ready():
	i = 0
	response_i = 0
	text_pointer = []

func filter(x):
	if x.title == title:
		return true
	else:
		return false

func next():
	if showing_response:
		return

	if i == text_pointer.size():
		if any_responses():
			show_responses()
		else:
			end()

		return

	var tween = create_tween()
	tween.tween_method(custom_tween, 1.0, -0.5, 0.1)
	tween.tween_callback(custom_tween_callback)
	is_tweening = true

	#handle_camera()

	DialogCameras.next(text_pointer.get(i).line_id)

func handle_camera():
	var cam = get_node("ExampleBalloon/camera")
	var current_camera_mode = text_pointer.get(i).camera

	if current_camera_mode == previous_camera_mode:
		return

	previous_camera_mode = current_camera_mode

	var cam_height = 1.
	var head_height = Vector3(0, .5, 0)

	match current_camera_mode:
		"default_middle_between":
			var v1 = get_parent().talkers[0].position
			var v2 = Player.player.position + head_height

			var mid = v1.lerp(v2, .5)
			var cross = (v2 - v1).cross(Vector3.UP)

			cam.position = mid

			cam.position += Vector3(0, cam_height, 0)
			cam.position += cross * 1.2

			cam.look_at(mid)

			var t = create_tween()
			t.set_trans(Tween.TRANS_SINE)
			t.tween_property(cam, "position", cam.position + Vector3(0, -.14, 0), 3.)
		"player_face":
			var v1 = get_parent().talkers[0].position
			var v2 = Player.player.position + head_height

			var cross = (v2 - v1).cross(Vector3.UP)

			cam.position = v1

			cam.position += Vector3(0, cam_height, 0)
			cam.position += cross * .45

			cam.look_at(v2)
		"speaker_face":
			var v1 = get_parent().talkers[0].position
			var v2 = Player.player.position + head_height

			var cross = (v2 - v1).cross(Vector3.UP)

			cam.position = v2

			cam.position += Vector3(0, cam_height, 0)
			cam.position += cross * .45

			cam.look_at(v1)

func custom_tween(x):
	get_node("ExampleBalloon/MarginContainer/GridContainer/Control2/VBoxContainer/PanelContainer3/VBoxContainer/MarginContainer2/RichTextLabel").set_modulate(Color(255, 255, 255, x))

func custom_tween_callback():
	get_node("ExampleBalloon/MarginContainer/GridContainer/Control2/VBoxContainer/PanelContainer3/VBoxContainer/MarginContainer/Label").set_text(text_pointer.get(i).name)
	get_node("ExampleBalloon/MarginContainer/GridContainer/Control2/VBoxContainer/PanelContainer3/VBoxContainer/MarginContainer2/RichTextLabel").set_text(text_pointer.get(i).text)

	i += 1

	var tween = create_tween()
	tween.tween_method(custom_tween, 0.0, 1.0, 0.1)
	tween.tween_callback(custom_tween_second_callback)
	is_tweening = true

func custom_tween_second_callback():
	is_tweening = false

func any_responses():
	if dialog.data.filter(filter)[0].responses.size():
		return true
	else:
		return false

func end_custom_tween(x):
	get_node("ExampleBalloon/MarginContainer/GridContainer/Control2/VBoxContainer/PanelContainer3/VBoxContainer/MarginContainer2/RichTextLabel").set_modulate(Color(255, 255, 255, x))

func end_custom_tween_callback():
	get_node("ExampleBalloon").queue_free()

func end():
	_is_dialog = false

	var tween = create_tween()
	tween.tween_method(end_custom_tween, 1.0, 0.0, 0.1)
	tween.tween_callback(end_custom_tween_callback)

	i = 0
	text_pointer = null
	get_parent().call("end_dialog")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Player.camera.mouse_follow(true)

	showing_response = false
	i = 0
	response_i = 0

	dialog = null

	var hud = get_tree().get_root().get_node("Phone").hud()
	hud.visible = true
	var t = create_tween()
	t.tween_property(hud, "modulate", Color(1, 1, 1, 1), .1)

	#Player.camera.make_current()

	#previous_camera_mode = ""

	DialogCameras.end()

func show_responses_custom_tween(x):
	get_node("ExampleBalloon/MarginContainer/MarginContainer2").set_modulate(Color(1, 1, 1, x))

func show_responses():
	get_node("ExampleBalloon/next_button").visible = false

	get_node("ExampleBalloon/MarginContainer/MarginContainer2").set_visible(true)
	get_node("ExampleBalloon/MarginContainer/MarginContainer2/VBoxContainer/Button2").grab_focus()

	var tween = create_tween()
	tween.tween_method(show_responses_custom_tween, 0.0, 1.0, 0.1)

	showing_response = true

	var r = dialog.data.filter(filter)[0].responses
	responses = r

	if r.size() == 1:
		get_node(response_example + "3").visible = false
	else:
		get_node(response_example + "3").visible = true

	for j in range(r.size()):
		var number = ""
		if j == 0:
			number = "2"

		if j == 1:
			number = "3"

		var b = get_node(response_example + number)
		b.connect("pressed", on_response_click.bind(j))
		b.set_text(r[j].split("|")[1])
		b.set_disabled(false)

func up():
	if (response_i == 0):
		return

	var label = get_node(response_example + str("2") + str("/MarginContainer/Label"))
	label.set_text(label.text.erase(0, 2))

	label = get_node(response_example + str("1") + str("/MarginContainer/Label"))
	label.set_text("> " + label.text)

	response_i -= 1

func down():
	if (response_i == 2 - 1):
		return

	var label = get_node(response_example + str("1") + str("/MarginContainer/Label"))
	label.set_text(label.text.erase(0, 2))

	label = get_node(response_example + str("2") + str("/MarginContainer/Label"))
	label.set_text("> " + label.text)

	response_i += 1

func hide_responses_custom_tween_callback():
	get_node("ExampleBalloon/MarginContainer/MarginContainer2").set_visible(false)

func select_response():
	showing_response = false
	i = 0
	response_i = 0

	var tween = create_tween()
	tween.tween_method(show_responses_custom_tween, 1.0, 0.0, 0.1)
	tween.tween_callback(hide_responses_custom_tween_callback)

	var r = dialog.data.filter(filter)[0].responses
	for j in range(r.size()):
		var number = ""
		if (j == 0):
			number = "2"

		if (j == 1):
			number = "3"

		var b = get_node(response_example + number)
		b.set_disabled(true)

func on_response_click(j):
	get_node("ExampleBalloon/next_button").visible = true

	select_response()
	var parts = responses[j].split("|")
	var to_node = parts[0]
	var label = parts[1] if parts.size() > 1 else ""
	Quests.on_dialog_response(title, to_node, label)
	start(to_node)

func on_screen_click():
	if is_tweening:
		return

	next()

func _process(_delta):
	if (Input.is_action_just_pressed("skip_dialog") and _is_dialog):
		end()

func start(d):
	_is_dialog = true
	title = d

	var array_of_sentences = []
	var data = dialog.data
	for k in range(data.size()):
		if data[k].title != title:
			continue

		array_of_sentences.append(data[k].sentences)

	var hud = get_tree().get_root().get_node("Phone").hud()
	var t = create_tween()
	t.tween_property(hud, "modulate", Color(1, 1, 1, 0), .1)
	t.tween_callback(func():
		hud.visible = false
	)

	text_pointer = array_of_sentences[0]
	if get_node_or_null("ExampleBalloon") == null:
		Resources.load("dialog.tscn", func(res):
			if get_node_or_null("ExampleBalloon") == null:
				var ref = res
				add_child(ref.instantiate())
				next()

				get_node("ExampleBalloon/MarginContainer/Skip").connect("pressed", end)
				get_node("ExampleBalloon/MarginContainer/MarginContainer/Button").connect("pressed", on_screen_click)
				get_node("ExampleBalloon/next_button").connect("pressed", func():
					next()
				)

				Player.camera.mouse_follow(false)
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

				get_node("ExampleBalloon/camera").make_current()
		)
	else:
		next()

func is_dialog():
	return _is_dialog
