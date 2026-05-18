Option Explicit

Dim fso, shell
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

Dim workingDir, godotExe, args

workingDir = "D:\Games\GodotGame\godot-cpp\demo"
godotExe = "D:\Games\GodotEngine\Godot_v4.5-beta2_win64.exe"
args = "--scene ""res://editor/other/main.tscn"" -- --game-editor"

Sub MoveFile(srcPath, destPath)
fso.MoveFile srcPath, destPath
End Sub

shell.CurrentDirectory = workingDir

MoveFile workingDir & "\project.godot", workingDir & "\old.project.godot"
MoveFile workingDir & "\custom-project\project.godot", workingDir & "\project.godot"

' 0 = hidden window, True = wait for exit
shell.Run """" & godotExe & """ " & args, 0, True

MoveFile workingDir & "\project.godot", workingDir & "\custom-project\project.godot"
MoveFile workingDir & "\old.project.godot", workingDir & "\project.godot"

WScript.Quit 0