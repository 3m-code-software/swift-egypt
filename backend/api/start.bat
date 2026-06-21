@echo off
cd /d "K:\Swift Egypt\swift_egypt\backend\api"
start /B "" "venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > server.log 2> server.err
echo Server started
