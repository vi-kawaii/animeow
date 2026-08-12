extends Node

var callbacks = {}

func load(path, callback):
	ResourceLoader.load_threaded_request(path)
	callbacks[path] = callback

func _process(_delta):
	var done: Array = []
	for i in callbacks:
		if ResourceLoader.load_threaded_get_status(i) == ResourceLoader.THREAD_LOAD_LOADED:
			callbacks[i].call(ResourceLoader.load_threaded_get(i))
			done.append(i)
	for i in done:
		callbacks.erase(i)

func progress(path):
	var p = []
	ResourceLoader.load_threaded_get_status(path, p)

	return p[0]
