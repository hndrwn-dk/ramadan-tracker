@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."

echo ==^> flutter pub get
call flutter pub get
if errorlevel 1 exit /b 1

echo ==^> Unit regression (seeder + layout)
call flutter test test\regression_seeder_test.dart test\regression_layout_test.dart --reporter expanded
if errorlevel 1 exit /b 1

set "DEVICE=%REGRESSION_DEVICE%"
if "%DEVICE%"=="" (
  for /f "tokens=*" %%a in ('flutter devices 2^>nul ^| findstr /i emulator') do (
    for /f "tokens=2 delims=•" %%b in ("%%a") do (
      set "DEVICE=%%b"
      goto :found
    )
  )
)
:found
if "%DEVICE%"=="" (
  echo.
  echo ERROR: No Android emulator/device found.
  echo Start an AVD, then rerun. Or: set REGRESSION_DEVICE=emulator-5554
  exit /b 1
)

set "DEVICE=%DEVICE: =%"
set "PKG=com.tursinalabs.ramadan.tracker"

echo ==^> Integration regression on device: %DEVICE%

where adb >nul 2>&1
if not errorlevel 1 (
  echo ==^> Clearing app data for clean seeded run
  adb -s %DEVICE% shell pm clear %PKG% 2>nul
  adb -s %DEVICE% shell am force-stop %PKG% 2>nul
  adb -s %DEVICE% shell pm grant %PKG% android.permission.POST_NOTIFICATIONS 2>nul
  adb -s %DEVICE% shell pm grant %PKG% android.permission.ACCESS_FINE_LOCATION 2>nul
  adb -s %DEVICE% shell pm grant %PKG% android.permission.ACCESS_COARSE_LOCATION 2>nul
)

call flutter test integration_test\regression_emulator_test.dart -d %DEVICE% --dart-define=REGRESSION_SEED=true --reporter expanded
if errorlevel 1 exit /b 1

echo ==^> Regression finished OK
exit /b 0
