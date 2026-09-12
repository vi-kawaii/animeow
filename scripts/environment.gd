extends WorldEnvironment


@onready var sun_and_moon = get_parent().get_node("SunContainer")
var timer = false
var hours = 12
var minutes = -1
var day_number = 1


func _process(_delta: float) -> void:
	if timer:
		return

	timer = true
	spin_sun_and_moon()
	update_time()
	await get_tree().create_timer(0.005).timeout
	timer = false


func spin_sun_and_moon():
	sun_and_moon.rotate_x(2 * PI / (24 * 60))

	#sun_and_moon.get_node("Sun").set_visible(hours >= 6 and hours <= 21 - 3)
	#sun_and_moon.get_node("Moon").set_visible(hours > 21 - 6 or hours < 6)


func update_time():
	minutes += 1

	if minutes == 60:
		minutes = 0
		hours += 1

	if hours == 24:
		hours = 0
		day_number += 1

	if day_number == 8:
		day_number = 1

func time():
	var m = str(minutes)
	if minutes < 10:
		m = "0" + m

	return str(hours) + ":" + m


func day():
	match day_number:
		1:
			return "Monday"
		2:
			return "Tuesday"
		3:
			return "Wednesday"
		4:
			return "Thursday"
		5:
			return "Friday"
		6:
			return "Saturday"
		7:
			return "Sunday"
