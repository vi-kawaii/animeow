extends Node

var refs = []
var _done: bool = false

func _ready():
	Resources.load("intro/scenes_order", func(data):
		print(data)
		for scene in data.scenes_res:
			if scene == null:
				push_warning("intro: сцена не загрузилась")
				continue
			var n = scene.instantiate()
			refs.append(n)
			Pathes.load(n.get_node("pathes").get_children())
			call_deferred("add_child", n)
	)

func _process(_delta):
	if _done:
		return
	var p := Resources.progress() * 100.0
	Intro.update_loading_progress(p)
	if p >= 100.0:
		_done = true

func activate():
	Player.set_process_mode(PROCESS_MODE_ALWAYS)
	for i in refs:
		i.set_process_mode(PROCESS_MODE_ALWAYS)

	Quests.map_already_loaded = true
