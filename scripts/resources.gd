extends Node

# Карта активных задач: path -> { "task_id": int, "callback": Callable, "result": Variant, "done": bool }
var _tasks: Dictionary = {}

# Общий счётчик для прогресса: сколько всего запущено и сколько завершено
var _total: int = 0
var _completed: int = 0

func load(path: String, callback: Callable) -> void:
	# Если задача по этому пути уже есть — не дублируем
	if _tasks.has(path):
		push_warning("JsonLoader: задача для %s уже в очереди" % path)
		return

	# Читаем файл в главном потоке (быстро), парсим в фоне
	var json_string := FileAccess.get_file_as_string(path)
	if json_string.is_empty():
		push_error("JsonLoader: не удалось прочитать файл %s" % path)
		callback.call(null)
		return

	var task_id := WorkerThreadPool.add_task(_parse_json.bind(path, json_string))
	_tasks[path] = {
		"task_id": task_id,
		"callback": callback,
		"result": null,
		"done": false,
	}
	_total += 1

func _parse_json(path: String, json_string: String) -> void:
	# Выполняется в фоновом потоке
	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		push_error("JsonLoader: ошибка парсинга JSON в %s" % path)
	# Возвращаемся в главный поток, чтобы безопасно обновить данные
	call_deferred("_mark_done", path, parsed)

func _mark_done(path: String, result: Variant) -> void:
	if not _tasks.has(path):
		return
	var t: Dictionary = _tasks[path]
	t["result"] = result
	t["done"] = true

	# Очищаем задачу, она уже завершена — ждать не придётся
	if WorkerThreadPool.is_task_completed(t["task_id"]):
		WorkerThreadPool.wait_for_task_completion(t["task_id"])

func _process(_delta: float) -> void:
	var done: Array = []
	for path in _tasks:
		var t: Dictionary = _tasks[path]
		if t["done"]:
			t["callback"].call(t["result"])
			done.append(path)
	for path in done:
		_tasks.erase(path)
		_completed += 1

	# Если все задачи завершены — сбрасываем счётчики
	if _total > 0 and _completed >= _total:
		_total = 0
		_completed = 0

func progress(path: String) -> float:
	# Если конкретный path ещё в очереди — считаем общий прогресс
	if _tasks.has(path):
		if _total <= 0:
			return 0.0
		return float(_completed) / float(_total)
	# Если path уже завершён (или не существует) — считаем готовым
	return 1.0
