extends Node
##
## SaveManager — состояние в виде Dictionary.
##
## База (дефолт) лежит в  res://data/save/default.json
## Пользовательский сейв в user://data/save.json
##
## Логика:
##   1) грузим базу из res://data/save/default.json
##   2) грузим пользовательский сейв из user://data/save.json
##   3) если сейва нет — state = база
##   4) если сейв есть — state = нормализованный сейв
##

const SAVE_NAME    := "save"
const DEFAULT_NAME := "save/default"

var state: Dictionary = {}
var _default: Dictionary = {}

signal loaded

func _ready() -> void:
	Resources.load(DEFAULT_NAME, _on_default_loaded, false)

func _on_default_loaded(data: Dictionary) -> void:
	if data.is_empty():
		push_error("SaveManager: не удалось загрузить %s.json" % DEFAULT_NAME)
		_default = _fallback_default()
	else:
		_default = _normalize(data)

	Resources.load(SAVE_NAME, _on_save_loaded, true)

func _on_save_loaded(data: Dictionary) -> void:
	if data.is_empty():
		state = _default.duplicate(true)
	else:
		state = _normalize(data)
	loaded.emit()

# ---------------------------------------------------------------------------
# Публичное API
# ---------------------------------------------------------------------------

func save() -> void:
	Resources.save(SAVE_NAME, state, _on_save_written)

func _on_save_written(path: String) -> void:
	if path.is_empty():
		push_error("SaveManager: сохранение не удалось")
	else:
		print("SaveManager: сохранено в ", path)

## Сброс к базе (например, кнопка «Новая игра»)
func reset_to_default() -> void:
	state = _default.duplicate(true)

# ---------------------------------------------------------------------------
# Нормализация / fallback
# ---------------------------------------------------------------------------

static func _fallback_default() -> Dictionary:
	return {
		"character_position": [0.0, 0.0, 0.0],
		"camera_data": {
			"angle_x": 0.0,
			"angle_y": 0.0,
			"current_radius": 0.0,
		},
		"completed_quests": [],
		"started_branches": [],
		"branches_current_indexes": [],
	}

func _normalize(d: Dictionary) -> Dictionary:
	var out: Dictionary = _fallback_default()

	for key_v in d.keys():
		var key: String = key_v
		out[key] = d[key]

	# character_position
	var p_v: Variant = out.get("character_position", [0.0, 0.0, 0.0])
	if typeof(p_v) != TYPE_ARRAY or (p_v as Array).size() < 3:
		out["character_position"] = [0.0, 0.0, 0.0]
	else:
		var p: Array = p_v
		out["character_position"] = [float(p[0]), float(p[1]), float(p[2])]

	# camera_data
	var cam_v: Variant = out.get("camera_data", {})
	if typeof(cam_v) != TYPE_DICTIONARY:
		out["camera_data"] = {
			"angle_x": 0.0,
			"angle_y": 0.0,
			"current_radius": 0.0,
		}
	else:
		var cam: Dictionary = cam_v
		out["camera_data"] = {
			"angle_x": float(cam.get("angle_x", 0.0)),
			"angle_y": float(cam.get("angle_y", 0.0)),
			"current_radius": float(cam.get("current_radius", 0.0)),
		}

	# массивы
	for key in ["completed_quests", "started_branches", "branches_current_indexes"]:
		if typeof(out.get(key)) != TYPE_ARRAY:
			out[key] = []

	return out
