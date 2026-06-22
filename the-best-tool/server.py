import json
import os
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from threading import Timer

GRAPH_SAVE_FILE = "project_graph.json"

class GodotPersistentCompilerServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            
            # Читаем сохраненный граф, если он есть
            saved_graph_data = "null"
            if os.path.exists(GRAPH_SAVE_FILE):
                try:
                    with open(GRAPH_SAVE_FILE, "r", encoding="utf-8") as sf:
                        saved_graph_data = sf.read()
                except Exception:
                    pass

            try:
                with open('index.html', 'r', encoding='utf-8') as f:
                    html_content = f.read()
                    
                # Внедряем сохраненные данные прямо в тело скрипта веб-страницы перед отправкой
                injected_html = html_content.replace("let initialSavedGraph = null;", f"let initialSavedGraph = {saved_graph_data};")
                self.wfile.write(injected_html.encode('utf-8'))
            except FileNotFoundError:
                self.wfile.write(b"<h1>Error: index.html not found</h1>")
        else:
            self.send_response(404)
            self.end_headers()
                                                                                    
    def do_POST(self):
        if self.path == '/compile-graph':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            data = json.loads(post_data)

            # 1. Сохраняем резервную рабочую копию графа для самого редактора
            try:
                with open(GRAPH_SAVE_FILE, "w", encoding="utf-8") as sf:
                    json.dump(data, sf, ensure_ascii=False, indent=4)
            except Exception as e:
                print(f"Не удалось сохранить рабочую копию графа: {e}")

            nodes = data.get('nodes', [])
            connections = data.get('connections', [])
            
            output_dir = "./game/dialogues"
            os.makedirs(output_dir, exist_ok=True)

            # Строим карту связей
            graph_map = {}
            for conn in connections:
                from_id = conn['fromId']
                to_id = conn['toId']
                if from_id not in graph_map:
                    graph_map[from_id] = []
                graph_map[from_id].append(to_id)

            # Удаляем старые ноды из папки Godot, чтобы не плодить мусор при переименованиях ID
            if os.path.exists(output_dir):
                for f in os.listdir(output_dir):
                    if f.startswith("node_") and f.endswith(".tres"):
                        try: os.remove(os.path.join(output_dir, f))
                        except Exception: pass

            # 2. Генерируем новые .tres файлы для Godot
            for node in nodes:
                nid = node['id']
                ntype = node['type']
                nlabel = node['label']
                nspeaker = node['speaker']
                ntext = node['text'].replace('\n', '\\n').replace('"', '\"')
                
                next_nodes = graph_map.get(nid, [])
                godot_array_string = ", ".join([f'"{x}"' for x in next_nodes])

                tres_content = f'''[gd_resource type="Resource" script_class="DialogueNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/dialogue_node.gd" id="1_graph_script"]

[resource]
script = ExtResource("1_graph_script")
node_id = "{nid}"
node_type = "{ntype}"
node_label = "{nlabel}"
speaker_name = "{nspeaker}"
dialogue_text = "{ntext}"
next_nodes = PackedStringArray([{godot_array_string}])
'''
                file_path = os.path.join(output_dir, f"node_{nid}.tres")
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(tres_content)

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {"status": "success", "count": len(nodes)}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def open_browser(url):
    webbrowser.open(url)
                                                                
def run(port=8000):
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, GodotPersistentCompilerServer)
    url = f"http://127.0.0.1:{port}"
    print(f"Сервер с памятью запущен: {url}")
    Timer(0.5, open_browser, [url]).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nСервер остановлен.")
                                                            
if __name__ == '__main__':
    run()
