extends CanvasLayer

@onready var panel: Control = %QuestPanel
@onready var title_label: Label = %QuestTitle
@onready var objective_label: Label = %QuestObjective
@onready var complete_root: Control = %CompleteRoot
@onready var complete_banner: Control = %CompleteBanner
@onready var complete_header: Label = %CompleteHeader
@onready var complete_title: Label = %CompleteTitle
@onready var flash: ColorRect = %Flash
@onready var sfx: AudioStreamPlayer = %CompleteSfx

var _complete_tween: Tween


func _ready() -> void:
	hide_tracker()
	_reset_complete_overlay()


func hide_tracker() -> void:
	panel.visible = false
	panel.modulate = Color.WHITE
	panel.scale = Vector2.ONE


func show_quest(title: String, objective: String) -> void:
	_kill_complete_tween()
	_reset_complete_overlay()
	title_label.text = title
	objective_label.text = "• " + objective
	objective_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92, 1))
	panel.modulate = Color.WHITE
	panel.scale = Vector2.ONE
	panel.visible = true


func show_completed(title: String) -> void:
	_kill_complete_tween()

	title_label.text = title
	objective_label.text = "✓ Выполнено"
	objective_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55, 1))
	panel.visible = true
	panel.modulate = Color.WHITE
	panel.scale = Vector2.ONE
	panel.pivot_offset = Vector2(148, 38)

	complete_title.text = title
	complete_root.visible = true
	complete_root.modulate = Color.WHITE
	complete_banner.modulate = Color(1, 1, 1, 0)
	complete_banner.scale = Vector2(0.86, 0.86)
	complete_banner.pivot_offset = Vector2(180, 47)
	flash.modulate = Color(1, 0.9, 0.4, 0)

	_play_complete_sfx()

	_complete_tween = create_tween()
	_complete_tween.set_parallel(true)

	# Screen flash
	_complete_tween.tween_property(flash, "modulate:a", 0.28, 0.08)
	_complete_tween.tween_property(flash, "modulate:a", 0.0, 0.35).set_delay(0.08)

	# Tracker punch + gold blink
	_complete_tween.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_complete_tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_delay(0.12).set_trans(Tween.TRANS_SINE)
	_complete_tween.tween_property(panel, "modulate", Color(1.35, 1.2, 0.55, 1), 0.1)
	_complete_tween.tween_property(panel, "modulate", Color.WHITE, 0.35).set_delay(0.15)

	# Center banner
	_complete_tween.tween_property(complete_banner, "modulate:a", 1.0, 0.2).set_delay(0.05)
	_complete_tween.tween_property(complete_banner, "scale", Vector2.ONE, 0.35).set_delay(0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_complete_tween.set_parallel(false)
	_complete_tween.tween_interval(2.2)
	_complete_tween.set_parallel(true)
	_complete_tween.tween_property(panel, "modulate:a", 0.0, 0.45)
	_complete_tween.tween_property(complete_root, "modulate:a", 0.0, 0.45)
	_complete_tween.set_parallel(false)
	_complete_tween.tween_callback(_on_complete_finished)


func _on_complete_finished() -> void:
	hide_tracker()
	_reset_complete_overlay()


func _reset_complete_overlay() -> void:
	complete_root.visible = false
	complete_root.modulate = Color.WHITE
	complete_banner.modulate = Color(1, 1, 1, 0)
	complete_banner.scale = Vector2.ONE
	flash.modulate = Color(1, 0.9, 0.4, 0)


func _kill_complete_tween() -> void:
	if _complete_tween and _complete_tween.is_valid():
		_complete_tween.kill()
	_complete_tween = null


func _play_complete_sfx() -> void:
	if sfx.stream == null:
		sfx.stream = _make_complete_chime()
	sfx.pitch_scale = 1.0
	sfx.volume_db = -6.0
	sfx.play()


func _make_complete_chime() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var mix_rate := 22050.0
	var duration := 0.55
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var freqs := [523.25, 659.25, 783.99] # C5 E5 G5
	for i in sample_count:
		var t := float(i) / mix_rate
		var env := 0.0
		if t < 0.04:
			env = t / 0.04
		else:
			env = exp(-(t - 0.04) * 4.5)

		var sample := 0.0
		for f in freqs:
			sample += sin(TAU * f * t) * 0.22
		# Soft octave sparkle
		sample += sin(TAU * 1046.5 * t) * 0.08 * env
		sample *= env

		var s := int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)

	stream.data = data
	return stream
