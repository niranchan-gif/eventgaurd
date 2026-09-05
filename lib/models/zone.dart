class Zone {
  final String id;
  final String name;
  final int cameraCount;
  final int activeAlerts;
  final String threatLevel;

  Zone({
    required this.id,
    required this.name,
    required this.cameraCount,
    required this.activeAlerts,
    required this.threatLevel,
  });
}
