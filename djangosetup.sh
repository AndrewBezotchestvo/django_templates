#!/usr/bin/env bash
# ============================================
#  Django Project Setup (macOS / Linux)
# ============================================
set -euo pipefail

# Переход в папку скрипта (ключевой момент)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  Установка Django-проекта"
echo "============================================"
echo "Папка: $PWD"
echo

# ============================================
#  Проверка Python 3
# ============================================
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ОШИБКА] python3 не найден."
    echo "Установи: brew install python  (или с https://python.org)"
    exit 1
fi
PYVER=$(python3 --version 2>&1 | awk '{print $2}')
echo "[OK] Python $PYVER найден."
echo

# ============================================
#  Проверка: не сломан ли проект от прошлого запуска
# ============================================
if [ -f "config/manage.py" ]; then
    echo "[ОШИБКА] Прошлый запуск создал вложенный проект: config/manage.py"
    echo "Исправление: удали папку config и запусти setup.sh заново."
    exit 1
fi
if [ -f "config/config/settings.py" ]; then
    echo "[ОШИБКА] Прошлый запуск создал вложенный проект: config/config/settings.py"
    echo "Исправление: удали папку config и запусти setup.sh заново."
    exit 1
fi

# ============================================
#  1. requirements.txt
# ============================================
echo "[1/8] requirements.txt..."
if [ -f "requirements.txt" ]; then
    echo "[INFO] уже есть."
else
    cat > requirements.txt <<'EOF'
Django==5.0.6
python-dotenv==1.0.1
django-environ==0.11.2
EOF
    [ -f "requirements.txt" ] || { echo "[ОШИБКА] requirements.txt не создан"; exit 1; }
    echo "[OK] создан."
fi
echo

# ============================================
#  2. venv
# ============================================
if [ -x ".venv/bin/python" ]; then
    echo "[INFO] .venv уже существует."
else
    echo "[2/8] Создаю venv..."
    python3 -m venv .venv
    [ -x ".venv/bin/python" ] || { echo "[ОШИБКА] venv не создался."; exit 1; }
    echo "[OK] venv создан."
fi
echo

# ============================================
#  3. Активация venv
# ============================================
echo "[3/8] Активирую venv..."
# shellcheck disable=SC1091
source .venv/bin/activate
VENV_PREFIX=$(python -c "import sys;print(sys.prefix)")
case "$VENV_PREFIX" in
    *".venv"*) echo "[OK] venv активен: $VENV_PREFIX" ;;
    *) echo "[ОШИБКА] venv не активировался. Python: $VENV_PREFIX"; exit 1 ;;
esac
echo

# ============================================
#  4. Зависимости
# ============================================
echo "[4/8] Устанавливаю зависимости..."
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
echo "[OK] установлены."
echo

# ============================================
#  5. Django-проект
# ============================================
echo "[5/8] Создаю Django-проект..."
if [ -f "manage.py" ]; then
    echo "[INFO] manage.py уже в корне, пропускаю."
else
    echo "[INFO] Запуск: python -m django startproject config \"$PWD\""
    python -m django startproject config "$PWD"

    # Проверка 1: manage.py в корне
    if [ ! -f "manage.py" ]; then
        echo "[ОШИБКА] manage.py НЕ появился в корне."
        echo "Содержимое папки:"
        ls -la
        exit 1
    fi

    # Проверка 2: нет вложенного config/config
    if [ -f "config/config/settings.py" ]; then
        echo "[ОШИБКА] Создался вложенный проект config/config/."
        echo "Удали config и запусти setup.sh заново."
        exit 1
    fi

    # Проверка 3: settings.py на месте
    if [ ! -f "config/settings.py" ]; then
        echo "[ОШИБКА] config/settings.py не найден."
        exit 1
    fi

    echo "[OK] Проект создан: manage.py в корне, config/settings.py на месте."
fi
echo

# ============================================
#  6. Приложение main
# ============================================
echo "[6/8] Создаю приложение main..."
if [ -f "main/apps.py" ]; then
    echo "[INFO] main уже есть."
else
    python manage.py startapp main
    [ -f "main/apps.py" ] || { echo "[ОШИБКА] startapp main не сработал."; exit 1; }
    echo "[OK] main создано."
fi
echo

# ============================================
#  7. Шаблоны, статика, views, urls
# ============================================
echo "[7/8] Создаю файлы main/..."

mkdir -p "main/templates/main"
mkdir -p "main/static/main"

# --- base.html ---
cat > "main/templates/main/base.html" <<'EOF'
{% load static %}
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Мой проект{% endblock %}</title>
    <link rel="stylesheet" href="{% static 'main/style.css' %}">
</head>
<body>
    <header class="site-header">
        <div class="container">
            <h1>Мой Django-проект</h1>
            <nav>
                <a href="/">Главная</a>
                <a href="/admin/">Админка</a>
            </nav>
        </div>
    </header>
    <main class="container">
        {% block content %}{% endblock %}
    </main>
    <footer class="site-footer">
        <div class="container">Django Student Template</div>
    </footer>
</body>
</html>
EOF

# --- index.html ---
cat > "main/templates/main/index.html" <<'EOF'
{% extends "main/base.html" %}

{% block title %}Главная{% endblock %}

{% block content %}
    <section class="card">
        <h2>Добро пожаловать!</h2>
        <p>Проект успешно создан и работает. Это стартовая страница приложения <code>main</code>.</p>
        <ul>
            <li>Шаблоны: <code>main/templates/main/</code></li>
            <li>Стили: <code>main/static/main/style.css</code></li>
            <li>Маршруты: <code>main/urls.py</code></li>
        </ul>
    </section>
{% endblock %}
EOF

# --- style.css ---
cat > "main/static/main/style.css" <<'EOF'
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; background: #f5f6fa; color: #222; line-height: 1.6; }
.container { max-width: 900px; margin: 0 auto; padding: 0 20px; }
.site-header { background: #092e20; color: #fff; padding: 20px 0; }
.site-header h1 { font-size: 22px; margin-bottom: 8px; }
.site-header nav a { color: #9fd6b5; margin-right: 16px; text-decoration: none; }
.site-header nav a:hover { color: #fff; }
main.container { padding-top: 30px; padding-bottom: 30px; }
.card { background: #fff; border-radius: 8px; padding: 24px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
.card h2 { margin-bottom: 12px; }
.card p, .card ul { margin-bottom: 12px; }
.card ul { padding-left: 20px; }
code { background: #eef; padding: 1px 5px; border-radius: 3px; font-size: 90%; }
.site-footer { border-top: 1px solid #e1e4e8; padding: 16px 0; color: #666; font-size: 14px; margin-top: 40px; }
EOF

# --- main/views.py ---
cat > "main/views.py" <<'EOF'
from django.shortcuts import render

def index(request):
    return render(request, "main/index.html")
EOF

# --- main/urls.py ---
cat > "main/urls.py" <<'EOF'
from django.urls import path
from . import views

app_name = "main"

urlpatterns = [
    path("", views.index, name="index"),
]
EOF

# --- Проверка файлов ---
for f in "main/templates/main/index.html" "main/static/main/style.css" "main/views.py" "main/urls.py"; do
    [ -f "$f" ] || { echo "[ОШИБКА] $f не создался."; exit 1; }
done
echo "[OK] Файлы main/ созданы и проверены."
echo

# ============================================
#  8. Патчим settings.py и urls.py
# ============================================
echo "[8/8] Подключаю main в настройки..."

python - <<'PYEOF'
import sys
p = "config/settings.py"
s = open(p, encoding="utf-8").read()
if '"main"' not in s:
    s = s.replace(
        '"django.contrib.staticfiles",',
        '"django.contrib.staticfiles",\n    "main",',
        1,
    )
    open(p, "w", encoding="utf-8").write(s)
sys.exit(0 if '"main"' in open(p, encoding="utf-8").read() else 1)
PYEOF
if [ $? -ne 0 ]; then
    echo "[ОШИБКА] Не удалось добавить 'main' в INSTALLED_APPS."
    echo "Открой config/settings.py и добавь вручную:    \"main\","
    exit 1
fi
echo "[OK] 'main' в INSTALLED_APPS."

python - <<'PYEOF'
import sys
p = "config/urls.py"
s = open(p, encoding="utf-8").read()
if "main.urls" not in s:
    s = s.replace("from django.urls import path",
                  "from django.urls import path, include", 1)
    s = s.replace("urlpatterns = [",
                  "urlpatterns = [\n    path('', include('main.urls')),", 1)
    open(p, "w", encoding="utf-8").write(s)
sys.exit(0 if "main.urls" in open(p, encoding="utf-8").read() else 1)
PYEOF
if [ $? -ne 0 ]; then
    echo "[ОШИБКА] Не удалось подключить main.urls."
    echo "Открой config/urls.py и добавь:"
    echo "    from django.urls import include"
    echo "    path('', include('main.urls')),"
    exit 1
fi
echo "[OK] main.urls подключён."
echo

# ============================================
#  .env и миграции
# ============================================
if [ -f ".env" ]; then
    echo "[INFO] .env уже есть."
else
    cat > .env <<'EOF'
DEBUG=True
SECRET_KEY=dev-only-change-me-in-production
ALLOWED_HOSTS=127.0.0.1,localhost
EOF
    echo "[OK] .env создан."
fi

echo "Применяю миграции..."
python manage.py migrate --noinput
echo "[OK] База готова."
echo

# ============================================
#  Финальная проверка структуры
# ============================================
echo "Проверяю структуру проекта..."
STRUCT_OK=1
check() { [ -e "$1" ] || { echo "  [НЕТ] $1"; STRUCT_OK=0; }; }
check_absent() { [ ! -e "$1" ] || { echo "  [ЛИШНИЙ] $1"; STRUCT_OK=0; }; }

check "manage.py"
check "config/settings.py"
check "main/apps.py"
check "main/views.py"
check "main/urls.py"
check "main/templates/main/base.html"
check "main/templates/main/index.html"
check "main/static/main/style.css"
check_absent "config/manage.py"
check_absent "config/config/settings.py"

if [ "$STRUCT_OK" -eq 1 ]; then
    echo "[OK] Структура корректна."
else
    echo "[ОШИБКА] Структура неполная, см. выше."
    exit 1
fi
echo

# ============================================
#  ГОТОВО
# ============================================
echo "============================================"
echo "  ГОТОВО!"
echo "============================================"
echo
echo "  http://127.0.0.1:8000/       - главная"
echo "  http://127.0.0.1:8000/admin/ - админка"
echo

read -r -p "Запустить сервер сейчас? [Y/n] " ans
ans=${ans:-Y}
if [[ "$ans" =~ ^[YyДд]$ ]]; then
    (sleep 2 && open "http://127.0.0.1:8000" 2>/dev/null || true) &
    python manage.py runserver
else
    echo "Чтобы запустить позже:"
    echo "    source .venv/bin/activate"
    echo "    python manage.py runserver"
fi
