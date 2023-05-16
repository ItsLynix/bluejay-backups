@echo off
echo "Attempting to set PowerShell execution policy..."
powershell Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
echo "Launching manager..."
powershell.exe .\manager.ps1