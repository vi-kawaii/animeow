@echo off
chcp 65001 > nul

:: Проверяем, есть ли тут git
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo Ошибка: это не git-репозиторий!
    pause
    exit /b
)

:: Добавляем все изменения
git add .

:: Запрашиваем сообщение коммита
set /p commit_message="Введите сообщение коммита: "

:: Проверяем на пустоту
if "%commit_message%"=="" (
    echo Ошибка: сообщение коммита не может быть пустым!
    pause
    exit /b
)

:: Коммитим
git commit -m "%commit_message%"

:: Получаем текущую ветку и пушим
for /f "tokens=*" %%i in ('git branch --show-current') do set branch=%%i
git push origin %branch%

echo Готово! Изменения отправлены в ветку %branch%.
pause
