extends EditorPlugin

var server_runned = false
var path_to_server = "D:\\Games\\GodotGame\\server\\main.js"

func _process(_delta):
	return
	if EditorInterface.is_playing_scene() and not server_runned:
		server_runned = true
		OS.create_process("bun", ["--hot", "run", path_to_server])
		return

	if not EditorInterface.is_playing_scene() and server_runned:
		server_runned = false
		OS.execute("taskkill", ["/f", "/im", "bun.exe"])
		return

var b

func _enter_tree():
	b = preload("button.tscn").instantiate()
	add_control_to_container(CONTAINER_TOOLBAR, b)

func _exit_tree():
	remove_control_from_docks(b)
	b.free()
