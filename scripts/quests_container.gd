extends Node

const MEET_STRANGER := "meet_stranger"

var map_already_loaded := false
var only_once := false
var active_quest_id := ""

var _hud


func _ready() -> void:
	_hud = preload("res://quest_hud.tscn").instantiate()
	add_child(_hud)


func _process(_delta: float) -> void:
	if only_once:
		return
	if not map_already_loaded:
		return

	only_once = true
	_try_start_meet_stranger()


func _try_start_meet_stranger() -> void:
	if _is_completed(MEET_STRANGER):
		return

	active_quest_id = MEET_STRANGER
	_hud.show_quest("Познакомься", "Поговори с незнакомцем")


func on_dialog_response(_from_node: String, to_node: String, _label: String) -> void:
	if active_quest_id != MEET_STRANGER:
		return
	if to_node == "hello":
		complete_quest(MEET_STRANGER)


func complete_quest(quest_id: String) -> void:
	if quest_id != active_quest_id:
		return

	if not _is_completed(quest_id):
		if Save.state.completed_quests == null:
			Save.state.completed_quests = []
		Save.state.completed_quests.append(quest_id)
		Save.save()

	active_quest_id = ""
	_hud.show_completed("Познакомься")


func _is_completed(quest_id: String) -> bool:
	if Save.state == null or Save.state.completed_quests == null:
		return false
	return Save.state.completed_quests.has(quest_id)
