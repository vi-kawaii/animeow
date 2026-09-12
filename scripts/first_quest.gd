extends Node3D

var quest_name = "First Quest"
@onready var c = get_tree().root.get_node("World").find_child("Characters")
var char

func start() -> void:
	char = c.spawn("RandomCharacter", Vector3(1, 8, 1))
	var d = load("res://dialog/areas/dialog_area.tscn").instantiate()
	d.dialog_name = "start"
	d.callback = complete
	char.add_child(d)

var pos: Vector3

func _process(delta: float) -> void:
	if not char:
		return
	pos = get_tree().root.find_child("RandomCharacter", true, false).position

func complete():
	print(quest_name + " completed")
	var q = get_parent().get_parent()
	q.unload_quest(quest_name)
	q.mark_quest_as_completed(quest_name)
	char.queue_free()
	queue_free()
