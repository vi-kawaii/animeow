@tool
extends Control

@onready var dialog_list = $VBox/HSplitContainer/DialogList/ItemList
@onready var line_edit_container = $VBox/HSplitContainer/LineEditContainer
@onready var speaker_input = $VBox/HSplitContainer/LineEditContainer/VBox2/SpeakerInput
@onready var text_input = $VBox/HSplitContainer/LineEditContainer/VBox2/TextInput
@onready var add_line_btn = $VBox/HSplitContainer/LineEditContainer/VBox2/HBox2/AddLineBtn
@onready var remove_line_btn = $VBox/HSplitContainer/LineEditContainer/VBox2/HBox2/RemoveLineBtn
@onready var dialog_name_input = $VBox/HBox/DialogNameInput
@onready var create_btn = $VBox/HBox/CreateBtn
@onready var delete_btn = $VBox/HBox/DeleteBtn
@onready var save_btn = $VBox/HBox/SaveBtn

var current_dialog: Dialog = null
var current_dialog_path: String = ""
var dialogs_cache: Dictionary = {}

const DIALOGS_DIR = "res://dialogs/"


func _ready() -> void:
	_create_dialogs_directory()
	_setup_signals()
	_refresh_list()


func _setup_signals() -> void:
	if add_line_btn:
		add_line_btn.pressed.connect(_add_line)
	if remove_line_btn:
		remove_line_btn.pressed.connect(_remove_line)
	if create_btn:
		create_btn.pressed.connect(_create_new_dialog)
	if delete_btn:
		delete_btn.pressed.connect(_delete_dialog)
	if save_btn:
		save_btn.pressed.connect(_save_dialog)
	if dialog_list:
		dialog_list.item_selected.connect(_on_dialog_selected)
	if dialog_name_input:
		dialog_name_input.text_submitted.connect(_on_name_submitted)


func _create_dialogs_directory() -> void:
	if not DirAccess.dir_exists_absolute(DIALOGS_DIR):
		DirAccess.make_dir_absolute(DIALOGS_DIR)


# ---------------------------------------------------------------------------
# Загрузка
# ---------------------------------------------------------------------------

func _load_editable(path: String) -> Dialog:
	var res = load(path)
	if res == null:
		return null

	var raw_lines = res.get("lines")
	var fixed := _repair_lines_array(raw_lines, path)
	res.set("lines", fixed)

	return res


func _repair_lines_array(raw, path: String) -> Array[DialogLine]:
	var fresh: Array[DialogLine] = []

	if raw != null:
		for item in raw:
			if item is DialogLine:
				fresh.append(item)
			elif item is Resource:
				var dl := DialogLine.new()
				if "speaker" in item:
					dl.speaker = str(item.get("speaker"))
				if "text" in item:
					dl.text = str(item.get("text"))
				fresh.append(dl)

	if fresh.is_empty():
		fresh = _parse_lines_from_file(path)

	return fresh


func _parse_lines_from_file(path: String) -> Array[DialogLine]:
	var result: Array[DialogLine] = []
	var content = FileAccess.get_file_as_string(path)
	if content.is_empty():
		return result

	var chunks = content.split("[sub_resource")
	for chunk in chunks:
		if chunk.find("speaker") == -1 or chunk.find("text") == -1:
			continue
		if chunk.find("script = ExtResource") != -1 and chunk.find("\nlines") != -1:
			continue

		var dl := DialogLine.new()
		dl.speaker = _extract_string_value(chunk, "speaker")
		dl.text = _extract_string_value(chunk, "text")
		if dl.speaker.is_empty() and dl.text.is_empty():
			continue
		result.append(dl)

	return result


func _extract_string_value(block: String, key: String) -> String:
	var marker := key + " = \""
	var start := block.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := block.find("\"", start)
	if end == -1:
		return ""
	return block.substr(start, end - start)


# ---------------------------------------------------------------------------
# Список диалогов
# ---------------------------------------------------------------------------

func _refresh_list() -> void:
	if not dialog_list:
		return

	if dialog_list.item_selected.is_connected(_on_dialog_selected):
		dialog_list.item_selected.disconnect(_on_dialog_selected)

	dialog_list.clear()
	dialogs_cache.clear()

	var dir = DirAccess.open(DIALOGS_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var path = DIALOGS_DIR + file_name
				dialog_list.add_item(file_name.replace(".tres", ""))
				var dialog = load(path)
				if dialog:
					dialogs_cache[path] = dialog
			file_name = dir.get_next()
		dir.list_dir_end()

	if not dialog_list.item_selected.is_connected(_on_dialog_selected):
		dialog_list.item_selected.connect(_on_dialog_selected)


func _on_dialog_selected(index: int) -> void:
	if not dialog_list:
		return
	if index < 0 or index >= dialog_list.item_count:
		return

	var item_text = dialog_list.get_item_text(index)
	var path = DIALOGS_DIR + item_text + ".tres"

	var dialog = _load_editable(path)
	if dialog:
		current_dialog = dialog
		current_dialog_path = path
		_display_dialog(current_dialog)


# ---------------------------------------------------------------------------
# Отображение (переиспользуем один ItemList)
# ---------------------------------------------------------------------------

func _display_dialog(dialog: Dialog) -> void:
	if not line_edit_container:
		return

	var line_list = line_edit_container.get_node_or_null("LineList")
	if line_list == null:
		line_list = ItemList.new()
		line_list.name = "LineList"
		line_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		line_edit_container.add_child(line_list)

	line_list.clear()

	if dialog == null:
		if speaker_input:
			speaker_input.text = ""
		if text_input:
			text_input.text = ""
		return

	var lines = dialog.get("lines")
	if lines != null:
		for i in range(lines.size()):
			var line = lines[i]
			line_list.add_item(str(i + 1) + ". " + line.speaker + ": " + line.text)

	if speaker_input:
		speaker_input.text = ""
	if text_input:
		text_input.text = ""


# ---------------------------------------------------------------------------
# Редактирование строк
# ---------------------------------------------------------------------------

func _add_line() -> void:
	if not current_dialog:
		_show_notification("Please select or create a dialog first!")
		return

	if not speaker_input or not text_input:
		return

	var speaker = speaker_input.text.strip_edges()
	var text = text_input.text.strip_edges()

	if speaker.is_empty() or text.is_empty():
		_show_notification("Please fill in all fields!")
		return

	var new_line := DialogLine.new()
	new_line.speaker = speaker
	new_line.text = text

	var fresh: Array[DialogLine] = []
	var existing = current_dialog.get("lines")
	if existing != null:
		for l in existing:
			if l is DialogLine:
				fresh.append(l)
	fresh.append(new_line)
	current_dialog.set("lines", fresh)

	_display_dialog(current_dialog)
	_mark_as_modified()


func _remove_line() -> void:
	if not current_dialog:
		return

	if not line_edit_container:
		return

	var line_list = line_edit_container.get_node_or_null("LineList")
	if not line_list:
		return

	var selected = line_list.get_selected_items()
	if selected.is_empty():
		_show_notification("Please select a line to delete!")
		return

	var index = selected[0]
	var existing = current_dialog.get("lines")
	if existing == null or index < 0 or index >= existing.size():
		return

	var fresh: Array[DialogLine] = []
	for i in range(existing.size()):
		if i != index and existing[i] is DialogLine:
			fresh.append(existing[i])
	current_dialog.set("lines", fresh)

	_display_dialog(current_dialog)
	_mark_as_modified()


# ---------------------------------------------------------------------------
# Создание / удаление / сохранение
# ---------------------------------------------------------------------------

func _create_new_dialog() -> void:
	if not dialog_name_input:
		return

	var name = dialog_name_input.text.strip_edges()
	if name.is_empty():
		_show_notification("Please enter a dialog name!")
		return

	var path = DIALOGS_DIR + name + ".tres"
	if FileAccess.file_exists(path):
		_show_notification("A dialog with this name already exists!")
		return

	var new_dialog := Dialog.new()
	new_dialog.set("lines", [] as Array[DialogLine])

	var save_err = ResourceSaver.save(new_dialog, path)
	if save_err != OK:
		_show_notification("Error creating dialog! Code: " + str(save_err))
		return

	var editable = _load_editable(path)
	if editable == null:
		_show_notification("Error creating dialog!")
		return

	current_dialog = editable
	current_dialog_path = path
	dialogs_cache[path] = load(path)

	_refresh_list()
	_display_dialog(current_dialog)
	_show_notification("Dialog created: " + name)


func _delete_dialog() -> void:
	if not current_dialog or current_dialog_path.is_empty():
		_show_notification("Please select a dialog to delete!")
		return

	var dialog_name = current_dialog_path.get_file()

	var confirm = ConfirmationDialog.new()
	confirm.title = "Confirm Deletion"
	confirm.dialog_text = "Delete dialog '" + dialog_name + "'?"
	confirm.ok_button_text = "Delete"
	confirm.cancel_button_text = "Cancel"
	add_child(confirm)
	confirm.confirmed.connect(_on_delete_confirmed.bind(confirm))
	confirm.popup_centered()


func _on_delete_confirmed(confirm: ConfirmationDialog) -> void:
	if FileAccess.file_exists(current_dialog_path):
		DirAccess.remove_absolute(current_dialog_path)
		dialogs_cache.erase(current_dialog_path)
		current_dialog = null
		current_dialog_path = ""
		_refresh_list()
		_display_dialog(null)
		_show_notification("Dialog deleted")
	confirm.queue_free()


func _save_dialog() -> void:
	if not current_dialog or current_dialog_path.is_empty():
		_show_notification("No dialog to save!")
		return

	var to_save := Dialog.new()
	var existing = current_dialog.get("lines")
	var fresh: Array[DialogLine] = []
	if existing != null:
		for l in existing:
			if l is DialogLine:
				fresh.append(l)
	to_save.set("lines", fresh)

	var error = ResourceSaver.save(to_save, current_dialog_path)
	if error != OK:
		_show_notification("Error saving dialog! Code: " + str(error))
		return

	_show_notification("Dialog saved!")
	if save_btn:
		save_btn.text = "Save"

	dialogs_cache[current_dialog_path] = load(current_dialog_path)

	var editable = _load_editable(current_dialog_path)
	if editable:
		current_dialog = editable
		_display_dialog(current_dialog)


# ---------------------------------------------------------------------------
# Утилиты
# ---------------------------------------------------------------------------

func _mark_as_modified() -> void:
	if save_btn:
		save_btn.text = "Save *"


func _on_name_submitted(_new_text: String) -> void:
	_create_new_dialog()


func _show_notification(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1, 0.8, 0.2)
	add_child(label)
	label.position = Vector2(10, 10)
	await get_tree().create_timer(2).timeout
	if is_instance_valid(label):
		label.queue_free()
