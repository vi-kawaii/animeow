extends Node3D

@onready var character = get_node("../Player")

func _process(_delta: float) -> void:
	var p = RenderingServer.global_shader_parameter_get("player_position")
	#get_node("grass").material.set_shader_parameter("character_position", p)
