@tool
extends Button

var server_resource = load("res://addons/server/resources/main.tres")

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

func _enter_tree():
	pressed.connect(func():
		activate()
	)

func activate():
	endpoints = []

	add_code()
	make_server()

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
