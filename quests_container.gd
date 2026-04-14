extends Node

var quests = "quests.tres"
var quests_scenes = "quests/%s.tscn"

var current_quests: PackedStringArray
var current_quest: String
var current_quests_scenes = []
var current_quests_scenes_names = []

var map_already_loaded = false
var only_once = false

func track_quest(t):
	var quest_to_track
	var label

	quest_to_track = current_quests_scenes_names.find(t)

	if quest_to_track != -1:
		current_quest = t
		label = current_quests_scenes[quest_to_track].find_child("Label3D")

	quest_to_track = current_quests_scenes_names.find(t)
	label = current_quests_scenes[quest_to_track].find_child("Label3D")

	if label:
		label.set_visible(true)

func untrack_quest(t):
	var quest_to_track
	var label

	quest_to_track = current_quests_scenes_names.find(t)

	if quest_to_track != -1:
		current_quest = t
		label = current_quests_scenes[quest_to_track].find_child("Label3D")

	if label:
		label.set_visible(false)

	quest_to_track = current_quests_scenes_names.find(t)
	label = current_quests_scenes[quest_to_track].find_child("Label3D")

func _ready():
	Resources.load(quests, func(res):
		var b = Save.state.started_branches
		var idx = Save.state.branches_current_indexes

		if b.size() == 0:
			b = [true, true]
		if idx.size() == 0:
			idx = [0, 0]

		for i in range(b.size()):
			if (!b[i]):
				continue

			var quest_name = res.data[i].quests[idx[i]]
			Resources.load(quests_scenes % quest_name, func(res2):
				var n = res2.instantiate()
				add_child(n)
				current_quests_scenes.append(n)
				current_quests_scenes_names.append(n.name)
			)
			current_quests.append(quest_name)
	)

func _process(_delta):
	if only_once:
		return

	if not map_already_loaded:
		return

	for i in current_quests_scenes:
		i.set_process_mode(PROCESS_MODE_ALWAYS)
