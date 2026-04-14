@tool
extends EditorPlugin

var server_runned = false
var path_to_server = "D:\\Games\\GodotGame\\godot-cpp\\demo\\server\\main.js"

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
