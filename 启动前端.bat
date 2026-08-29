@echo off
chcp 65001 >nul
cd /d "%~dp0"
call scripts\start-frontend.bat
