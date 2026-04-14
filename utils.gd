extends Node

const hostname = "http://localhost:3000"

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
