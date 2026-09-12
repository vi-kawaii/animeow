extends Node3D

var delta = .5
var grass_size = 20
var grass_height = 2

var instances = []

var already_hidden = false

func make_grid(n):
	var half = floor(n / 2.0)
	var coords = []
	for y in range(int(-half), int(half) + 1):
		for x in range(int(-half), int(half) + 1):
			coords.append(Vector2(x, y))
	return coords

func _ready():
	Resources.load("res://map/common/grass.tscn", func(res):
		var p = Player.player.position
		for i in make_grid(grass_size):
			var n = res.instantiate()
			n.position = snapped(p, Vector3(delta, delta, delta)) + Vector3(delta * i[0], 0, delta * i[1])
			n.position.y = grass_height
			add_child(n)
			instances.append(n)
			#n.visible = false
	)

func _process(_delta):
	#position_update()
	raycast_update()

	if already_hidden:
		return

	hide_grass_update()

func position_update():
	var p = Player.player.position
	var new_grass = []

	for i in make_grid(grass_size):
		var pos = snapped(p, Vector3(delta, delta, delta)) + Vector3(delta * i[0], 0, delta * i[1])
		pos.y = grass_height
		new_grass.append(pos)

	var old_grass_non_changing = []
	var new_grass_non_changing = []

	for i in instances.size():
		for k in new_grass.size():
			if instances[i].position.x == new_grass[k].x and instances[i].position.z == new_grass[k].z:
				old_grass_non_changing.append(i)
				new_grass_non_changing.append(k)

	for i in instances.size():
		var new_grass_x = new_grass[i][0]
		var new_grass_z = new_grass[i][2]
		instances[i].request_to_change_position(Vector3(new_grass_x, grass_height, new_grass_z))

	return

	for i in old_grass_non_changing.size():
		var idx = new_grass_non_changing[i]
		var new_grass_x = new_grass[idx][0]
		var new_grass_z = new_grass[idx][2]

		#var pos = snapped(p, Vector3(delta, delta, delta)) + Vector3(delta * new_grass_x, 0, delta * new_grass_z)
		#pos.y = grass_height

		idx = old_grass_non_changing[i]
		instances[idx].request_to_change_position(Vector3(new_grass_x, grass_height, new_grass_z))

func raycast_update():
	for grass in instances:
		if grass == null:
			return

		grass.raycast_update()

func hide_grass_update():
	var mark_to_delete = []
	for i in instances.size():
		if instances[i] != null and instances[i].position.y == grass_height:
			mark_to_delete.append(i)
			instances[i].queue_free()
			instances[i] = null
