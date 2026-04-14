extends Node

@export var state: SaveResource

func _ready():
	if !ResourceLoader.exists("user://save.res"):
		return

	state = ResourceLoader.load("user://save.res")

func save():
	ResourceSaver.save(state, "user://save.res")
