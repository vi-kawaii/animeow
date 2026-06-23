extends Node3D

var quest_name = "Fourth Quest"
@onready var c = get_tree().root.get_node("World").find_child("Characters")
var char

func start() -> void:
	char = c.spawn("RandomCharacter2", Vector3(6, 8, 1))

var pos: Vector3

func _process(delta: float) -> void:
	if not char:
		return
	pos = get_tree().root.find_child("RandomCharacter2", true, false).position

func complete():
	print(quest_name + " completed")
	set_visible(false)
