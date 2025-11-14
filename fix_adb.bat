@echo off
:: Check for admin rights
NET FILE > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

echo Resetting network components...
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

echo Restarting ADB...
taskkill /F /IM adb.exe > NUL 2>&1
adb kill-server
timeout 2 > NUL
adb start-server

echo Verification:
adb devices

pause