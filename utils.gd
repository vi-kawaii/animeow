extends Node

const hostname = "http://localhost:3000"

var once = true

func fetch_get(url, callback):
	var req = HTTPRequest.new()
	add_child(req)
	req.request(hostname + url)
	req.request_completed.connect(func(_result, _response_code, _headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		var res = json
		callback.call(res)
		req.queue_free()
	)

func target_area(area):
	return str(area.get_parent().name) == "character" and area.get_parent().call("get_is_player")

func game_editor():
	var args = OS.get_cmdline_user_args()

	if args and args[0] == "--game-editor":
		return true

	toggle_to_fullscreen_mode_once()
	return false

func toggle_to_fullscreen_mode_once():
	if not once:
		return

	once = false

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
