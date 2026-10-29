@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Django Project Setup

REM ============================================
REM  Переход в папку скрипта (ключевой момент!)
REM ============================================
cd /d "%~dp0"
if errorlevel 1 (
    echo [ОШИБКА] Не удалось перейти в папку скрипта.
    pause
    exit /b 1
)

echo ============================================
echo   Установка Django-проекта
echo ============================================
echo Папка: %CD%
echo.

REM ============================================
REM  Проверка Python
REM ============================================
python --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Python не найден в PATH.
    echo Установи Python с https://python.org
    echo и поставь галочку "Add Python to PATH".
    pause
    exit /b 1
)
for /f "tokens=2" %%v in ('python --version') do set PYVER=%%v
echo [OK] Python !PYVER! найден.
echo.

REM ============================================
REM  Проверка: не сломан ли проект от прошлого запуска
REM ============================================
if exist "config\manage.py" (
    echo [ОШИБКА] Прошлый запуск создал вложенный проект: config\manage.py
    echo.
    echo Исправление:
    echo   1. Удали папку config полностью
    echo   2. Запусти setup.bat заново
    echo.
    pause
    exit /b 1
)
if exist "config\config\settings.py" (
    echo [ОШИБКА] Прошлый запуск создал вложенный проект: config\config\settings.py
    echo.
    echo Исправление:
    echo   1. Удали папку config полностью
    echo   2. Запусти setup.bat заново
    echo.
    pause
    exit /b 1
)

REM ============================================
REM  1. requirements.txt
REM ============================================
echo [1/8] requirements.txt...
if exist "requirements.txt" (
    echo [INFO] уже есть.
) else (
    (
        echo Django==5.0.6
        echo python-dotenv==1.0.1
        echo django-environ==0.11.2
    ) > requirements.txt
    if not exist "requirements.txt" (
        echo [ОШИБКА] Не удалось создать requirements.txt
        pause
        exit /b 1
    )
    echo [OK] создан.
)
echo.

REM ============================================
REM  2. venv
REM ============================================
if exist ".venv\Scripts\python.exe" (
    echo [INFO] .venv уже существует.
) else (
    echo [2/8] Создаю venv...
    python -m venv .venv
    if not exist ".venv\Scripts\python.exe" (
        echo [ОШИБКА] venv не создался.
        pause
        exit /b 1
    )
    echo [OK] venv создан.
)
echo.

REM ============================================
REM  3. Активация venv
REM ============================================
echo [3/8] Активирую venv...
call ".venv\Scripts\activate.bat"
REM Проверяем, что python теперь из venv
for /f "delims=" %%p in ('python -c "import sys;print(sys.prefix)"') do set VENV_PREFIX=%%p
echo !VENV_PREFIX! | findstr /i ".venv" >nul
if errorlevel 1 (
    echo [ОШИБКА] venv не активировался. Python: !VENV_PREFIX!
    pause
    exit /b 1
)
echo [OK] venv активен: !VENV_PREFIX!
echo.

REM ============================================
REM  4. Зависимости
REM ============================================
echo [4/8] Устанавливаю зависимости...
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ОШИБКА] pip install не сработал.
    pause
    exit /b 1
)
echo [OK] установлены.
echo.

REM ============================================
REM  5. Django-проект (ГЛАВНЫЙ ШАГ)
REM ============================================
echo [5/8] Создаю Django-проект...
if exist "manage.py" (
    echo [INFO] manage.py уже в корне, пропускаю.
) else (
    echo [INFO] Запуск: python -m django startproject config "%CD%"
    python -m django startproject config "%CD%"
    if errorlevel 1 (
        echo [ОШИБКА] startproject завершился с ошибкой.
        pause
        exit /b 1
    )

    REM --- Проверка 1: manage.py в корне ---
    if not exist "manage.py" (
        echo.
        echo [ОШИБКА] manage.py НЕ появился в корне.
        echo Содержимое папки:
        dir /b
        echo.
        echo Возможные причины:
        echo   - путь содержит пробелы/кириллицу и Django записал не туда
        echo   - проверь папку config: если там manage.py — это вложенный проект
        pause
        exit /b 1
    )

    REM --- Проверка 2: нет вложенного config\config ---
    if exist "config\config\settings.py" (
        echo.
        echo [ОШИБКА] Создался вложенный проект config\config\.
        echo Значит аргумент пути не сработал.
        echo.
        echo Что делать: удали папку config и запусти setup.bat заново
        echo в папке без пробелов и русских букв, например C:\dev\myproject
        pause
        exit /b 1
    )

    REM --- Проверка 3: settings.py на месте ---
    if not exist "config\settings.py" (
        echo [ОШИБКА] config\settings.py не найден.
        pause
        exit /b 1
    )

    echo [OK] Проект создан: manage.py в корне, config\settings.py на месте.
)
echo.

REM ============================================
REM  6. Приложение main
REM ============================================
echo [6/8] Создаю приложение main...
if exist "main\apps.py" (
    echo [INFO] main уже есть.
) else (
    python manage.py startapp main
    if not exist "main\apps.py" (
        echo [ОШИБКА] startapp main не сработал.
        pause
        exit /b 1
    )
    echo [OK] main создано.
)
echo.

REM ============================================
REM  7. Шаблоны, статика, views, urls
REM ============================================
echo [7/8] Создаю файлы main/...

if not exist "main\templates\main" mkdir "main\templates\main"
if not exist "main\static\main"    mkdir "main\static\main"

REM --- base.html ---
(
    echo {%% load static %%}
    echo ^<!DOCTYPE html^>
    echo ^<html lang="ru"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<title^>{%% block title %%}Мой проект{%% endblock %%}^</title^>
    echo     ^<link rel="stylesheet" href="{%% static 'main/style.css' %%}"^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<header class="site-header"^>
    echo         ^<div class="container"^>
    echo             ^<h1^>Мой Django-проект^</h1^>
    echo             ^<nav^>
    echo                 ^<a href="/"^>Главная^</a^>
    echo                 ^<a href="/admin/"^>Админка^</a^>
    echo             ^</nav^>
    echo         ^</div^>
    echo     ^</header^>
    echo     ^<main class="container"^>
    echo         {%% block content %%}{%% endblock %%}
    echo     ^</main^>
    echo     ^<footer class="site-footer"^>
    echo         ^<div class="container"^>Django Student Template^</div^>
    echo     ^</footer^>
    echo ^</body^>
    echo ^</html^>
) > "main\templates\main\base.html"

REM --- index.html ---
(
    echo {%% extends "main/base.html" %%}
    echo.
    echo {%% block title %%}Главная{%% endblock %%}
    echo.
    echo {%% block content %%}
    echo     ^<section class="card"^>
    echo         ^<h2^>Добро пожаловать!^</h2^>
    echo         ^<p^>Проект успешно создан и работает. Это стартовая страница приложения ^<code^>main^</code^>.^</p^>
    echo         ^<ul^>
    echo             ^<li^>Шаблоны: ^<code^>main/templates/main/^</code^>^</li^>
    echo             ^<li^>Стили: ^<code^>main/static/main/style.css^</code^>^</li^>
    echo             ^<li^>Маршруты: ^<code^>main/urls.py^</code^>^</li^>
    echo         ^</ul^>
    echo     ^</section^>
    echo {%% endblock %%}
) > "main\templates\main\index.html"

REM --- style.css ---
(
    echo * { box-sizing: border-box; margin: 0; padding: 0; }
    echo body { font-family: -apple-system, "Segoe UI", Roboto, Arial, sans-serif; background: #f5f6fa; color: #222; line-height: 1.6; }
    echo .container { max-width: 900px; margin: 0 auto; padding: 0 20px; }
    echo .site-header { background: #092e20; color: #fff; padding: 20px 0; }
    echo .site-header h1 { font-size: 22px; margin-bottom: 8px; }
    echo .site-header nav a { color: #9fd6b5; margin-right: 16px; text-decoration: none; }
    echo .site-header nav a:hover { color: #fff; }
    echo main.container { padding-top: 30px; padding-bottom: 30px; }
    echo .card { background: #fff; border-radius: 8px; padding: 24px; box-shadow: 0 1px 4px rgba^(0,0,0,0.06^); }
    echo .card h2 { margin-bottom: 12px; }
    echo .card p, .card ul { margin-bottom: 12px; }
    echo .card ul { padding-left: 20px; }
    echo code { background: #eef; padding: 1px 5px; border-radius: 3px; font-size: 90%%; }
    echo .site-footer { border-top: 1px solid #e1e4e8; padding: 16px 0; color: #666; font-size: 14px; margin-top: 40px; }
) > "main\static\main\style.css"

REM --- main/views.py ---
(
    echo from django.shortcuts import render
    echo.
    echo def index^(request^):
    echo     return render^(request, "main/index.html"^)
) > "main\views.py"

REM --- main/urls.py ---
(
    echo from django.urls import path
    echo from . import views
    echo.
    echo app_name = "main"
    echo.
    echo urlpatterns = [
    echo     path^("", views.index, name="index"^),
    echo ]
) > "main\urls.py"

REM --- Проверка, что файлы на месте ---
if not exist "main\templates\main\index.html" (
    echo [ОШИБКА] index.html не создался.
    pause
    exit /b 1
)
if not exist "main\static\main\style.css" (
    echo [ОШИБКА] style.css не создался.
    pause
    exit /b 1
)
if not exist "main\views.py" (
    echo [ОШИБКА] views.py не создался.
    pause
    exit /b 1
)
if not exist "main\urls.py" (
    echo [ОШИБКА] urls.py не создался.
    pause
    exit /b 1
)

echo [OK] Файлы main/ созданы и проверены.
echo.

REM ============================================
REM  8. Патчим settings.py и urls.py
REM ============================================
echo [8/8] Подключаю main в настройки...

REM --- INSTALLED_APPS ---
python -c "p='config/settings.py';s=open(p,encoding='utf-8').read();s=(s if chr(34)+'main'+chr(34) in s else s.replace(chr(34)+'django.contrib.staticfiles'+chr(34)+',',chr(34)+'django.contrib.staticfiles'+chr(34)+','+chr(10)+'    '+chr(34)+'main'+chr(34)+',',1));open(p,'w',encoding='utf-8').write(s)"
python -c "import sys;s=open('config/settings.py',encoding='utf-8').read();sys.exit(0 if chr(34)+'main'+chr(34) in s else 1)"
if errorlevel 1 (
    echo [ОШИБКА] Не удалось добавить 'main' в INSTALLED_APPS.
    echo Открой config\settings.py и добавь вручную после "django.contrib.staticfiles",:
    echo     "main",
    pause
    exit /b 1
)
echo [OK] 'main' в INSTALLED_APPS.

REM --- config/urls.py ---
python -c "p='config/urls.py';s=open(p,encoding='utf-8').read();s=(s if 'main.urls' in s else s.replace('from django.urls import path','from django.urls import path, include',1).replace('urlpatterns = [','urlpatterns = ['+chr(10)+'    path('+chr(34)+chr(34)+', include('+chr(34)+'main.urls'+chr(34)+')),',1));open(p,'w',encoding='utf-8').write(s)"
python -c "import sys;s=open('config/urls.py',encoding='utf-8').read();sys.exit(0 if 'main.urls' in s else 1)"
if errorlevel 1 (
    echo [ОШИБКА] Не удалось подключить main.urls.
    echo Открой config\urls.py и добавь:
    echo     from django.urls import include
    echo     path('', include('main.urls')),
    pause
    exit /b 1
)
echo [OK] main.urls подключён.
echo.

REM ============================================
REM  .env и миграции
REM ============================================
if exist ".env" (
    echo [INFO] .env уже есть.
) else (
    (
        echo DEBUG=True
        echo SECRET_KEY=dev-only-change-me-in-production
        echo ALLOWED_HOSTS=127.0.0.1,localhost
    ) > .env
    echo [OK] .env создан.
)

echo Применяю миграции...
python manage.py migrate --noinput
if errorlevel 1 (
    echo [ОШИБКА] Миграции не применились.
    pause
    exit /b 1
)
echo [OK] База готова.
echo.

REM ============================================
REM  Финальная проверка структуры
REM ============================================
echo Проверяю структуру проекта...
set STRUCT_OK=1

if not exist "manage.py"                  (echo   [НЕТ] manage.py в корне            & set STRUCT_OK=0)
if not exist "config\settings.py"         (echo   [НЕТ] config\settings.py           & set STRUCT_OK=0)
if not exist "main\apps.py"               (echo   [НЕТ] main\apps.py                 & set STRUCT_OK=0)
if not exist "main\views.py"              (echo   [НЕТ] main\views.py                & set STRUCT_OK=0)
if not exist "main\urls.py"               (echo   [НЕТ] main\urls.py                 & set STRUCT_OK=0)
if not exist "main\templates\main\base.html"  (echo   [НЕТ] main\templates\main\base.html  & set STRUCT_OK=0)
if not exist "main\templates\main\index.html" (echo   [НЕТ] main\templates\main\index.html & set STRUCT_OK=0)
if not exist "main\static\main\style.css" (echo   [НЕТ] main\static\main\style.css   & set STRUCT_OK=0)
if exist     "config\manage.py"           (echo   [ЛИШНИЙ] config\manage.py          & set STRUCT_OK=0)
if exist     "config\config\settings.py"  (echo   [ЛИШНИЙ] config\config\settings.py & set STRUCT_OK=0)

if "%STRUCT_OK%"=="1" (
    echo [OK] Структура корректна.
) else (
    echo [ОШИБКА] Структура неполная, см. выше.
    pause
    exit /b 1
)
echo.

REM ============================================
REM  ГОТОВО
REM ============================================
echo ============================================
echo   ГОТОВО!
echo ============================================
echo.
echo   http://127.0.0.1:8000/       - главная
echo   http://127.0.0.1:8000/admin/ - админка
echo.

choice /C YN /M "Запустить сервер сейчас"
if !errorlevel! == 1 (
    start "" http://127.0.0.1:8000
    python manage.py runserver
) else (
    echo Чтобы запустить позже:
    echo    .venv\Scripts\activate.bat
    echo    python manage.py runserver
    pause
)

endlocal