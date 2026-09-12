extends CanvasLayer

func _ready():
	%contacts.connect("pressed", func():
		print("contacts opened")
	)

	%quests.connect("pressed", func():
		%main_screen.set_visible(false)
		%quests_screen.set_visible(true)
		%quests_screen.activate()
	)

	%map.connect("pressed", func():
		%main_screen.set_visible(false)
		%map_screen.set_visible(true)
		%map_screen.activate()
	)

	%music.connect("pressed", func():
		%main_screen.set_visible(false)
		%music_screen.set_visible(true)
	)
