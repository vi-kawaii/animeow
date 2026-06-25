extends Node

var rate = .5

var shoot_from

var can_shoot = true

func _ready():
	shoot_from = $"../shoot_from"

func fire():
	if can_shoot:
		can_shoot = false
		_fire()

func _fire():
	print("shoot from " + str(self))

	await get_tree().create_timer(rate).timeout
	can_shoot = true
