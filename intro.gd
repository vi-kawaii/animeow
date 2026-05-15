extends Node

var continue_pressed = false
var only_once = false

func _ready():
	if __.game_editor():
		queue_free()
		return

	%continue.connect("pressed", func():
		continue_pressed = true
	)

	%progress.text = "0%"
	__.fetch_get("/counter", func(res):
		print(res["m"])
	)

func _process(_delta):
	if only_once:
		return

	if continue_pressed and Map.loaded == Map.map.size():
		only_once = true

		get_tree().paused = false

		Map.activate()
		#get_node("../QuestsContainer").process_mode = Node.PROCESS_MODE_ALWAYS

		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		%continue.disabled = true

		var tween = create_tween()
		tween.tween_method(func(x):
			%container.modulate = Color(0, 0, 0, x)
		, 1., 0., .5)
		tween.tween_callback(func():
			queue_free()
		)

func update_loading_progress(progress):
	%progress.text = str(progress).pad_decimals(0) + "%" if progress != 100 else "Click to Play"
