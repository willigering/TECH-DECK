@echo off
cd /d "%~dp0"
if not exist .venv (
  py -3 -m venv .venv
)
call .venv\Scripts\activate.bat
python -m pip install -r requirements.txt
if not exist .env (
  copy .env.example .env
  echo Bitte XAI_API_KEY in backend\.env eintragen.
)
python -m uvicorn main:app --host 0.0.0.0 --port 8787
pause
