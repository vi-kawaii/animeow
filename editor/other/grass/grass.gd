extends EditorPlugin

var b

func _enter_tree():
	b = preload("main.tscn").instantiate()
	add_control_to_container(CONTAINER_TOOLBAR, b)

func _exit_tree():
	remove_control_from_docks(b)
	b.free()
