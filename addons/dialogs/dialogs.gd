@tool
extends EditorPlugin

var b_preload = preload("button.tscn")
var b

func _enter_tree():
	b = b_preload.instantiate()

	EditorInterface.get_editor_main_screen().add_child(b)

	_make_visible(false)

func _make_visible(visible):
	print(visible)
	if b:
		b.visible = visible

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Dialog"

func _exit_tree():
	if b:
		b.free()
