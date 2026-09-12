extends Node3D

var waves
var offset = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	waves = get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for x in waves:
		x.global_transform.origin.y = sin(offset + x.global_transform.origin.z) / 4 - 2
	
	offset += delta
