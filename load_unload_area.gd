extends Area3D

@export var resource_name: String

var resource_handle

func _ready():
	connect("area_entered", area_entered)
	connect("area_exited", area_exited)

func area_entered(a):
	if not CheckIfAreaIsPlayerArea.target_area(a):
		return

	Resources.load(resource_name, func(res):
		resource_handle = res.instantiate()
		add_child(resource_handle)
	)

func area_exited(a):
	if not CheckIfAreaIsPlayerArea.target_area(a):
		return

	if not resource_handle:
		return

	resource_handle.queue_free()
