extends Resource
class_name Dialog

@export var lines: Array[DialogLine] = []

func add_line(speaker: String, text: String):
	var new_line = DialogLine.new(speaker, text)
	lines.append(new_line)

func get_line(index: int) -> DialogLine:
	if index >= 0 and index < lines.size():
		return lines[index]
	return null

func remove_line(index: int):
	if index >= 0 and index < lines.size():
		lines.remove_at(index)

func clear():
	lines.clear()
