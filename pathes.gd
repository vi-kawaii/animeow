extends Node3D

var pathes = []
var names = []

func load(children):
	for i in range(children.size()):
		names.append(children[i].get_name())
		pathes.append(children[i].get_children())

func get_next_node_from_path_if_close(from, path_name, i, distance):
	var idx
	for k in range(names.size()):
		if names[k] == path_name:
			idx = k
			break

	var pos = pathes[idx][i].get_global_position()

	if pos.distance_to(from) < distance:
		i += 1
		if i == pathes[idx].size():
			i = 0

		pos = pathes[idx][i].get_global_position()

	var r = []
	r.append(pos)
	r.append(i)
	return r
