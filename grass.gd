@tool
extends Node3D

var time_to_tween = .5
var t = null
var check_raycast = true

func _ready():
	if not $grass_area or not $grass_part:
		return

	$grass_area.connect("area_entered", func(area):
		if not __.target_area(area):
			return

		$grass_part.set_visible(true)

		var tween = _create_tween()
		tween.tween_method(custom_tween, 0., 1., time_to_tween)
	)
	$grass_area.connect("area_exited", func(area):
		if not __.target_area(area):
			return

		var tween = _create_tween()
		tween.tween_method(custom_tween, 1., 0., time_to_tween).connect("finished", func():
			$grass_part.set_visible(false)
		)
	)
	$grass_part.set_instance_shader_parameter("current_alpha", 0.)

func _physics_process(_delta):
	if not $grass_part:
		return

	if not Engine.is_editor_hint():
		$grass_part.set_instance_shader_parameter("player_position", Player.player.global_position)

func _create_tween():
	if t != null:
		t.stop()

	t = create_tween()
	return t

#func player_area(area):
	#return str(area.get_parent().name) == "character" and area.get_parent().call("get_is_player")

func custom_tween(x):
	$grass_part.set_instance_shader_parameter("current_alpha", x)

func request_to_change_position(pos):
	position = pos

func raycast_update():
	if not check_raycast:
		return

	var space_state = EditorInterface.get_editor_viewport_3d().get_camera_3d().get_world_3d().direct_space_state

	var end = Vector3(0, -1000, 0)

	var middle_ray = PhysicsRayQueryParameters3D.create(position, position + end)
	var rays = []
	var delta = .25
	rays.append(PhysicsRayQueryParameters3D.create(position + Vector3(delta, 0, delta), position + end))
	rays.append(PhysicsRayQueryParameters3D.create(position + Vector3(-delta, 0, -delta), position + end))
	rays.append(PhysicsRayQueryParameters3D.create(position + Vector3(delta, 0, -delta), position + end))
	rays.append(PhysicsRayQueryParameters3D.create(position + Vector3(-delta, 0, delta), position + end))

	var mid = middle_ray

	var mid_result = space_state.intersect_ray(mid)
	var rays_result = []
	for i in rays:
		rays_result.append(space_state.intersect_ray(i))

	if mid_result and mid_result["collider"].get_parent().name.ends_with("-grass"):
		var pos = mid_result["position"]
		position = pos
	else:
		queue_free()
		return

	var names = []

	for ray in rays_result:
		if ray and ray["collider"].get_parent().name.ends_with("-grass"):
			names.append(ray["collider"].name)
			check_raycast = false

	var _pass = false

	for n in names:
		if n != names[0]:
			_pass = true

	if _pass:
		queue_free()
		return

	if names.size() != 4:
		queue_free()
		return

	visible = true
