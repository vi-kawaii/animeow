extends Node

func _ready():
	if __.game_editor():
		return

	toggle_to_fullscreen_mode()

func toggle_to_fullscreen_mode():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
