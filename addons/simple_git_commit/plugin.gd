@tool
extends EditorPlugin

const BUTTON_WIDTH := 100.0

var commit_button: Button
var dialog: AcceptDialog
var message_edit: LineEdit

var worker: Thread
var worker_running := false

var result_success := false
var result_error := ""


func _enter_tree() -> void:
	_create_button()
	_create_dialog()


func _exit_tree() -> void:
	if worker_running and worker != null:
		worker.wait_to_finish()
		worker = null
		worker_running = false

	if is_instance_valid(commit_button):
		remove_control_from_container(CONTAINER_TOOLBAR, commit_button)
		commit_button.queue_free()

	if is_instance_valid(dialog):
		dialog.queue_free()


func _create_button() -> void:
	commit_button = Button.new()
	commit_button.text = "Commit"
	commit_button.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	commit_button.tooltip_text = "Commit and push changes"
	commit_button.pressed.connect(_open_commit_dialog)

	add_control_to_container(CONTAINER_TOOLBAR, commit_button)


func _create_dialog() -> void:
	dialog = AcceptDialog.new()
	dialog.title = "Commit"

	message_edit = LineEdit.new()
	message_edit.placeholder_text = "Commit message..."
	message_edit.custom_minimum_size = Vector2(350, 0)

	dialog.add_child(message_edit)
	dialog.confirmed.connect(_commit_confirmed)

	add_child(dialog)


func _open_commit_dialog() -> void:
	if worker_running:
		return

	message_edit.text = ""
	dialog.popup_centered()
	message_edit.grab_focus()


func _commit_confirmed() -> void:
	var message: String = message_edit.text.strip_edges()

	if message.is_empty():
		return

	dialog.hide()

	_set_button_state("Sending...", false)

	result_success = false
	result_error = ""
	worker_running = true

	worker = Thread.new()
	worker.start(_git_worker.bind(message))

	set_process(true)


func _git_worker(message: String) -> void:
	var commands := [
		PackedStringArray(["add", "."]),
		PackedStringArray(["commit", "-m", message]),
		PackedStringArray(["push"])
	]

	for args in commands:
		var output: Array = []
		var exit_code := OS.execute(
			"git",
			args,
			output,
			true
		)

		if exit_code != 0:
			result_success = false

			var error_text := ""

			for line in output:
				error_text += str(line) + "\n"

			result_error = error_text.strip_edges()

			return

	result_success = true


func _process(_delta: float) -> void:
	if not worker_running:
		return

	if worker.is_alive():
		return

	worker.wait_to_finish()
	worker = null
	worker_running = false

	set_process(false)

	if result_success:
		_finish_success()
	else:
		_finish_error()


func _finish_success() -> void:
	_set_button_state("✓ Done", true)

	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(commit_button):
		commit_button.text = "Commit"


func _finish_error() -> void:
	_set_button_state("✗ Error", true)

	var error_dialog := AcceptDialog.new()
	error_dialog.title = "Git Error"
	error_dialog.dialog_text = result_error

	add_child(error_dialog)
	error_dialog.popup_centered(Vector2(600, 300))

	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(commit_button):
		commit_button.text = "Commit"


func _set_button_state(text: String, enabled: bool) -> void:
	commit_button.text = text
	commit_button.disabled = not enabled
	commit_button.custom_minimum_size.x = BUTTON_WIDTH
