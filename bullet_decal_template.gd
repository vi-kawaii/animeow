extends Node3D

func _ready():
	visible = false

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
	_die()

func _die():
	visible = false
	print("decal animated and deactivated")
