#extends Node3D
#
#@export var save: Save
#
#func _ready():
	#_load()
#
#func _load():
	#if not ResourceLoader.exists("user://save.res"):
		#return
#
	#save = load("user://save.res")
#
#func _save():
	#ResourceSaver.save(save, "user://save.res")
