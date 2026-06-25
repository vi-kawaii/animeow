extends Node

var max_health = 100

var health

func _ready():
	health = max_health

func damage(dmg):
	health = max(0, health - dmg)

	if health == 0:
		die()

func die():
	get_parent().queue_free()
