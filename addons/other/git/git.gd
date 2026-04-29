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
		b.find_child("message").grab_focus()
	)

	b.find_child("message").text_submitted.connect(func(t):
		w.hide()

		if t == "":
			return

		OS.execute("git", ["add", "."])
		OS.execute("git", ["commit", "-m", t])
		OS.execute("git", ["push"])

		b.find_child("message").text = ""
	)

	add_control_to_container(CONTAINER_TOOLBAR, b)

func _exit_tree():
	remove_control_from_docks(b)
	b.free()
