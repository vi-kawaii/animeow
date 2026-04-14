extends CanvasLayer

var camera
var player

var is_selector_mode = false
var is_ignoring_input = false

var melee = []
var gun = ""

func _ready():
	camera = get_node("../camera")
	player = get_parent()

	is_selector_mode = false
	is_ignoring_input = false

	melee.append("")
	melee.append("katana")
	gun = ""

	for i in range(5):
		get_node("GridContainer/Button" + str(i)).connect("pressed", func(): gun_button_pressed(i))

	set_visible(false)

func gun_button_pressed(idx):
	match idx:
		0:
			gun = "Pistol"
		1:
			gun = "Nothing"
		2:
			gun = "Rifle"
		3:
			gun = "Uzi"
		4:
			gun = "Katana"

	player.call("set_gun", gun)
	set_visible(false)
	is_selector_mode = false

func _process(_delta):
	if is_ignoring_input:
		return

	if Input.is_action_just_pressed("gun_selector"):
		camera.mouse_follow(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		set_visible(true)
		is_selector_mode = true

	if Input.is_action_just_released("gun_selector"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		camera.mouse_follow(true)

		set_visible(false)
		is_selector_mode = false

func is_melee_selected():
	return melee.has(gun)

func is_gun_selected():
	return !melee.has(gun)
