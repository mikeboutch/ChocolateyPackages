@echo off
net session >nul 2>&1
if %errorLevel% == 0 goto RunScript
  else (
   color 4e
   cls
   echo.
   echo                  ********************************************
   echo                  *  You must choose "Run as administrator"  *
   echo                  ********************************************
   echo.
   timeout 5
   goto end
 )

:RunScript
powershell -NoProfile -ExecutionPolicy Bypass -Command "%ChocolateyInstall%\bin\Choco-Cleaner.ps1"
:end

