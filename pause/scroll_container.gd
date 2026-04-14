extends ScrollContainer

# Allows you to scroll a scroll container by dragging.
# Includes momentum and "rubber banding" effect.

var swiping = false
var swipe_start = Vector2()
var swipe_mouse_start = Vector2()
var swipe_mouse_times = []
var swipe_mouse_positions = []
var flick_momentum_multiplier = 15.0 # Adjust for desired flick strength
var flick_cutoff_time = 100 # milliseconds to consider for flick calculation
var rubber_band_amount = 0.3  # How much the scroll stretches beyond bounds (0.0 - 1.0)
var rubber_band_return_speed = 5.0  # Speed at which the scroll returns to bounds

var target_scroll_v = 0.0  # Target vertical scroll position (used for tweening)

@onready var buttons_container = get_node("GridContainer")

func _ready():
	target_scroll_v = scroll_vertical #initialize target scroll with current scroll

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			start_swipe(ev.position)
		else:
			end_swipe(ev.position)
	elif swiping and ev is InputEventMouseMotion:
		update_swipe(ev.position)

func _process(delta):
	# Smoothly return to bounds if overscrolled
	if not swiping:
		if scroll_vertical < 0:
			target_scroll_v = max(0, target_scroll_v - rubber_band_return_speed * delta)
		else:
			var content_height = get_content_height()
			var scrollable_height = get_scrollable_height()
			if scroll_vertical > content_height - scrollable_height and content_height > scrollable_height:
				target_scroll_v = min(content_height - scrollable_height, target_scroll_v + rubber_band_return_speed * delta)
		scroll_vertical = lerp(float(scroll_vertical), float(target_scroll_v), 0.2) #smoothing

func start_swipe(mouse_position):
	swiping = true
	swipe_start = Vector2(get_h_scroll(), get_v_scroll())
	swipe_mouse_start = mouse_position
	swipe_mouse_times = [Time.get_ticks_msec()]
	swipe_mouse_positions = [swipe_mouse_start]

func update_swipe(mouse_position):
	var delta = mouse_position - swipe_mouse_start
	set_h_scroll(swipe_start.x - delta.x)

	# Apply rubber banding effect to vertical scroll
	var target_v_scroll = swipe_start.y - delta.y
	var content_height = get_content_height()
	var scrollable_height = get_scrollable_height()

	if target_v_scroll < 0:
		target_v_scroll *= pow(1.0 - rubber_band_amount, abs(target_v_scroll) / 100.0) #Progressively reduce effect
	elif content_height > scrollable_height and target_v_scroll > content_height - scrollable_height:
		var overscroll = target_v_scroll - (content_height - scrollable_height)
		target_v_scroll = content_height - scrollable_height + overscroll * pow(1.0 - rubber_band_amount, abs(overscroll) / 100.0)  #Progressively reduce effect
	set_v_scroll(target_v_scroll)
	target_scroll_v = target_v_scroll #Update target when swiping, for smooth transition when stop

	swipe_mouse_times.append(Time.get_ticks_msec())
	swipe_mouse_positions.append(mouse_position)

func end_swipe(mouse_position):
	swipe_mouse_times.append(Time.get_ticks_msec())
	swipe_mouse_positions.append(mouse_position)
	swiping = false
	apply_flick_momentum(mouse_position)

func apply_flick_momentum(end_position):
	var source = Vector2(get_h_scroll(), get_v_scroll())
	var idx = get_flick_start_index()
	var flick_start = swipe_mouse_positions[idx]
	var flick_dur = float(swipe_mouse_times.size() - 1 - idx) / Engine.get_frames_per_second()
	var delta = end_position - flick_start
	var target = source - delta * flick_dur * flick_momentum_multiplier

	# Apply boundary limits AFTER momentum, before tween
	var content_height = get_content_height()
	var scrollable_height = get_scrollable_height()

	if content_height > scrollable_height:
		target.y = clamp(target.y, 0, content_height - scrollable_height) #normal limits
	else:
		target.y = clamp(target.y, 0, 0) #no scrolling if not big enough
	create_flick_tween(target.y, flick_dur)
	target_scroll_v = target.y #For smooth return

func get_flick_start_index():
	var now = Time.get_ticks_msec()
	var cutoff = now - flick_cutoff_time
	for i in range(swipe_mouse_times.size() - 1, -1, -1):
		if swipe_mouse_times[i] >= cutoff:
			return i
	return 0

func get_content_height():
	if get_child_count() > 0:
		return get_child(0).size.y
	else:
		printerr("Error: No VBoxContainer found as a direct child.  Adjust get_content_height() accordingly.")
		return 0

func get_scrollable_height():
	return size.y

func create_flick_tween(target_y, flick_dur):
	var tween = create_tween()
	tween.tween_property(self, "scroll_vertical", target_y, flick_dur).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
