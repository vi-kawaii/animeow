extends Node

var dialog
var current_dialog

var talkers = []

func set_dialog(d):
	dialog = d
	current_dialog = d

func start_dialog():
	get_tree().connect("process_frame", func():
		%dialog.start(dialog.split("_")[2])
	, CONNECT_ONE_SHOT)

func next_dialog():
	if %dialog.is_tweening:
		return

	%dialog.next()

func is_dialog():
	return %dialog.is_dialog()

func end_dialog():
	Player.listen_input()

func load_dialog():
	var p = get_tree().get_root().get_node("Phone")

	if p.get_node("camera_screen").active:
		return

	Resources.load("dialog/%s.tres" % dialog.split("_")[1], func(res):
		if p.visible:
			p.close_phone(true)

		DialogCameras.set_dialog(dialog)

		%dialog.set_dialog(res)
		%dialog.start(dialog.split("_")[2])
	)
