extends Node3D

#@onready var enemy = load("res://characters/simple.tscn").instantiate()

func _ready() -> void:
	#add_child(enemy)
	#enemy.name = "Enemy"
	#enemy.global_transform.origin = Vector3(1, 4, 1)
	pass

func spawn(name, position):
	var c = load("res://characters/simple.tscn").instantiate()
	get_tree().root.add_child(c)
	c.name = name
	c.global_position = position
	return c
