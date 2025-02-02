@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   Internet Connection Benchmark & Optimization Tool
echo ==========================================
echo.
echo Resetting Winsock...
netsh winsock reset >nul
echo Resetting IP settings...
netsh int ip reset >nul
echo Flushing DNS cache...
ipconfig /flushdns >nul

echo.
echo Restarting network interfaces...
rem Adjust the adapter names if yours differ (e.g., "Wireless Network Connection")
netsh interface set interface "Wi-Fi" admin=disable >nul
timeout /t 2 /nobreak >nul
netsh interface set interface "Wi-Fi" admin=enable >nul
netsh interface set interface "Ethernet" admin=disable >nul
timeout /t 2 /nobreak >nul
netsh interface set interface "Ethernet" admin=enable >nul
timeout /t 5 /nobreak >nul

echo.
echo NOTE: This script requires speedtest.exe (Speedtest CLI) to be available.
echo It will test various TCP settings to see which yields the highest download speed.
echo.
pause

rem Initialize “best” values
set bestInt=0
set bestSpeed=0
set bestLevel=none

rem Loop through various TCP autotuning levels.
rem (Other global TCP settings are fixed in this test.)
for %%L in (disabled highlyrestricted restricted normal experimental) do (
    echo --------------------------------------------------
    echo Testing autotuning level: %%L
    netsh int tcp set global autotuninglevel=%%L >nul
    netsh int tcp set global chimney=enabled >nul
    netsh int tcp set global rss=enabled >nul
    netsh int tcp set global congestionprovider=ctcp >nul

    echo Waiting for settings to take effect...
    timeout /t 5 /nobreak >nul

    echo Running speedtest for autotuning level %%L...
    rem Capture the line containing "Download"
    for /f "tokens=1,2,* delims=: " %%a in ('speedtest.exe ^| findstr /i "Download"') do (
        rem Assuming a line like: "Download: 9.61 Mbit/s"
        set currentSpeed=%%b
    )

    rem Remove any stray spaces from the speed string
    set currentSpeed=!currentSpeed: =!
    rem Convert currentSpeed (e.g., "9.61") into an integer by removing the decimal point.
    set currentInt=!currentSpeed:.=!
    echo Autotuning level %%L resulted in download speed: !currentSpeed! Mbit/s (Integer: !currentInt!)
    
    rem Compare the current test to the best so far
    if !currentInt! GTR !bestInt! (
        set bestInt=!currentInt!
        set bestSpeed=!currentSpeed!
        set bestLevel=%%L
    )
    echo.
    timeout /t 3 /nobreak >nul
)

echo.
echo ==========================================
echo Best autotuning level found: !bestLevel! with !bestSpeed! Mbit/s download speed.
echo Applying best settings...
netsh int tcp set global autotuninglevel=!bestLevel!
netsh int tcp set global chimney=enabled
netsh int tcp set global rss=enabled
netsh int tcp set global congestionprovider=ctcp
echo.
echo Optimization complete.
pause
