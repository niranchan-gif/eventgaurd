enum IncidentSeverity { critical, high, medium, low }
enum IncidentStatus { newIncident, investigating, resolved }

class Incident {
  final String id;
  final String threatType;
  final String cameraId;
  final String location;
  final IncidentSeverity severity;
  final DateTime detectedAt;
  final String assignedTo;
  IncidentStatus status;
  final int confidence;
  final String notes;

  Incident({
    required this.id,
    required this.threatType,
    required this.cameraId,
    required this.location,
    required this.severity,
    required this.detectedAt,
    required this.assignedTo,
    this.status = IncidentStatus.newIncident,
    required this.confidence,
    required this.notes,
  });
}
