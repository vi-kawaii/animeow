@tool
extends EditorPlugin

const BUTTON_WIDTH := 100.0

var commit_button: Button
var dialog: AcceptDialog
var message_edit: LineEdit

var git_pid: int = -1
var current_message := ""
var current_step := 0

var steps := [
	["add", ["add", "."]],
	["commit", []],
	["push", ["push"]]
]


func _enter_tree() -> void:
	_create_button()
	_create_dialog()


func _exit_tree() -> void:
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
	if git_pid != -1:
		return

	message_edit.text = ""
	dialog.popup_centered()
	message_edit.grab_focus()


func _commit_confirmed() -> void:
	var message: String = message_edit.text.strip_edges()

	if message.is_empty():
		return

	current_message = message
	current_step = 0

	dialog.hide()
	_set_button_state("Sending...", false)

	_start_git_step()


func _start_git_step() -> void:
	if current_step >= steps.size():
		_finish(true)
		return

	var step_name: String = steps[current_step][0]
	var args: PackedStringArray = PackedStringArray(
		steps[current_step][1]
	)

	if step_name == "commit":
		args = PackedStringArray([
			"commit",
			"-m",
			current_message
		])

	var process := OS.execute_with_pipe(
		"git",
		args,
		false
	)

	if process.is_empty():
		_finish(false)
		return

	git_pid = process["pid"]

	set_process(true)


func _process(_delta: float) -> void:
	if git_pid == -1:
		return

	var exit_code := OS.get_process_exit_code(git_pid)

	if exit_code == -1:
		return

	git_pid = -1

	if exit_code != 0:
		_finish(false)
		return

	current_step += 1
	_start_git_step()


func _finish(success: bool) -> void:
	set_process(false)

	if success:
		_set_button_state("✓ Done", true)

		await get_tree().create_timer(2.0).timeout

		if is_instance_valid(commit_button):
			commit_button.text = "Commit"
	else:
		_set_button_state("✗ Error", true)

		await get_tree().create_timer(3.0).timeout

		if is_instance_valid(commit_button):
			commit_button.text = "Commit"


func _set_button_state(text: String, enabled: bool) -> void:
	commit_button.text = text
	commit_button.disabled = not enabled
	commit_button.custom_minimum_size.x = BUTTON_WIDTH
