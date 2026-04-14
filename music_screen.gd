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
	tracks = ResourceLoader.list_directory("res://music")
	%music_player.stream = AudioStreamWAV.load_from_file("res://music/%s" % tracks[0])
	%music_buttons_container.visible = true
