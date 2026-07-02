extends Node3D

var die_after = 3.

var timer

func _ready():
	visible = false

	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_die)

func impact():
	_decal()
	_effects()
	_run_timer_to_die()

func _decal():
	visible = true
	print("decal activated")

func _effects():
	$effect_from.restart()
	$effect_from.emitting = true
	print("cool effect from decal")

func _run_timer_to_die():
	print("some timer to delete decal")
	timer.start(die_after)

func _die():
	print("decal animated and deactivated")
	visible = false
