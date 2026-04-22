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

	var push_to_repo_button = b.find_child("push_to_repo")

	push_to_repo_button.pressed.connect(func():
		var message_textedit = b.find_child("message")
		if message_textedit.text == "":
			return

		OS.execute("git", ["add", "."])
		OS.execute("git", ["commit", "-m", message_textedit.text])
		OS.execute("git", ["push"])

		w.hide()
		message_textedit.text = ""
	)

	add_control_to_container(CONTAINER_TOOLBAR, b)

func _exit_tree():
	remove_control_from_docks(b)
	b.free()
