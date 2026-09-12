extends MeshInstance3D

#@onready var character = get_tree().root.get_node("World").find_child("Player")
#
#func _process(_delta: float) -> void:
	#pass
	##RenderingServer.global_shader_parameter_set("player_position", character.player.global_transform.origin)

func _process(_delta):
	if get_node("../../Map/Player"):
		position = get_node("../../Map/Player/Camera").position
		position.y = 0
