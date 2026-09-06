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

func _ready():
	_create_dialogs_directory()
	_refresh_list()
	_setup_signals()

func _setup_signals():
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

func _create_dialogs_directory():
	if not DirAccess.dir_exists_absolute(DIALOGS_DIR):
		DirAccess.make_dir_absolute(DIALOGS_DIR)

func _refresh_list():
	if not dialog_list:
		return

	dialog_list.clear()
	dialogs_cache.clear()

	var dir = DirAccess.open(DIALOGS_DIR)
	if dir:
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

func _on_dialog_selected(index: int):
	if not dialog_list:
		return

	var item_text = dialog_list.get_item_text(index)
	var path = DIALOGS_DIR + item_text + ".tres"

	if dialogs_cache.has(path):
		current_dialog = dialogs_cache[path]
		current_dialog_path = path
		_display_dialog(current_dialog)
	else:
		var dialog = load(path)
		if dialog:
			current_dialog = dialog
			current_dialog_path = path
			dialogs_cache[path] = dialog
			_display_dialog(dialog)

func _display_dialog(dialog: Dialog):
	if not line_edit_container:
		return

	var old_line_list = line_edit_container.get_node_or_null("LineList")
	if old_line_list:
		old_line_list.queue_free()

	if dialog == null:
		return

	var new_line_list = ItemList.new()
	new_line_list.name = "LineList"
	new_line_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line_edit_container.add_child(new_line_list)

	for i in range(dialog.lines.size()):
		var line = dialog.lines[i]
		new_line_list.add_item(str(i+1) + ". " + line.speaker + ": " + line.text)

	if speaker_input:
		speaker_input.text = ""
	if text_input:
		text_input.text = ""

func _add_line():
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

	var new_line = DialogLine.new()
	new_line.speaker = speaker
	new_line.text = text

	current_dialog.lines.append(new_line)
	_display_dialog(current_dialog)
	_mark_as_modified()

func _remove_line():
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
	current_dialog.lines.remove_at(index)
	_display_dialog(current_dialog)
	_mark_as_modified()

func _create_new_dialog():
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

	var new_dialog = Dialog.new()
	new_dialog.lines = []

	ResourceSaver.save(new_dialog, path)
	dialogs_cache[path] = new_dialog
	current_dialog = new_dialog
	current_dialog_path = path

	_refresh_list()
	_display_dialog(new_dialog)
	_show_notification("Dialog created: " + name)

func _delete_dialog():
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

func _on_delete_confirmed(confirm: ConfirmationDialog):
	if FileAccess.file_exists(current_dialog_path):
		DirAccess.remove_absolute(current_dialog_path)
		dialogs_cache.erase(current_dialog_path)
		current_dialog = null
		current_dialog_path = ""
		_refresh_list()
		_display_dialog(null)
		_show_notification("Dialog deleted")
	confirm.queue_free()

func _save_dialog():
	if not current_dialog or current_dialog_path.is_empty():
		_show_notification("No dialog to save!")
		return

	var error = ResourceSaver.save(current_dialog, current_dialog_path)
	if error == OK:
		_show_notification("Dialog saved!")
		if save_btn:
			save_btn.text = "Save"
	else:
		_show_notification("Error saving dialog!")

func _mark_as_modified():
	if save_btn:
		save_btn.text = "Save *"

func _on_name_submitted(new_text: String):
	_create_new_dialog()

func _show_notification(text: String):
	var label = Label.new()
	label.text = text
	label.modulate = Color(1, 0.8, 0.2)
	add_child(label)
	label.position = Vector2(10, 10)
	await get_tree().create_timer(2).timeout
	label.queue_free()
