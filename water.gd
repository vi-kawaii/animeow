extends Node

func _process(_delta):
	if __.game_editor():
		queue_free()
		return

	var p = Player.camera.position
	p.y = 0
	%mesh.position = p
