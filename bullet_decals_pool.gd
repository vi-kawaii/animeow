extends Node3D

var default_size = 10

var bullet_decal_template = preload("res://bullet_decal_template.tscn")

var array = []

func _ready():
	for i in range(default_size):
		var b = bullet_decal_template.instantiate()
		array.append(b)
		add_child(b)

func create(pos, normal):
	print("spawned decal somewhere", pos, normal)

	var b = array[-1]
	b.position = pos
	b.normal = normal
	b.impact()
