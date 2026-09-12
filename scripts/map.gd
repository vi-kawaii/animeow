extends Node

var map = [
	"res://main.tscn",
]
var progress = []
var loaded = 0
var refs = []

func _ready():
	for i in map:
		Resources.load(i, func(res):
			var n = res.instantiate()
			refs.append(n)
			Pathes.load(n.get_node("pathes").get_children())
			call_deferred("add_child", n)
			loaded += 1
		)
		progress.append(0)

func _process(_delta):
	if loaded == map.size():
		return

	for i in range(map.size()):
		progress[i] = Resources.progress(map[i])

	var total_progress = 0
	for i in range(progress.size()):
		total_progress += progress[i]

	total_progress /= progress.size()
	total_progress *= 100

	Intro.update_loading_progress(total_progress)

func activate():
	Player.set_process_mode(PROCESS_MODE_ALWAYS)
	for i in refs:
		i.set_process_mode(PROCESS_MODE_ALWAYS)

	Quests.map_already_loaded = true
