@echo off
setlocal

cd /d "%~dp0"

REM Launcher for the protected rcfb build. Mirrors the original start.bat, but
REM runs the compiled rcfb.exe instead of python server.py, so no Python
REM installation or requirements.txt is needed on the target machine.
REM
REM   .env          is read next to this script; it must contain PASSWORD=...
REM   transfers\    is created next to rcfb.exe and holds uploaded files.

where cloudflared >nul 2>nul || (echo [ERROR] cloudflared not found on PATH & pause & exit /b 1)
if not exist "rcfb.exe" (echo [ERROR] rcfb.exe not found in %CD% & pause & exit /b 1)
if not exist ".env" (
    echo [WARN] .env not found. The login page needs PASSWORD=... in .env
    pause
)

echo [*] Starting rcfb server on http://127.0.0.1:6767 ...
start "rcfb server" cmd /k "cd /d ""%CD%"" && rcfb.exe"

echo [*] Waiting for server to come up...
:wait
timeout /t 1 /nobreak >nul
powershell -NoProfile -Command "try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:6767/login -TimeoutSec 2) | Out-Null; exit 0 } catch { exit 1 }" >nul 2>nul
if errorlevel 1 goto wait

echo [*] Starting cloudflared quick tunnel...
start "rcfb tunnel" cmd /k "cloudflared tunnel --url localhost:6767 --no-autoupdate"

echo.
echo ============================================================
echo  rcfb is running (protected build).
echo    Local:  http://127.0.0.1:6767
echo    Public: look for the https://*.trycloudflare.com line in
echo            the "rcfb tunnel" window that just opened.
echo  Close either window (or press Ctrl+C in it) to stop that part.
echo ============================================================
echo.

endlocal
