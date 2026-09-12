extends Resource

class_name DialogSentenceResource

@export var line_id: String
@export var name: String
@export_multiline var text: String
@export_enum(
	"default_middle_between",
	"player_face",
	"speaker_face",
) var camera: String = "default_middle_between"
