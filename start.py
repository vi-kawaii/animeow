import os
import shutil
import subprocess

working_dir = r"D:/Games/GodotGame/godot-cpp/demo"
godot_exe = r"D:/Games/GodotEngine/Godot_v4.5-beta2_win64.exe"
args = ['--scene', r'res://editor/other/main.tscn', '--', '--game-editor']

os.chdir(working_dir)

shutil.move(r"project.godot", r"old.project.godot")
shutil.move(r"custom-project/project.godot", r"project.godot")

# Run hidden (no console) and wait
startupinfo = None
if os.name == 'nt':
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

subprocess.run([godot_exe] + args, startupinfo=startupinfo)

shutil.move(r"project.godot", r"custom-project/project.godot")
shutil.move(r"old.project.godot", r"project.godot")