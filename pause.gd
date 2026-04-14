extends Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	find_child("Exit").pressed.connect(exit)

func _process(_delta: float) -> void:
	pass

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		get_node("CanvasLayer").set_visible(get_tree().paused)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED)

func exit():
	get_node("../Save").save()
	get_tree().quit()
