enum CameraStatus { online, offline }
enum DetectionMode { active, inactive }

class Camera {
  final String id;
  final String name;
  final String location;
  final String zone;
  CameraStatus status;
  final String signal;
  DateTime lastActive;
  final Map<String, DetectionMode> detectionModes;
  String currentDetection;
  final bool isEmptySlot;

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
    this.isEmptySlot = false,
  });
}
