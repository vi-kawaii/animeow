extends Node3D

var quest_name = "Third Quest"
@onready var c = get_tree().root.get_node("World").find_child("Characters")
@onready var d = get_tree().root.get_node("World").find_child("Dialogs")
var char

func start() -> void:
	char = c.spawn("RandomCharacter4", Vector3(3, 8, 1))

var pos: Vector3

func _process(delta: float) -> void:
	if not char:
		return
	pos = get_tree().root.find_child("RandomCharacter4", true, false).position

func complete():
	print(quest_name + " completed")
	set_visible(false)
