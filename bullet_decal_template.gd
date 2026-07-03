extends Node3D

var die_after = 3.
var timer

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_die)

# Объект просто активирует то, что у него есть внутри, там, где он сейчас находится
func impact():
	$effect_from.restart()
	$effect_from.emitting = true
	timer.start(die_after)

func _die():
	teleport_to_abyss() # Объект сам убирает за собой, когда стал не нужен

func teleport_to_abyss():
	global_position = Vector3(99999, -99999, 99999)
