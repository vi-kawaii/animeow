extends Node3D

var default_size = 10
var bullet_decal_template = preload("res://bullet_decal_template.tscn")
var array = []
var i = 0

func _ready():
	for _i in range(default_size):
		var b = bullet_decal_template.instantiate()
		array.append(b)
		add_child(b)
		b.teleport_to_abyss() # Пул инициализирует «склад» в бездне

func create(pos, normal):
	if normal.is_zero_approx(): return

	# 1. Менеджмент: выбираем объект
	var b = array[i % array.size()]
	i += 1

	# 2. Позиционирование: пул ставит объект в мир (ведь только пул знает pos и normal)
	b.global_position = pos
	var forward_vector = Vector3.UP if abs(normal.z) > 0.9 else Vector3.FORWARD
	b.global_transform = b.global_transform.looking_at(pos + forward_vector, normal)

	# 3. Активация: приказ действовать
	b.impact()
