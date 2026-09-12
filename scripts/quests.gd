extends Node3D

var quests = []
var distances = []
var i = -1

@onready var save = get_tree().root.get_node("World").find_child("Save")

func _ready() -> void:
	load_quests()

func load_quests():
	quests = $QuestsList.get_children()
	quests = quests.filter(func(x):
		return x.visible and not save.get_save().get_completed_quests().has(x.quest_name)
	)
	quests.map(func(x):
		x.start()
	)

func unload_quest(name):
	quests = quests.filter(func(x):
		return x.quest_name != name
	)

func mark_quest_as_completed(name):
	save.save.completed_quests.append(name)

func _process(delta: float) -> void:
	sort_by_closest()
	update_quests_ui()

func sort_by_closest():
	i = -1
	distances = quests.map(func(x):
		i += 1
		var p = get_player()

		var forward = p.get_parent().camera.global_transform.basis.z.normalized()
		forward.y = 0
		forward = forward.normalized()

		var angle = forward.signed_angle_to(x.pos.direction_to(p.global_position), Vector3.UP)
		angle = rad_to_deg(angle)
		if angle < 0:
			angle += 360
		return [p.global_position.distance_to(x.pos), i, angle]
	)
	distances.sort_custom(func(a, b):
		return a[0] < b[0]
	)

func get_player():
	return get_tree().root.get_node("World").find_child("Player", true, false).get_player()

func update_quests_ui():
	var s = quests.size()
	if s >= 1:
		find_child("First").text = quests[distances[0][1]].name + ": " + str(roundi(distances[0][0])) + "m " + get_angle_symbol(distances[0][2])
		find_child("First").get_parent().get_parent().set_visible(true)
	else:
		find_child("First").get_parent().get_parent().set_visible(false)
	if s >= 2:
		find_child("Second").text = quests[distances[1][1]].name + ": " + str(roundi(distances[1][0])) + "m " + get_angle_symbol(distances[1][2])
		find_child("Second").get_parent().get_parent().set_visible(true)
	else:
		find_child("Third").get_parent().get_parent().set_visible(false)
	if s >= 3:
		find_child("Third").text = quests[distances[2][1]].name + ": " + str(roundi(distances[2][0])) + "m " + get_angle_symbol(distances[1][2])
		find_child("Third").get_parent().get_parent().set_visible(true)
	else:
		find_child("Third").get_parent().get_parent().set_visible(false)

func get_angle_symbol(angle):
	var a = ""
	if angle > 360 - 22.5 or angle <= 0 + 22.5:
		a = "⇑"
	if angle > 0 + 22.5 and angle <= 0 + 45 + 22.5:
		a = "⇖"
	if angle > 0 + 45 + 22.5 and angle <= 90 + 22.5:
		a = "⇐"
	if angle > 90 + 22.5 and angle <= 90 + 45 + 22.5:
		a = "⇙"
	if angle > 90 + 45 + 22.5 and angle <= 180 + 22.5:
		a = "⇓"
	if angle > 180 + 22.5 and angle <= 180 + 45 + 22.5:
		a = "⇘"
	if angle > 180 + 45 + 22.5 and angle <= 180 + 90 + 22.5:
		a = "⇒"
	if angle > 180 + 90 + 22.5 and angle <= 360 - 22.5:
		a = "⇗"
	return a

func add_quest(quest_name):
	pass

func complete_quest(quest_name):
	pass
