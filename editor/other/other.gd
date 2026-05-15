extends MarginContainer

func _ready():
	handle_buttons()

func handle_buttons():
	var buttons = find_child("HBoxContainer").get_children()

	for i in buttons:
		find_child(i.name).pressed.connect(func():
			var container = find_child("Control")
			var res = load("res://editor/other/%s/main.tscn" % i.name).instantiate()

			var content = container.get_children()
			if content.size() != 0:
				for c in content:
					c.queue_free()

			container.add_child(res)

			if res.has_method("activate"):
				res.activate()
		)
