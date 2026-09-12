extends Node

@export var shoot_sound: AudioStream

var effect_from
var effect_audio

func _ready():
	effect_from = $"../effect_from"
	effect_audio = $"../effect_audio"

	effect_audio.stream = shoot_sound

func fire():
	_sound()
	_visual()

func _sound():
	effect_audio.play()

func _visual():
	effect_from.restart()
	effect_from.emitting = true
