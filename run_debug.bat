@echo off
echo Starting ReNamery in Debug Mode...
echo logs will be saved to debug_log.txt
"C:\src\flutter\bin\flutter" run -d windows -v > debug_log.txt 2>&1
echo Done.
pause
