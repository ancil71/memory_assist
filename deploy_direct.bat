@echo off
set FLUTTER_ROOT=C:\flutter
set DART_EXE=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart.exe
set SNAPSHOT=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot
set PACKAGE_CONFIG=%FLUTTER_ROOT%\packages\flutter_tools\.dart_tool\package_config.json

echo Cleaning manually...
rmdir /S /Q build .dart_tool
del /Q %FLUTTER_ROOT%\bin\cache\lockfile

echo.
echo getting dependencies (offline if possible)...
"%DART_EXE%" pub get --offline
if %errorlevel% neq 0 (
    echo Online pub get...
    "%DART_EXE%" pub get
)

echo.
echo Building web app (HTML renderer)...
"%DART_EXE%" --packages="%PACKAGE_CONFIG%" "%SNAPSHOT%" build web --web-renderer html
if %errorlevel% neq 0 (
    echo Build failed!
    exit /b %errorlevel%
)

echo.
echo Deploying to Firebase...
call firebase deploy

echo.
echo Done! App should be live.
