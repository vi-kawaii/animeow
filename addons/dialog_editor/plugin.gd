@tool
extends EditorPlugin

const BUTTON_WIDTH := 120.0

var dialog_editor_button: Button
var dialog: AcceptDialog  # Используем AcceptDialog как в примере!
var dialog_content: Control

func _enter_tree():
	_create_button()
	_create_dialog()

func _exit_tree():
	if is_instance_valid(dialog_editor_button):
		remove_control_from_container(CONTAINER_TOOLBAR, dialog_editor_button)
		dialog_editor_button.queue_free()

	if is_instance_valid(dialog):
		dialog.queue_free()

func _create_button():
	dialog_editor_button = Button.new()
	dialog_editor_button.text = "Dialog Editor"
	dialog_editor_button.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	dialog_editor_button.tooltip_text = "Open Dialog Editor"
	dialog_editor_button.pressed.connect(_open_dialog_editor)

	add_control_to_container(CONTAINER_TOOLBAR, dialog_editor_button)

func _create_dialog():
	# ТОЧНО ТАК ЖЕ как в Git Commit примере
	dialog = AcceptDialog.new()
	dialog.title = "Dialog Editor"
	dialog.size = Vector2(900, 600)
	dialog.min_size = Vector2(600, 400)

	# Окно скрыто по умолчанию (как в примере)
	dialog.visible = false

	# Загружаем главный интерфейс
	dialog_content = preload("res://addons/dialog_editor/dialog_editor_main.tscn").instantiate()
	dialog.add_child(dialog_content)

	# Добавляем диалог в редактор (как в примере)
	add_child(dialog)

func _open_dialog_editor():
	if not is_instance_valid(dialog):
		_create_dialog()
		return

	# ТОЧНО ТАК ЖЕ как в Git Commit примере
	dialog.popup_centered()

	# Обновляем список
	if is_instance_valid(dialog_content) and dialog_content.has_method("_refresh_list"):
		dialog_content._refresh_list()
