@echo off
chcp 65001 >nul
cd /d "%~dp0backend"
if not exist .venv (
  echo 正在创建 Python 虚拟环境...
  python -m venv .venv
)
call .venv\Scripts\activate.bat
pip install -r requirements.txt -q
if not exist .env (
  copy .env.example .env >nul
  echo 已根据 .env.example 生成 backend\.env
)
echo 初始化数据库（需 MySQL 已启动）...
python init_db.py
echo 启动后端: http://127.0.0.1:5000
python app.py
pause
