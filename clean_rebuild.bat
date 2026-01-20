@echo off
echo Cleaning Flutter project...
call "C:\src\flutter\bin\flutter" clean
echo.
echo Rebuilding Windows app...
"C:\src\flutter\bin\flutter" run -d windows
pause
