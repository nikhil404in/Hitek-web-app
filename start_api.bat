@echo off
title Phone Search API - http://127.0.0.1:8000/ui
echo.
echo  =============================================================
echo   Instant Phone Search API (Parquet Engine)
echo   Web UI   : http://127.0.0.1:8000/ui
echo   API Docs : http://127.0.0.1:8000/docs
echo  =============================================================
echo.

for /f "tokens=5" %%%%a in ('netstat -aon ^^| findstr ":8000" ^^| findstr "LISTENING"') do (
    echo Port 8000 is in use by PID %%%%a. Freeing port...
    taskkill /F /PID %%%%a >nul 2>&1
    timeout /t 1 >nul
)

cd /d "%~dp0"
python api\main.py
pause

