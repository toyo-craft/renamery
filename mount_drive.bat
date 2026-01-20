@echo off
rem Change to the directory where this script is located
cd /d "%~dp0"

echo Unmounting R: if it exists...
subst R: /D >NUL 2>&1

echo.
echo Mounting parent folder (source) as Drive R: ...
rem Use ".." to represent parent directory
subst R: ..

if exist R:\renamery\ (
    echo.
    echo [SUCCESS] Drive R: is now mounted to the 'source' directory!
    echo.
    echo Next Steps:
    echo 1. Close your current VS Code completely.
    echo 2. Open VS Code again.
    echo 3. Go to File - Open Folder...
    echo 4. Select "R:\renamery" from the list.
    echo    (Your project is now at R:\renamery)
    echo 5. Run your build/debug from that new window.
) else (
    echo.
    echo [FAILED] Could not mount drive or find renamery folder at R:\renamery.
)
echo.
pause
