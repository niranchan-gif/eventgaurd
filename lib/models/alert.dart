enum AlertSeverity { critical, high, medium, low }
enum AlertStatus { active, resolved, acknowledged }

class Alert {
  final String id;
  final String title;
  final AlertSeverity severity;
  final int confidence;
  final String cameraId;
  final String location;
  final DateTime detectedAt;
  AlertStatus status;

  Alert({
    required this.id,
    required this.title,
    required this.severity,
    required this.confidence,
    required this.cameraId,
    required this.location,
    required this.detectedAt,
    this.status = AlertStatus.active,
  });
}
