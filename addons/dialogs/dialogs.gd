@tool
extends EditorPlugin

var b

func _enter_tree():
	b = preload("button.tscn").instantiate()

	var w = b.get_node("window")
	w.hide()
	w.close_requested.connect(func():
		w.hide()
	)

	b.pressed.connect(func():
		w.show()
	)

	add_control_to_container(CONTAINER_TOOLBAR, b)

func _exit_tree():
	remove_control_from_docks(b)
	b.free()
