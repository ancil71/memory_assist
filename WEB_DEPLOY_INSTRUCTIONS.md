# Deploying Memory Assist to the Web

Because of environmental issues causing the process to hang, please follow these steps carefully:

## 1. Restart Your Computer (IMPORTANT)
The build processes (`flutter pub get`, etc.) have been hanging for hours. A restart is the only reliable way to clear these locked processes.

## 2. Run the Deployment Script
After your computer restarts:
1. Open this folder in File Explorer or a terminal: `c:\Users\ASUS\gravity_things\memory_assist`
2. Double-click or run: `deploy.bat`

This script will automatically:
- Clean the project
- Get dependencies
- Build the web version (HTML renderer)
- Deploy to Firebase Hosting

## 3. Access Your App
Once the script says "Done!", your app will be live at:
**[https://memory-assist-c1dfd.web.app](https://memory-assist-c1dfd.web.app)**

## Troubleshooting
If `deploy.bat` fails:
- Check your internet connection (needed for Firebase).
- Ensure no other `dart.exe` processes are running.
- Try running `flutter doctor` to see if your Flutter installation is healthy.
