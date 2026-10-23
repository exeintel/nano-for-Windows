@echo off
rem GNU nano portable launcher (32-bit).
setlocal
set "HOME=%~dp0"
"%~dp0nano.exe" %*
endlocal
