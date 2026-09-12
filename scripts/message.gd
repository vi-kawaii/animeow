extends Control

func log(text):
	%text.text = text
	visible = true

	var t = create_tween()
	t.tween_property(self, "modulate", Color(1., 1., 1., 1.), .2)
	t.tween_callback(func():
		await get_tree().create_timer(1.).timeout

		var t2 = create_tween()
		t2.tween_property(self, "modulate", Color(1., 1., 1., 0.), .2)
		t2.tween_callback(func():
			visible = false
		)
	)
