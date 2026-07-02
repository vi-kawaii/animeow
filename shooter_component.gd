extends Node

var rate = .5
var ray_length = 1000
var dmg = 50

var hit_mask = 5

var shoot_from
var effects_component

var can_shoot = true

func _ready():
	shoot_from = $"../shoot_from"
	effects_component = $"../effects_component"

func fire():
	if can_shoot:
		can_shoot = false
		_fire()

func _effects():
	effects_component.fire()

func _fire():
	_effects()

	var space_state = shoot_from.get_world_3d().direct_space_state

	# Пытаемся получить камеру (сработает только для игрока)
	var camera = Player.camera

	var target_point: Vector3

	# ЛОГИКА ДЛЯ ИГРОКА (ЧЕРЕЗ КАМЕРУ)
	# Проверяем, управляет ли этим скриптом игрок (есть камера и это не бот)
	if camera and shoot_from.get_parent().get_parent().is_in_group("player"):
		var screen_center = get_viewport().size / 2
		var cam_ray_start = camera.project_ray_origin(screen_center)
		var cam_ray_end = cam_ray_start + camera.project_ray_normal(screen_center) * ray_length

		var cam_query = PhysicsRayQueryParameters3D.create(cam_ray_start, cam_ray_end)
		cam_query.collision_mask = hit_mask
		cam_query.exclude = [shoot_from.get_parent().get_rid()]

		var cam_result = space_state.intersect_ray(cam_query)
		target_point = cam_result.position if cam_result else cam_ray_end

	# ЛОГИКА ДЛЯ ВРАГА (ПРЯМОЙ ВЫСТРЕЛ ИЗ СТВОЛА)
	else:
		# Враги стреляют прямо туда, куда смотрит их ствол shoot_from
		var forward_vector = -shoot_from.global_transform.basis.z
		target_point = shoot_from.global_position + (forward_vector * ray_length)

	# ОСНОВНОЙ ВЫСТРЕЛ ИЗ ОРУЖИЯ (Одинаковый для всех)
	var weapon_query = PhysicsRayQueryParameters3D.create(shoot_from.global_position, target_point)
	weapon_query.collision_mask = hit_mask
	weapon_query.exclude = [shoot_from.get_parent().get_rid()]

	var weapon_result = space_state.intersect_ray(weapon_query)

	if weapon_result:
		var hit_object = weapon_result.collider
		print(shoot_from.get_parent().get_parent().name, " попал в ", hit_object.name)

		BulletDecalsPool.create(weapon_result.position, weapon_result.normal)

		var health_component = hit_object.get_node_or_null("health_component")

		if health_component:
			health_component.damage(dmg)

	await get_tree().create_timer(rate).timeout
	can_shoot = true
