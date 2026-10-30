@echo off
setlocal
cd /d "%~dp0"

set "NODE_EXE="
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%I in ('where node') do (
        if not defined NODE_EXE set "NODE_EXE=%%I"
    )
)

if not defined NODE_EXE (
    if exist "%APPDATA%\fnm\aliases\default\node.exe" (
        set "NODE_EXE=%APPDATA%\fnm\aliases\default\node.exe"
    )
)

if not defined NODE_EXE (
    for /f "delims=" %%D in ('dir /b /ad /o-n "%APPDATA%\fnm\node-versions" 2^>nul') do (
        if not defined NODE_EXE (
            if exist "%APPDATA%\fnm\node-versions\%%D\installation\node.exe" (
                set "NODE_EXE=%APPDATA%\fnm\node-versions\%%D\installation\node.exe"
            )
        )
    )
)

if not defined NODE_EXE (
    for /f "delims=" %%D in ('dir /b /ad /o-d "%LOCALAPPDATA%\fnm_multishells" 2^>nul') do (
        if not defined NODE_EXE (
            if exist "%LOCALAPPDATA%\fnm_multishells\%%D\node.exe" (
                set "NODE_EXE=%LOCALAPPDATA%\fnm_multishells\%%D\node.exe"
            )
        )
    )
)

if not defined NODE_EXE (
    if exist "%ProgramFiles%\nodejs\node.exe" (
        set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
    )
)

if not defined NODE_EXE (
    echo [ERROR] Cannot find node.exe on this computer.
    pause
    exit /b 1
)

chcp 65001 >nul
if not "%STUDIO_NO_OPEN%"=="1" start "" "http://127.0.0.1:8765"
"%NODE_EXE%" "%~dp0studio_server.js"
pause
