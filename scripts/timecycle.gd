extends Node

var HOURS_IN_DAY = 24.0
var DAYS_IN_YEAR = 365

var day_time = 12
var day_of_year = 1

var latitude = 0

var planet_axial_tilt = 23.44
var moon_orbital_inclination = 5.14
var moon_orbital_period = 29.5

var clouds_cutoff = 0.3
var clouds_weight = 0.0

var use_day_time_for_shader = false

var time_scale = 0.01 * 2

var minute_passed = 0
var hour_passed = 0

func _ready():
	var sun = get_node("sun")
	var moon = get_node("moon")
	sun.set_global_position(Vector3(0.0, 0.0, 0.0))
	sun.set_global_rotation(Vector3(0.0, 0.0, 0.0))
	sun.set_rotation_order(EulerOrder.EULER_ORDER_ZXY)
	moon.set_global_position(Vector3(0.0, 0.0, 0.0))
	moon.set_global_rotation(Vector3(0.0, 0.0, 0.0))
	moon.set_rotation_order(EulerOrder.EULER_ORDER_ZXY)
	_update()

	GlobalTime.hours = day_time

func _process(delta):
	if day_time < 0.0:
		day_time += HOURS_IN_DAY
		day_of_year -= 1
	elif day_time > HOURS_IN_DAY:
		day_time -= HOURS_IN_DAY
		day_of_year += 1

	day_time += delta * time_scale
	minute_passed += delta * time_scale
	hour_passed += delta * time_scale

	if minute_passed >= 1. / 60:
		minute_passed = 0
		GlobalTime.minutes += 1
		GlobalTime.trigger_update()
		if GlobalTime.minutes == 60:
			GlobalTime.minutes = 0
	if hour_passed >= 1:
		hour_passed = 0
		GlobalTime.hours += 1
		if GlobalTime.hours == 24:
			GlobalTime.hours = 0
	_update()

func _update():
	_update_sun()
	_update_moon()
	_update_clouds()
	_update_shader()

func _update_sun():
	var sun = get_node("sun")

	var day_progress = day_time / HOURS_IN_DAY
	var earth_orbit_progress = day_of_year + 193.0 + day_progress / DAYS_IN_YEAR
	sun.set_rotation(Vector3(
		(day_progress * 2.0 - 0.5) * -PI,
		deg_to_rad(cos(earth_orbit_progress * PI * 2.0) * planet_axial_tilt),
		deg_to_rad(latitude)
	))
	var sun_direction = sun.to_global(Vector3(0.0, 0.0, 1.0)).normalized()
	sun.set_param(Light3D.Param.PARAM_ENERGY, smoothstep(-0.05, 0.1, sun_direction.y) * 1)

func _update_moon():
	var moon = get_node("moon")

	var day_progress = day_time / HOURS_IN_DAY
	var moon_orbit_progress = (fmod(float(day_of_year), moon_orbital_period) + day_progress) / moon_orbital_period
	var axial_tilt = moon_orbital_inclination
	axial_tilt += planet_axial_tilt * sin((day_progress * 2.0 - 1.0) * PI)
	moon.set_rotation(Vector3(
		((day_progress - moon_orbit_progress) * 2.0 - 1.0) * PI,
		deg_to_rad(axial_tilt),
		deg_to_rad(latitude)
	))
	var moon_direction = moon.to_global(Vector3(0.0, 0.0, 1.0)).normalized()
	moon.set_param(Light3D.Param.PARAM_ENERGY, smoothstep(-0.05, 0.1, moon_direction.y) * 0.1)

func _update_clouds():
	var env = get_node("environment")

	env.get_environment().get_sky().get_material().set_shader_parameter("clouds_cutoff", clouds_cutoff)
	env.get_environment().get_sky().get_material().set_shader_parameter("clouds_weight", clouds_weight)

func _update_shader():
	var env = get_node("environment")

	var overwritten_time = 0
	if use_day_time_for_shader:
		overwritten_time = (day_of_year * HOURS_IN_DAY + day_time) * 100.0

	env.get_environment().get_sky().get_material().set_shader_parameter("overwritten_time", overwritten_time)
