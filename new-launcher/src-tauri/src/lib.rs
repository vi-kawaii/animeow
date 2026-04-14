#[tauri::command]
fn close_window(window: tauri::Window) {
    window.close().unwrap()
}

#[tauri::command]
fn show_window(window: tauri::Window) {
    window.show().unwrap()
}

#[tauri::command]
fn hide_window(window: tauri::Window) {
    window.minimize().unwrap()
}

#[tauri::command]
fn run_game(window: tauri::Window) {
    println!("running some game");
    close_window(window)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![show_window, close_window, hide_window, run_game])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
