# EventGuard Staff Mobile App

This is the Flutter Android field application for EventGuard Staff Operators.

## Requirements
- Flutter SDK
- Android Studio or Android SDK

## Configuration
The app connects to the EventGuard HQ WebSocket server.

### Finding HQ LAN IP
On your Windows HQ PC, open PowerShell and run:
`ipconfig`
Look for the IPv4 Address (e.g., 192.168.1.x) under your Wi-Fi adapter. Use this IP in the Staff App setup screen.

### Windows Firewall
If the app cannot connect to HQ, ensure Windows Firewall allows inbound connections on TCP port 8765.

## Building the App
1. cd staff_app
2. flutter clean
3. flutter pub get
4. flutter build apk --debug

The APK will be generated at:
uild/app/outputs/flutter-apk/app-debug.apk

## Security Configuration
By default, the demo token is required to enroll a device. The token can be set via environment variables during compilation or entered manually during enrollment.
DO NOT use ws:// connections in production over the internet. This MVP demo relies on private local area networks.
