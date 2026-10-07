# EventGuard AI

EventGuard AI is an AI-powered event security and perimeter monitoring platform.

## Overview
EventGuard AI provides a centralized Event Command Center (HQ) for managing large crowds, monitoring restricted zones, and dispatching alerts to Event Security Operators on the field.

## Features
- **Flutter HQ Dashboard**: Real-time event monitoring interface.
- **Python AI Backend**: Integrates YOLO detection, Virtual Fence, Face Detection, and ANPR.
- **Camera Management**: Support for multiple monitoring nodes and camera feeds.
- **Incident Management**: Automated alert generation and field unit coordination.
- **Offline Operation**: Degraded operation support with alert queuing when the backend network is offline.

## Architecture
The application runs a lightweight Python backend for AI inference and a high-performance Flutter desktop frontend for the HQ dashboard.

## Security Considerations
- Employs AES-256-GCM for encrypted secure storage.
- Configurable secrets with no hardcoded master keys.
- Centralized configuration for endpoints and GitHub integrations.

## Setup (Windows)
1. Ensure Flutter is installed and configured for Windows desktop.
2. Run `flutter pub get`.
3. Launch via `flutter run -d windows` or build using `flutter build windows`.
4. The Python backend dependencies must be installed and backend launched.

## Limitations & Future Work
- Field-device communication is currently mocked via an abstraction layer and requires a real transport (e.g., Wi-Fi LAN/LoRa) for 30+ devices.
- Backend hardware requirements: NVIDIA GPU recommended for 30 FPS YOLO inference.
