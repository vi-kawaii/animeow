extends Node

var update_ui_callback = func(): pass

var is_bot: bool = false

var max_clip: int = 30          # Размер обоймы
var current_clip: int = 30      # Патроны в обойме
var total_ammo: int = 90        # Всего патронов в запасе
var reload_timer: Timer         # Наш таймер перезарядки
var reload_time: float = 2.0    # Длительность перезарядки обоймы

var max_spread: float = 0.08
var spread_per_shot: float = 0.01
var spread_recovery: float = 0.06

var recoil_up: float = 0.05
var recoil_side: float = 0.02
var recoil_snap: float = 10.0

# Настройки увода ствола вверх при зажиме (Progressive Recoil)
var progressive_recoil_up: float = 0.04 # На сколько уводит цель выше с каждым выстрелом
var progressive_recovery: float = 5.0     # Скорость возврата увода назад

var current_spread: float = 0.0
var bot_virtual_recoil: float = 0.0

# Переменная-мост: сюда мы пишем мгновенный толчок (вспышку) + постоянный увод
var recoil_vector: Vector3 = Vector3.ZERO
var progressive_recoil_offset: float = 0.0 # Накопленный увод для игрока

var rate = .07
var ray_length = 1000
var dmg = 50

var hit_mask = 5

var shoot_from
var effects_component

var can_shoot = true

func _ready():
	shoot_from = $"../shoot_from"
	effects_component = $"../effects_component"

	reload_timer = Timer.new()
	add_child(reload_timer)
	reload_timer.wait_time = reload_time
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timeout)

func _process(delta):
	# Восстановление разброса
	current_spread = max(current_spread - spread_recovery * delta, 0.0)

	# Восстановление увода при зажиме
	if is_bot:
		bot_virtual_recoil = max(bot_virtual_recoil - (progressive_recovery * delta * 0.5), 0.0)
	else:
		progressive_recoil_offset = max(progressive_recoil_offset - progressive_recovery * delta, 0.0)

func register_update_ui_callback(f):
	update_ui_callback = f
	f.call(current_clip, total_ammo)

func fire():
	# Стреляем, только если пушка готова И в обойме есть патроны
	if can_shoot and current_clip > 0:
		can_shoot = false
		current_clip -= 1
		_fire()
		_update_ui_callback(current_clip, max_clip)

		# Если это был последний патрон, автоматически уходим на перезарядку
		if current_clip == 0:
			_reload()
		else:
			# Обычный темп стрельбы между выстрелами через await, как у вас и было
			await get_tree().create_timer(rate).timeout
			can_shoot = true

func _update_ui_callback(cur, tot):
	update_ui_callback.call(cur, tot)

func _reload():
	# Перезаряжаемся, если обойма не полная, есть патроны в запасе и мы еще не перезаряжаемся
	if current_clip < max_clip and total_ammo > 0 and reload_timer.is_stopped():
		can_shoot = false # Блокируем стрельбу на время перезарядки
		reload_timer.start()
		print("Перезарядка обоймы началась...")

func _on_reload_timeout():
	var needed_ammo = max_clip - current_clip
	var transfer = min(needed_ammo, total_ammo)

	current_clip += transfer
	total_ammo -= transfer
	can_shoot = true # Снова разрешаем стрелять
	print("Перезарядка окончена. Патронов: ", current_clip, "/", total_ammo)

	_update_ui_callback(current_clip, total_ammo)

func _effects():
	effects_component.fire()

func _recoil():
	if is_bot:
		# Бот копит виртуальный увод вверх
		bot_virtual_recoil += (recoil_up + progressive_recoil_up)
	else:
		# Игрок получает мгновенный толчок вбок
		var side = randf_range(-recoil_side, recoil_side)
		recoil_vector += Vector3(side, recoil_up, 0.0)

		# И игрок НАКАПЛИВАЕТ постоянный увод вверх при зажиме
		progressive_recoil_offset += progressive_recoil_up

func _spread():
	current_spread = min(current_spread + spread_per_shot, max_spread)

# Хелпер для получения случайного смещения разброса
func _get_spread_offset() -> Vector3:
	return Vector3(
		randf_range(-current_spread, current_spread),
		randf_range(-current_spread, current_spread),
		0.0
	)

func _fire():
	_effects()
	_recoil()
	_spread()

	var space_state = shoot_from.get_world_3d().direct_space_state
	var camera = Player.camera
	var target_point: Vector3

	# Получаем случайный сдвиг разброса для текущего выстрела
	var spread_offset = _get_spread_offset()

	# ЛОГИКА ДЛЯ ИГРОКА (ЧЕРЕЗ КАМЕРУ)
	if camera and shoot_from.get_parent().get_parent().is_in_group("player"):
		var screen_center = get_viewport().size / 2
		var cam_ray_start = camera.project_ray_origin(screen_center)

		# Базовое направление из центра экрана
		var base_normal = camera.project_ray_normal(screen_center)

		# Накладываем разброс на вектор направления камеры
		var spread_rotation = Basis.from_euler(Vector3(spread_offset.y, spread_offset.x, 0.0))
		var final_normal = (camera.global_transform.basis * spread_rotation * camera.global_transform.basis.inverse()) * base_normal

		var cam_ray_end = cam_ray_start + final_normal * ray_length

		var cam_query = PhysicsRayQueryParameters3D.create(cam_ray_start, cam_ray_end)
		cam_query.collision_mask = hit_mask
		cam_query.exclude = [shoot_from.get_parent().get_rid()]

		var cam_result = space_state.intersect_ray(cam_query)
		target_point = cam_result.position if cam_result else cam_ray_end

	# ЛОГИКА ДЛЯ ВРАГА (ПРЯМОЙ ВЫСТРЕЛ ИЗ СТВОЛА)
	else:
		# Базовое направление ствола бота
		#var forward_vector = -shoot_from.global_transform.basis.z

		# Добавляем боту разброс И его виртуальный увод отдачи вверх
		var bot_offset = spread_offset
		bot_offset.y += bot_virtual_recoil

		var spread_rotation = Basis.from_euler(Vector3(bot_offset.y, bot_offset.x, 0.0))
		var final_forward = (shoot_from.global_transform.basis * spread_rotation).z * -1

		target_point = shoot_from.global_position + (final_forward * ray_length)

	# ОСНОВНОЙ ВЫСТРЕЛ ИЗ ОРУЖИЯ (Одинаковый для всех)
	var weapon_query = PhysicsRayQueryParameters3D.create(shoot_from.global_position, target_point)
	weapon_query.collision_mask = hit_mask
	weapon_query.exclude = [shoot_from.get_parent().get_rid()]

	var weapon_result = space_state.intersect_ray(weapon_query)

	if weapon_result:
		var hit_object = weapon_result.collider
		print(shoot_from.get_parent().get_parent().name, " попал в ", hit_object.name)

		if has_node("/root/BulletDecalsPool"): # Безопасная проверка синглтона
			BulletDecalsPool.create(weapon_result.position, weapon_result.normal)

		var health_component = hit_object.get_node_or_null("health_component")
		if health_component:
			health_component.damage(dmg)

	#await get_tree().create_timer(rate).timeout
	#can_shoot = true
