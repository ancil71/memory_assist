@echo off
echo Cleaning project...
call flutter clean
echo.
echo Getting dependencies...
call flutter pub get
echo.
echo Building web app (HTML renderer)...
call flutter build web --release --verbose
if %errorlevel% neq 0 (
    echo Build failed! Please check the output above.
    exit /b %errorlevel%
)
echo.
echo Deploying to Firebase...
call firebase deploy
echo.
echo Done!
