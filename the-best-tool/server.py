import json
import os
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from threading import Timer

class UnifiedGodotServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            try:
                with open('index.html', 'r', encoding='utf-8') as f:
                    self.wfile.write(f.read().encode('utf-8'))
            except FileNotFoundError:
                self.wfile.write(b"<h1>Error: index.html not found</h1>")
        else:
            self.send_response(404)
            self.end_headers()
                                                                                    
    def do_POST(self):
        if self.path == '/compile-item':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            data = json.loads(post_data)
                                                                
            item_id = data.get('id', 'unknown')
            item_name = data.get('name', 'Без названия')
            damage = data.get('damage', 0)
                                    
            tres_template = f'''[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]
            
[ext_resource type="Script" path="res://scripts/item_data.gd" id="1_item_script"]

[resource]
script = ExtResource("1_item_script")
item_id = "{item_id}"
item_name = "{item_name}"
damage = {damage}
'''
            output_dir = "./game/generated_resources"
            os.makedirs(output_dir, exist_ok=True)
            file_path = os.path.join(output_dir, f"item_{item_id}.tres")
                                    
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(tres_template)
                                    
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
                                                
            response = {"status": "success", "message": f"Создан item_{item_id}.tres"}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def open_browser(url):
    """Функция для открытия браузера."""
    webbrowser.open(url)
                                                                
def run(port=8000):
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, UnifiedGodotServer)
    url = f"http://127.0.0.1:{port}"
    
    print(f"Сервер запущен. Открываем браузер: {url}")
    
    # Запускаем таймер на 0.5 секунд, который откроет браузер в параллельном потоке.
    # Это гарантирует, что сервер успеет инициализироваться и принять запрос.
    Timer(0.5, open_browser, [url]).start()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nСервер остановлен.")
                                                            
if __name__ == '__main__':
    run()
