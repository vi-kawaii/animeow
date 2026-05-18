import fs from "fs";
import path from "path";
import { spawn } from "bun";

// CONFIG / script commands (one place)
const base = "D:/Games/GodotGame/godot-cpp/demo".replace(/\//g, "\\");
const binary = "D:/Games/GodotEngine/Godot_v4.5-beta2_win64.exe".replace(/\//g, "\\");
const scene = "res://editor/other/main.tscn";

const project = "project.godot";
const customDir = "custom-project";
const oldProject = `old.${project}`;

// Build script as array of logical steps (commands only, no execution)
const scriptCommands = [
  `cd "${base}"`,
  `move "${project}" "${oldProject}"`,
  `move "${path.join(customDir, project)}" "${project}"`,
  `"${binary}" --scene "${scene}" -- --game-editor`,
  `move "${project}" "${path.join(customDir, project)}"`,
  `move "${oldProject}" "${project}"`,
];

// Execution (separate place)
process.chdir(base);

// 1) backup
fs.renameSync(path.join(base, project), path.join(base, oldProject));

// 2) put custom project in place
fs.renameSync(path.join(base, customDir, project), path.join(base, project));

// 3) launch Godot detached (no console) and don't wait
const godot = spawn({
  cmd: [binary, "--scene", scene, "--", "--game-editor"],
  cwd: base,
  detached: true,
  stdio: ["ignore", "ignore", "ignore"],
});
godot.unref?.();

// 4) restore immediately
fs.renameSync(path.join(base, project), path.join(base, customDir, project));
fs.renameSync(path.join(base, oldProject), path.join(base, project));

// optional: print script commands for visibility
console.log("SCRIPT COMMANDS:");
scriptCommands.forEach((c) => console.log(c));
console.log("Executed.");