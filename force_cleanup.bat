@echo off
echo Killing lingering processes...
taskkill /F /IM renamery.exe 2>NUL
taskkill /F /IM dart.exe 2>NUL
echo.
echo Forcing directory deletion...
rmdir /S /Q build 2>NUL
rmdir /S /Q .dart_tool 2>NUL
echo.
echo Cleaning Flutter project...
call "C:\src\flutter\bin\flutter" clean
echo.
echo Rebuilding Windows app...
"C:\src\flutter\bin\flutter" run -d windows
pause
