extends Panel


func _ready():
	get_node(".").mouse_entered.connect(func(): print(get_node(".").theme.styles.panel))
	get_node(".").mouse_exited.connect(func(): pass)


func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1):
			get_tree().quit()
