@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%removeAI.ps1" %*
if errorlevel 1 (
    echo.
    echo A execucao com -ExecutionPolicy Bypass falhou. Tentando liberar a politica para o usuario atual...
    powershell -NoProfile -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
    powershell -NoProfile -File "%SCRIPT_DIR%removeAI.ps1" %*
)
endlocal
