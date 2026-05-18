import { $ } from "bun"

const base = "D:/Games/GodotGame/godot-cpp/demo"
const binary = "D:/Games/GodotEngine/Godot_v4.5-beta2_win64.exe"
const scene = "res://editor/other/main.tscn"

const project = "project.godot"
const custom_project = "custom-project/"

const script = `

cd ${base}

mv ${project} old.${project}
mv ${custom_project}${project} ${project}

${binary} --scene ${scene} -- --game-editor

mv ${project} ${custom_project}${project}
mv old.${project} ${project}

`

script.split("\n").filter(x => x !== "").map(async x => await $`${x}`)