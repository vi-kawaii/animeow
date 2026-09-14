extends Node
##
## Resources — единый загрузчик/сохранятель JSON.
##
## Чтение:
##  - load("intro/scenes_order", callback) →
##      res://data/intro/scenes_order.json
##  - load("save", callback, true) →
##      user://data/save.json
##  - парсит JSON в фоне (WorkerThreadPool)
##  - находит ключи вида "<base>_res" (например "scene_res", "sound_res")
##  - по схеме (res://data/_schema.json) собирает полный путь к ресурсу
##  - грузит ресурсы через ResourceLoader.load_threaded_request (в фоне)
##  - кэширует ресурсы по пути
##  - в колбэк отдаёт data, где data.scene_res — уже готовый Resource
##  - поддержка массивов под *_res: "scenes_res": ["main", "intro/forest"]
##    → data.scenes_res = [PackedScene, PackedScene]
##
## Запись:
##  - save("save", data, callback) → пишет user://data/save.json
##  - ресурсы (*_res) заменяются на относительные имена по схеме
##  - Vector3 → [x, y, z], PackedByteArray/PackedInt64Array → Array
##  - запись в фоне (WorkerThreadPool)
##
## Прогресс: Resources.progress() -> float (0.0 .. 1.0), опрашивать из _process
##

const DATA_ROOT   := "res://data/"
const USER_ROOT   := "user://data/"
const SCHEMA_PATH := "res://data/_schema.json"
const RES_SUFFIX  := "_res"

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

func load(name: String, callback: Callable, from_user: bool = false) -> int:
	var id: int = _next_id
	_next_id += 1

	var root: String = USER_ROOT if from_user else DATA_ROOT

	var task: Dictionary = {
		"id": id,
		"name": name,
		"path": root + name + ".json",
		"callback": callback,
		"data": {},
		"res_requests": {},
		"json_done": false,
		"finished": false,
		"weight": 1.0,
		"done_weight": 0.0,
		"is_save": false,
	}
	_tasks[id] = task
	_total_weight += 1.0
	set_process(true)

	var path: String = task["path"]
	_start_json_read(id, path)
	return id

func save(name: String, data: Variant, callback: Callable = Callable()) -> int:
	var id: int = _next_id
	_next_id += 1

	var clean: Variant = _sanitize_for_json(data)
	var text: String = JSON.stringify(clean, "\t")
	var path: String = USER_ROOT + name + ".json"

	var task: Dictionary = {
		"id": id,
		"name": name,
		"path": path,
		"callback": callback,
		"data": {},
		"res_requests": {},
		"json_done": true,
		"finished": false,
		"weight": 1.0,
		"done_weight": 0.0,
		"is_save": true,
	}
	_tasks[id] = task
	_total_weight += 1.0
	set_process(true)

	WorkerThreadPool.add_task(func() -> void:
		DirAccess.make_dir_recursive_absolute(USER_ROOT)
		var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			push_error("Resources: не удалось открыть на запись %s" % path)
			call_deferred("_on_save_finished", id, "")
			return
		f.store_string(text)
		f.close()
		call_deferred("_on_save_finished", id, path)
	)
	return id

func save_sync(name: String, data: Variant) -> Error:
	var clean: Variant = _sanitize_for_json(data)
	var text: String = JSON.stringify(clean, "\t")
	DirAccess.make_dir_recursive_absolute(USER_ROOT)
	var f: FileAccess = FileAccess.open(USER_ROOT + name + ".json", FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	return OK

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
	var text: String = FileAccess.get_file_as_string(SCHEMA_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Resources: не удалось распарсить схему %s" % SCHEMA_PATH)
		_schema = {}
		return
	_schema = parsed as Dictionary

# ---------------------------------------------------------------------------
# Чтение и парсинг JSON
# ---------------------------------------------------------------------------

func _start_json_read(id: int, path: String) -> void:
	if not FileAccess.file_exists(path):
		_finish_task(id, {})
		return
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		_finish_task(id, {})
		return

	WorkerThreadPool.add_task(func() -> void:
		var parsed: Variant = JSON.parse_string(text)
		call_deferred("_on_json_parsed", id, parsed)
	)

func _on_json_parsed(id: int, parsed: Variant) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]

	var t: int = typeof(parsed)
	if t != TYPE_DICTIONARY and t != TYPE_ARRAY:
		var p: String = task["path"]
		push_error("Resources: %s — не Dictionary и не Array" % p)
		_finish_task(id, {})
		return

	task["data"] = parsed
	task["json_done"] = true

	var requests: Dictionary = {}
	_collect_res_requests(parsed, requests)

	var total_res: int = 0
	for key_v in requests.keys():
		var key: String = key_v
		var info: Dictionary = requests[key]
		if info.get("is_multi", false):
			var paths_arr: Array = info["paths"]
			total_res += paths_arr.size()
		else:
			total_res += 1

	task["weight"] = 1.0 + float(total_res)
	_total_weight += float(total_res)

	if requests.is_empty():
		_finish_task(id, parsed)
		return

	task["res_requests"] = requests
	for key_v in requests.keys():
		var key: String = key_v
		var info: Dictionary = requests[key]
		if info.get("is_multi", false):
			var paths_arr: Array = info["paths"]
			for entry_v in paths_arr:
				var entry: Dictionary = entry_v
				var p: String = entry["path"]
				_start_resource_load(id, key, p)
		else:
			var p: String = info["path"]
			_start_resource_load(id, key, p)

# ---------------------------------------------------------------------------
# Сбор *_res
# ---------------------------------------------------------------------------

func _collect_res_requests(node: Variant, requests: Dictionary) -> void:
	var t: int = typeof(node)
	if t == TYPE_DICTIONARY:
		var dict: Dictionary = node
		for key_v in dict.keys():
			if typeof(key_v) != TYPE_STRING:
				continue
			var key: String = key_v
			var value: Variant = dict[key]
			if key.ends_with(RES_SUFFIX):
				var base: String = key.trim_suffix(RES_SUFFIX)
				if typeof(value) == TYPE_ARRAY:
					var paths: Array = []
					var value_arr: Array = value
					for item in value_arr:
						if typeof(item) == TYPE_STRING:
							var item_str: String = item
							var p: String = _resolve_res_path(base, item_str)
							if not p.is_empty():
								paths.append({ "name": item_str, "path": p })
					if not paths.is_empty():
						requests[key] = { "paths": paths, "base": base, "is_multi": true }
				else:
					var full_path: String = _resolve_res_path(base, value)
					if not full_path.is_empty():
						if not requests.has(key):
							requests[key] = { "path": full_path, "base": base, "is_multi": false }
			else:
				_collect_res_requests(value, requests)
	elif t == TYPE_ARRAY:
		var arr: Array = node
		for item in arr:
			_collect_res_requests(item, requests)

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

	var value_str: String = value

	var value_ext: String = value_str.get_extension()
	if not value_ext.is_empty():
		var direct: String = dir + value_str
		if FileAccess.file_exists(direct):
			return direct

	for ext_v in exts:
		var ext_str: String = ext_v
		var candidate: String = dir + value_str + ext_str
		if FileAccess.file_exists(candidate):
			return candidate

	push_warning("Resources: ресурс '%s' не найден в %s с расширениями %s" % [value_str, dir, exts])
	return ""

func _res_to_name(base: String, res: Resource) -> String:
	if res == null:
		return ""
	if not _schema.has(base):
		push_warning("Resources: нет схемы для '%s_res' при сохранении" % base)
		return ""

	var entry: Dictionary = _schema[base]
	var dir: String = entry.get("dir", "")
	var exts: Array = entry.get("exts", [])

	var path: String = res.resource_path
	if path.is_empty():
		push_warning("Resources: ресурс '%s' не имеет resource_path, сохранить нельзя" % res)
		return ""

	if not path.begins_with(dir):
		push_warning("Resources: '%s' вне схемной папки '%s'" % [path, dir])
		return ""
	var rel: String = path.substr(dir.length())

	var ext: String = rel.get_extension()
	if ext != "" and exts.has("." + ext):
		rel = rel.substr(0, rel.length() - ext.length() - 1)

	return rel

# ---------------------------------------------------------------------------
# Сериализация в JSON
# ---------------------------------------------------------------------------

func _sanitize_for_json(node: Variant) -> Variant:
	var t: int = typeof(node)

	match t:
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			var src: Dictionary = node
			for key_v in src.keys():
				if typeof(key_v) != TYPE_STRING:
					var raw_key: Variant = key_v
					out[raw_key] = _sanitize_for_json(src[raw_key])
					continue
				var key: String = key_v
				var value: Variant = src[key]
				if key.ends_with(RES_SUFFIX):
					var base: String = key.trim_suffix(RES_SUFFIX)
					if typeof(value) == TYPE_ARRAY:
						var arr_out: Array = []
						var value_arr: Array = value
						for item in value_arr:
							if item is Resource:
								arr_out.append(_res_to_name(base, item))
							elif item == null:
								arr_out.append(null)
							else:
								arr_out.append(_sanitize_for_json(item))
						out[key] = arr_out
					elif value is Resource:
						out[key] = _res_to_name(base, value)
					elif value == null:
						out[key] = null
					else:
						out[key] = _sanitize_for_json(value)
				else:
					out[key] = _sanitize_for_json(value)
			return out

		TYPE_ARRAY:
			var arr: Array = []
			var src_arr: Array = node
			for item in src_arr:
				arr.append(_sanitize_for_json(item))
			return arr

		TYPE_VECTOR3:
			var v3: Vector3 = node
			return [v3.x, v3.y, v3.z]

		TYPE_VECTOR2:
			var v2: Vector2 = node
			return [v2.x, v2.y]

		TYPE_COLOR:
			var c: Color = node
			return [c.r, c.g, c.b, c.a]

		TYPE_PACKED_BYTE_ARRAY:
			var pb: PackedByteArray = node
			return Array(pb)

		TYPE_PACKED_INT32_ARRAY:
			var pi32: PackedInt32Array = node
			return Array(pi32)

		TYPE_PACKED_INT64_ARRAY:
			var pi64: PackedInt64Array = node
			return Array(pi64)

		TYPE_PACKED_FLOAT32_ARRAY:
			var pf32: PackedFloat32Array = node
			return Array(pf32)

		TYPE_PACKED_FLOAT64_ARRAY:
			var pf64: PackedFloat64Array = node
			return Array(pf64)

		TYPE_PACKED_STRING_ARRAY:
			var ps: PackedStringArray = node
			return Array(ps)

		TYPE_PACKED_VECTOR2_ARRAY:
			var pv2: PackedVector2Array = node
			var out_v2: Array = []
			for v in pv2:
				out_v2.append([v.x, v.y])
			return out_v2

		TYPE_PACKED_VECTOR3_ARRAY:
			var pv3: PackedVector3Array = node
			var out_v3: Array = []
			for v in pv3:
				out_v3.append([v.x, v.y, v.z])
			return out_v3

	return node

# ---------------------------------------------------------------------------
# Загрузка ресурсов
# ---------------------------------------------------------------------------

func _start_resource_load(id: int, key: String, path: String) -> void:
	if _resource_cache.has(path):
		var cached: Resource = _resource_cache[path]
		_on_resource_loaded(id, key, path, cached)
		return

	var err: int = ResourceLoader.load_threaded_request(path, "", true, ResourceLoader.CACHE_MODE_REUSE)
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
		var loaded_count: int = info.get("loaded_count", 0)
		for entry_v in paths:
			var entry: Dictionary = entry_v
			if entry["path"] == path and not entry.has("result"):
				entry["result"] = res
				loaded_count += 1
				break
		info["loaded_count"] = loaded_count
		if loaded_count >= paths.size():
			var arr: Array = []
			for entry_v2 in paths:
				var entry2: Dictionary = entry_v2
				arr.append(entry2.get("result"))
			var task_data: Dictionary = task["data"]
			task_data[key] = arr
			info["loaded"] = true
	else:
		info["loaded"] = true
		var task_data2: Dictionary = task["data"]
		task_data2[key] = res

	var done_w: float = float(task["done_weight"]) + 1.0
	task["done_weight"] = done_w
	_done_weight += 1.0

	_try_finish_task(id)

func _try_finish_task(id: int) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	if not task["json_done"]:
		return
	var requests: Dictionary = task["res_requests"]
	for key_v in requests.keys():
		var key: String = key_v
		var info: Dictionary = requests[key]
		if not info.get("loaded", false):
			return
	var data: Variant = task["data"]
	_finish_task(id, data)

func _finish_task(id: int, data: Variant) -> void:
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

	if cb.is_valid():
		cb.call(data)

func _on_save_finished(id: int, path: String) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	task["done_weight"] = 1.0
	_done_weight += 1.0
	var cb: Callable = task["callback"]
	_tasks.erase(id)
	if _tasks.is_empty():
		set_process(false)
	if cb.is_valid():
		cb.call(path)

# ---------------------------------------------------------------------------
# Опрос ресурсов
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	for id_v in _tasks.keys():
		var id: int = id_v
		var task: Dictionary = _tasks[id]
		if task.get("is_save", false):
			continue
		var requests: Dictionary = task["res_requests"]
		for key_v in requests.keys():
			var key: String = key_v
			var info: Dictionary = requests[key]
			if info.get("loaded", false):
				continue

			if info.get("is_multi", false):
				var paths: Array = info["paths"]
				for entry_v in paths:
					var entry: Dictionary = entry_v
					if entry.has("result"):
						continue
					var p: String = entry["path"]
					_poll_one_resource(id, key, p, info)
			else:
				var p: String = info["path"]
				_poll_one_resource(id, key, p, info)

func _poll_one_resource(id: int, key: String, path: String, info: Dictionary) -> void:
	var progress_arr: Array = []
	var status: int = ResourceLoader.load_threaded_get_status(path, progress_arr)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var res: Resource = ResourceLoader.load_threaded_get(path)
			_on_resource_loaded(id, key, path, res)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_warning("Resources: не удалось загрузить %s" % path)
			_on_resource_loaded(id, key, path, null)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = 0.0
			if progress_arr.size() > 0:
				p = float(progress_arr[0])
			var prev: float = float(info.get("partial", 0.0))
			var diff: float = p - prev
			if diff > 0.0:
				info["partial"] = p
				_task_partial_add(id, diff)

func _task_partial_add(id: int, diff: float) -> void:
	if not _tasks.has(id):
		return
	var task: Dictionary = _tasks[id]
	task["done_weight"] = float(task["done_weight"]) + diff
	_done_weight += diff
