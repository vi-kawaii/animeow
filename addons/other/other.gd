@tool
extends EditorPlugin

var b_preload = preload("main.tscn")
var b

func _enter_tree():
	b = b_preload.instantiate()

	EditorInterface.get_editor_main_screen().add_child(b)

	_make_visible(false)

	handle_buttons()

func _make_visible(visible):
	if b:
		b.visible = visible

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Other"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("GuiTabMenuHl", "EditorIcons")

func _exit_tree():
	if b:
		b.free()

func handle_buttons():
	var buttons = b.find_child("HBoxContainer").get_children()

	for i in buttons:
		b.find_child(i.name).pressed.connect(func():
			var container = b.find_child("Control")
			var res = load("res://addons/other/%s/main.tscn" % i.name).instantiate()

			var content = container.get_children()
			if content.size() != 0:
				for c in content:
					c.queue_free()

			container.add_child(res)

			if res.has_method("activate"):
				res.activate()
		)
