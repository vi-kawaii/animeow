extends Resource
class_name DialogLine

@export var speaker: String = ""
@export var text: String = ""

func _init(p_speaker: String = "", p_text: String = ""):
	speaker = p_speaker
	text = p_text
