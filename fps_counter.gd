extends CanvasLayer

func _process(_delta):
	%fps.text = str(Engine.get_frames_per_second()).pad_decimals(0)
