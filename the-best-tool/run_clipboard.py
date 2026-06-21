import os
import sys

def get_clipboard_text():
    """Безопасное получение текста через встроенный во все версии Python tkinter."""
    try:
        import tkinter as tk
        root = tk.Tk()
        root.withdraw()  # Скрываем графическое окно
        text = root.clipboard_get()
        root.destroy()   # Закрываем системный процесс окна
        return str(text)
    except Exception as e:
        print(f"Предупреждение: Не удалось прочитать буфер: {e}")
        return ""

def wait_for_keypress():
    """Гарантированная остановка консоли."""
    print("\n" + "=" * 40)
    print("Нажмите ЛЮБУЮ клавишу для выхода...")
    try:
        sys.stdin.flush()
    except Exception:
        pass

    if os.name == 'nt':
        import msvcrt
        msvcrt.getch()
    else:
        import tty, termios
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def main():
    # Флаг PYTHONUNBUFFERED сбрасывает текст в консоль мгновенно
    sys.stdout.reconfigure(line_buffering=True) if sys.version_info >= (3, 7) else None
    
    print("Инициализация...")
    print("Чтение кода из буфера обмена...")
    
    code = get_clipboard_text().strip()
    
    if not code:
        print("Ошибка: Буфер обмена пуст или содержит не текст.")
        wait_for_keypress()
        return

    print("-" * 40)
    print("ВЫПОЛНЯЕМЫЙ КОД:")
    print("-" * 40)
    print(code)
    print("-" * 40)
    print("ЗАПУСК...\n")

    try:
        exec(code, globals())
        print("\n" + "-" * 40)
        print("Код успешно выполнен.")
    except Exception as e:
        import traceback
        print("\n" + "-" * 40)
        print("ОШИБКА В КОДЕ:")
        traceback.print_exc()
    
    wait_for_keypress()

if __name__ == "__main__":
    main()
