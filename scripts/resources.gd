extends Node
##
## Resources — единый загрузчик JSON из res://data/.
##
##  - load("intro/scenes_order", callback) →
##      res://data/intro/scenes_order.json
##  - парсит JSON в фоне (WorkerThreadPool)
##  - находит ключи вида "<base>_res" (например "scene_res", "sound_res")
##  - по схеме (res://data/_schema.json) собирает полный путь к ресурсу
##  - грузит ресурсы через ResourceLoader.load_threaded_request (в фоне)
##  - кэширует ресурсы по пути
##  - в колбэк отдаёт data, где data.scene_res — уже готовый Resource
##  - поддержка массивов под *_res: "scenes_res": ["main", "intro/forest"]
##    → data.scenes_res = [PackedScene, PackedScene]
##
## Прогресс: Resources.progress() -> float (0.0 .. 1.0), опрашивать из _process
##

const DATA_ROOT := "res://data/"
const SCHEMA_PATH := "res://data/_schema.json"
const RES_SUFFIX := "_res"

var _schema: Dictionary = {}
var _resource_cache: Dictionary = {}
var _tasks: Dictionary = {}
var _next_id: int = 0
var _total_weight: float = 0.0
var _done_weight: float = 0.0

func _ready() -> void:
	set_process(false)
	_load_schema()

# ---------------------------------------------------------------------------
# Публичное API
# ---------------------------------------------------------------------------

func load(name: String, callback: Callable) -> int:
	var id := _next_id
	_next_id += 1

	var task := {
		"id": id,
		"name": name,
		"path": DATA_ROOT + name + ".json",
		"callback": callback,
		"data": {},
		"res_requests": {},
		"json_done": false,
		"finished": false,
		"weight": 1.0,
		"done_weight": 0.0,
	}
	_tasks[id] = task
	_total_weight += 1.0
	set_process(true)

	_start_json_read(id, task["path"])
	return id

func progress() -> float:
	if _total_weight <= 0.0:
		return 1.0
	return clampf(_done_weight / _total_weight, 0.0, 1.0)

# ---------------------------------------------------------------------------
# Схема
# ---------------------------------------------------------------------------

func _load_schema() -> void:
	if not FileAccess.file_exists(SCHEMA_PATH):
		push_warning("Resources: схема не найдена (%s)" % SCHEMA_PATH)
		_schema = {}
		return
	var text := FileAccess.get_file_as_string(SCHEMA_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Resources: не удалось распарсить схему %s" % SCHEMA_PATH)
		_schema = {}
		return
	_schema = parsed

# ---------------------------------------------------------------------------
# Чтение и парсинг JSON
# ---------------------------------------------------------------------------

func _start_json_read(id: int, path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Resources: не удалось прочитать %s" % path)
		_finish_task(id, {})
		return

	WorkerThreadPool.add_task(func():
		var parsed = JSON.parse_string(text)
		call_deferred("_on_json_parsed", id, parsed)
	)

func _on_json_parsed(id: int, parsed: Variant) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]

	var t := typeof(parsed)
	if t != TYPE_DICTIONARY and t != TYPE_ARRAY:
		push_error("Resources: %s — не Dictionary и не Array" % task["path"])
		_finish_task(id, {})
		return

	task["data"] = parsed
	task["json_done"] = true

	var requests: Dictionary = {}
	_collect_res_requests(parsed, requests)

	# Вес: JSON + каждый ресурс (включая элементы массивов)
	var total_res := 0
	for key in requests:
		var info: Dictionary = requests[key]
		if info.get("is_multi", false):
			total_res += info["paths"].size()
		else:
			total_res += 1

	task["weight"] = 1.0 + float(total_res)
	_total_weight += float(total_res)

	if requests.is_empty():
		_finish_task(id, parsed)
		return

	task["res_requests"] = requests
	for key in requests:
		var info: Dictionary = requests[key]
		if info.get("is_multi", false):
			for entry in info["paths"]:
				_start_resource_load(id, key, entry["path"])
		else:
			_start_resource_load(id, key, info["path"])

# Рекурсивно ищет *_res-ключи.
#   - одиночное значение: { key: { path, base, is_multi=false } }
#   - массив значений:    { key: { paths: [...], base, is_multi=true } }
func _collect_res_requests(node: Variant, requests: Dictionary) -> void:
	var t := typeof(node)
	if t == TYPE_DICTIONARY:
		for key in node.keys():
			var value = node[key]
			if typeof(key) == TYPE_STRING and key.ends_with(RES_SUFFIX):
				var base := (key as String).trim_suffix(RES_SUFFIX)
				if typeof(value) == TYPE_ARRAY:
					var paths: Array = []
					for item in value:
						if typeof(item) == TYPE_STRING:
							var p := _resolve_res_path(base, item)
							if not p.is_empty():
								paths.append({ "name": item, "path": p })
					if not paths.is_empty():
						requests[key] = { "paths": paths, "base": base, "is_multi": true }
				else:
					var full_path := _resolve_res_path(base, value)
					if not full_path.is_empty():
						if not requests.has(key):
							requests[key] = { "path": full_path, "base": base, "is_multi": false }
			else:
				_collect_res_requests(value, requests)
	elif t == TYPE_ARRAY:
		for item in node:
			_collect_res_requests(item, requests)

# base: "scene", value: "intro/main"
#   → "res://scenes/intro/main.tscn"
func _resolve_res_path(base: String, value: Variant) -> String:
	if typeof(value) != TYPE_STRING:
		push_warning("Resources: значение для '%s_res' не строка (%s)" % [base, value])
		return ""
	if not _schema.has(base):
		push_warning("Resources: нет схемы для поля '%s_res'" % base)
		return ""

	var entry: Dictionary = _schema[base]
	var dir: String = entry.get("dir", "")
	var exts: Array = entry.get("exts", [])
	if dir.is_empty() or exts.is_empty():
		push_warning("Resources: схема для '%s' пустая" % base)
		return ""

	# После проверки typeof выше — можно безопасно привести
	var value_str: String = value

	# Если в value уже есть расширение — пробуем как есть
	var value_ext: String = value_str.get_extension()
	if not value_ext.is_empty():
		var direct: String = dir + value_str
		if FileAccess.file_exists(direct):
			return direct

	for ext in exts:
		var ext_str: String = ext
		var candidate: String = dir + value_str + ext_str
		if FileAccess.file_exists(candidate):
			return candidate

	push_warning("Resources: ресурс '%s' не найден в %s с расширениями %s" % [value_str, dir, exts])
	return ""

# ---------------------------------------------------------------------------
# Загрузка ресурсов
# ---------------------------------------------------------------------------

func _start_resource_load(id: int, key: String, path: String) -> void:
	if _resource_cache.has(path):
		_on_resource_loaded(id, key, path, _resource_cache[path])
		return

	var err := ResourceLoader.load_threaded_request(path, "", true, ResourceLoader.CACHE_MODE_REUSE)
	if err != OK:
		push_warning("Resources: не удалось начать загрузку %s (err %d)" % [path, err])
		_on_resource_loaded(id, key, path, null)
		return

func _on_resource_loaded(id: int, key: String, path: String, res: Resource) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	var requests: Dictionary = task["res_requests"]
	if not requests.has(key):
		return
	var info: Dictionary = requests[key]

	if res != null:
		_resource_cache[path] = res

	if info.get("is_multi", false):
		var paths: Array = info["paths"]
		for entry in paths:
			if entry["path"] == path and not entry.has("result"):
				entry["result"] = res
				info["loaded_count"] = info.get("loaded_count", 0) + 1
				break
		if info["loaded_count"] >= paths.size():
			var arr: Array = []
			for entry in paths:
				arr.append(entry.get("result"))
			task["data"][key] = arr
			info["loaded"] = true
	else:
		info["loaded"] = true
		task["data"][key] = res

	task["done_weight"] = float(task["done_weight"]) + 1.0
	_done_weight += 1.0

	_try_finish_task(id)

func _try_finish_task(id: int) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	if not task["json_done"]:
		return
	var requests: Dictionary = task["res_requests"]
	for key in requests:
		if not requests[key].get("loaded", false):
			return
	_finish_task(id, task["data"])

func _finish_task(id: int, data) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	if task["finished"]:
		return
	task["finished"] = true

	var cb: Callable = task["callback"]
	_tasks.erase(id)
	if _tasks.is_empty():
		set_process(false)

	cb.call(data)

# ---------------------------------------------------------------------------
# Опрос ресурсов
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	for id in _tasks.keys():
		var task: Dictionary = _tasks[id]
		var requests: Dictionary = task["res_requests"]
		for key in requests.keys():
			var info: Dictionary = requests[key]
			if info.get("loaded", false):
				continue

			if info.get("is_multi", false):
				for entry in info["paths"]:
					if entry.has("result"):
						continue
					_poll_one_resource(id, key, entry["path"], info)
			else:
				_poll_one_resource(id, key, info["path"], info)

func _poll_one_resource(id: int, key: String, path: String, info: Dictionary) -> void:
	var progress_arr: Array = []
	var status := ResourceLoader.load_threaded_get_status(path, progress_arr)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path)
			_on_resource_loaded(id, key, path, res)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_warning("Resources: не удалось загрузить %s" % path)
			_on_resource_loaded(id, key, path, null)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = 0.0
			if progress_arr.size() > 0:
				p = float(progress_arr[0])
			var prev: float = info.get("partial", 0.0)
			var diff: float = p - prev
			if diff > 0.0:
				info["partial"] = p
				_task_partial_add(id, diff)

func _task_partial_add(id: int, diff: float) -> void:
	if not _tasks.has(id):
		return
	_tasks[id]["done_weight"] = float(_tasks[id]["done_weight"]) + diff
	_done_weight += diff
