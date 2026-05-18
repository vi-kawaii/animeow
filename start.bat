cd D:\Games\GodotGame\godot-cpp\demo

move project.godot old.project.godot
move custom-project\project.godot project.godot

D:\Games\GodotEngine\Godot_v4.5-beta2_win64.exe --scene "res://editor/other/main.tscn" -- --game-editor

move project.godot custom-project\project.godot
move old.project.godot project.godot