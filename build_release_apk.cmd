@echo off
REM Builds release APK from C:\dev\testsprint_junior_build (no spaces) — required when your
REM Windows username or project folder contains spaces (breaks objective_c native asset hooks).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_release_apk.ps1"
exit /b %ERRORLEVEL%
