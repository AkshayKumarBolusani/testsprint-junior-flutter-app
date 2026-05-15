@echo off
setlocal EnableExtensions
REM Flutter 3.4x native asset hooks on Windows often break when the project path
REM contains spaces (e.g. "JME MEDIA", "TestSprint Junior"). SUBST maps this folder
REM to a drive letter so hook commands are not split at spaces.
set "DRIVE=Z:"
cd /d "%~dp0"
subst %DRIVE% "%CD%" >nul 2>&1
if errorlevel 1 (
  echo Could not map %DRIVE% to "%CD%".
  echo If %DRIVE% is in use, edit DRIVE in this script ^(e.g. Y:^) or run: subst %DRIVE% /d
  exit /b 1
)
pushd %DRIVE%\
echo Running from %CD%
call flutter run -d chrome %*
set "EC=%ERRORLEVEL%"
popd
subst %DRIVE% /d >nul 2>&1
exit /b %EC%
