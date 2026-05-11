@tool
extends MarginContainer

var server_resource = load("res://addons/other/server/resources/main.tres")

func add_code():
	for i in server_resource.endpoints:
		match i.type:
			"get":
				__get(i.url)
			"post":
				__post(i.url)

var endpoints = []

func __get(url):
	var code_template = """
		  .get("%s", () => {
		    return { m: `data is ${data++}` }
		  })
	""".strip_edges() % url

	endpoints.append(code_template)

func __post(url):
	var code_template = """
		  .post("%s", ({ params: { id, pw } }) => {
		    console.log({ id, pw })

		    const is_unique = true

		    return { m: is_unique ? "" : "Your id is not unique" }
		  })
	""".strip_edges() % url

	endpoints.append(code_template)

var dialog_line = load("res://addons/other/dialogs/components/dialog_line.tscn")
var dialog_lines = []

var endpoint_action = load("res://addons/other/server/components/endpoint_action.tscn")
var endpoint_actions = []

func handle_window():
	%create_new_dialog_line.pressed.connect(func():
		var e = add_dialog_line()

		#var cna = e.find_child("create_new_action")
		#cna.pressed.connect(func():
			#var ea = endpoint_action.instantiate()
			#endpoint_actions.append(ea)
			#cna.add_sibling(ea)
		#)
	)

	%search.text_submitted.connect(func(t):
		if !t:
			return

		update_ui_by_search(t)
	)

func update_ui_by_search(t):
	pass

func add_dialog_line(param = null):
	var e = dialog_line.instantiate()
	dialog_lines.append(e)
	%dialog_lines_container.add_child(e)

	if !param:
		return e

	if param.type == "get":
		e.find_child("OptionButton")._select_int(0)
	elif param.type == "post":
		e.find_child("OptionButton")._select_int(1)

	e.find_child("TextEdit2").text = param.url
	e.title = param.url

	return e

func activate():
	handle_window()

	#endpoints = []

	#load_endpoints()
	#add_code()
	#make_server()

func load_endpoints():
	var server = load("res://addons/other/server/resources/main.tres")
	endpoints = server.endpoints

	for i in endpoints:
		add_dialog_line(i)

func make_server():
	var server_code = """
		import { SQL } from "bun"
		import { Elysia } from "elysia"

		const connection_string = "postgres://postgres:admin@localhost:5432/main"

		const sql = new SQL(connection_string)

		let data = 0

		new Elysia()
		  %s.listen(3000)
	""".strip_edges()

	var server_code_endpoints = ""
	for i in endpoints:
		server_code_endpoints += i + "\n  "

	server_code = server_code % server_code_endpoints

	server_code = server_code.replace("\t", "")

	save_text_to_file(server_code)

	print("server generated successfully")

func save_text_to_file(t):
	var f = FileAccess.open("res://server/server_file.js", FileAccess.WRITE)

	if !f:
		print("Error")
		return

	f.store_string(t)
