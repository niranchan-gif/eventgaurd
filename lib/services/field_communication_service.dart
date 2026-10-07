import 'dart:async';
import 'dart:math';

enum FieldDeviceState { online, offline, degraded }
enum MessageType { alert, acknowledged, resolved, system, emergency }

class FieldDevice {
  final String deviceId;
  final String unitId;
  FieldDeviceState connectionState;
  DateTime lastHeartbeat;
  int batteryLevel;

  FieldDevice({
    required this.deviceId,
    required this.unitId,
    this.connectionState = FieldDeviceState.online,
    required this.lastHeartbeat,
    this.batteryLevel = 100,
  });
}

class FieldCommunicationService {
  final List<FieldDevice> _devices = [];
  
  void initializeSimulatedClients(int count) {
    _devices.clear();
    for (int i = 0; i < count; i++) {
      _devices.add(FieldDevice(
        deviceId: 'DEV-${1000 + i}',
        unitId: 'UNIT-${i + 1}',
        lastHeartbeat: DateTime.now(),
        batteryLevel: 80 + Random().nextInt(20),
      ));
    }
  }

  List<FieldDevice> get connectedDevices => _devices.where((d) => d.connectionState == FieldDeviceState.online).toList();

  Future<void> broadcastAlert(String alertId, String payload) async {
    // In production, this would use WebSockets or LoRa to push to all connected devices.
    // For demo/simulation:
    await Future.delayed(const Duration(milliseconds: 500));
    print('[FIELD COMM] Broadcasted ALERT $alertId to ${connectedDevices.length} field units.');
  }
}
