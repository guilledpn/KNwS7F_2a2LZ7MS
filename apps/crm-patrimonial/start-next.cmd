@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  echo No se encontro Python mediante el comando py.
  echo Instala Python 3 o ejecuta: python scripts\run_local.py
  pause
  exit /b 1
)
py scripts\run_local.py
