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

func create(pos, normal):
	print("spawned decal somewhere", pos, normal)

	# 1. Получаем текущую декаль по кругу с помощью модуля %
	var b = array[i % array.size()]

	# 2. Увеличиваем счетчик для следующего вызова
	i += 1

	b.global_position = pos

	# Проверяем на нулевую нормаль (если рейкаст улетел в небо)
	if normal.is_zero_approx():
		return

	# Направляем ось Y (UP) декали по нормали стены
	# Взгляд (FORWARD) направляем в любую другую сторону, например Vector3.FORWARD
	# Если нормаль совпадает с FORWARD, используем UP
	var forward_vector = Vector3.UP if abs(normal.z) > 0.9 else Vector3.FORWARD

	b.global_transform = b.global_transform.looking_at(pos + forward_vector, normal)

	b.impact()
