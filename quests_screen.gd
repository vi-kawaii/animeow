extends CanvasLayer

var tracked_quests = []

func load_quests_tracking_state(b):
	if tracked_quests.find(b.text.replace("    ", "")) != -1:
		b.text = "    [%s]" % b.text.substr(4)

func activate():
	Resources.load("res://quests_button.tscn", func(res):
		for i in Quests.current_quests:
			var b = res.instantiate()
			b.text = "    %s" % i.capitalize()
			load_quests_tracking_state(b)
			b.connect("pressed", func():
				if b.text[4] == "[":
					Quests.untrack_quest(i)
					b.text = b.text.replace("[", "").replace("]", "")
					tracked_quests.remove_at(tracked_quests.find(b.text.replace("    ", "")))
				else:
					Quests.track_quest(i)
					tracked_quests.append(b.text.substr(4))
					b.text = "    [%s]" % b.text.substr(4)
			)
			%quests_buttons_container.add_child(b)
	)

func deactivate():
	for i in %quests_buttons_container.get_children():
		i.queue_free()
