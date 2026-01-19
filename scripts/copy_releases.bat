@echo off
REM Script to copy release builds to releases folder with versioning
REM Usage: scripts\copy_releases.bat

cd /d "%~dp0\.."

REM Get version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
set VERSION=%VERSION: =%

if "%VERSION%"=="" (
    echo Error: Could not find version in pubspec.yaml
    exit /b 1
)

echo Version: %VERSION%

REM Create releases folder if it doesn't exist
if not exist "releases" mkdir releases

REM Copy APK
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "releases\ramadan-tracker-v%VERSION%.apk"
    echo [OK] Copied APK: releases\ramadan-tracker-v%VERSION%.apk
) else (
    echo [ERROR] APK not found: build\app\outputs\flutter-apk\app-release.apk
)

REM Copy AAB
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy /Y "build\app\outputs\bundle\release\app-release.aab" "releases\ramadan-tracker-v%VERSION%.aab"
    echo [OK] Copied AAB: releases\ramadan-tracker-v%VERSION%.aab
) else (
    echo [ERROR] AAB not found: build\app\outputs\bundle\release\app-release.aab
)

echo.
echo Release files copied to releases\ folder
dir /b releases\ramadan-tracker-v%VERSION%.*

