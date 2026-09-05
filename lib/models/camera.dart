enum CameraStatus { online, offline }
enum DetectionMode { active, inactive }

class Camera {
  final String id;
  final String name;
  final String location;
  final String zone;
  final CameraStatus status;
  final String signal;
  final DateTime lastActive;
  final Map<String, DetectionMode> detectionModes;
  final String currentDetection;

  Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.zone,
    required this.status,
    required this.signal,
    required this.lastActive,
    required this.detectionModes,
    this.currentDetection = "No Threat",
  });
}
