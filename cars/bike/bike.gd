extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	steering = Input.get_axis("car_right", "car_left") * 500
	engine_force = Input.get_axis("car_forward", "car_back") * 500
