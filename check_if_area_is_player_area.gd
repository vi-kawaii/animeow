extends Node

func target_area(area):
	return str(area.get_parent().name) == "character" and area.get_parent().call("get_is_player")
