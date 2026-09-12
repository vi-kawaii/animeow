extends CanvasLayer

var tracks
var playback_position = 0.

func _ready():
	%play_button.connect("pressed", func():
		if %music_player.playing:
			playback_position = %music_player.get_playback_position()
			%music_player.stop()
		else:
			%music_player.play(playback_position)
	)

	%prev_button.connect("pressed", func():
		pass
	)

	%next_button.connect("pressed", func():
		pass
	)

	load_tracks()

func load_tracks():
	var all_files = ResourceLoader.list_directory("res://")
	var music_files = []

	# Фильтруем файлы по расширению .wav (или .mp3 / .ogg)
	for file in all_files:
		if file.ends_with(".wav") or file.ends_with(".wav.remap"):
			music_files.append(file.get_basename() + "." + file.get_extension()) # Получаем имя без .remap в экспортированной сборке

	if music_files.size() > 0:
		var track_path = "res://%s" % music_files[0]
		%music_player.stream = AudioStreamWAV.load_from_file(track_path)
		%music_buttons_container.visible = true
	else:
		print("Музыкальные файлы не найдены в корневой папке res://")
