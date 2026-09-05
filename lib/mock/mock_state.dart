import 'package:flutter/material.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../models/incident.dart';
import '../models/zone.dart';

class MockState extends ChangeNotifier {
  List<Camera> cameras = [
    Camera(
      id: 'CAM-001',
      name: 'North Gate Cam',
      location: 'North Border Sector 01',
      zone: 'North',
      status: CameraStatus.online,
      signal: 'Strong',
      lastActive: DateTime.now(),
      detectionModes: {'Person': DetectionMode.active, 'Vehicle': DetectionMode.active},
      currentDetection: 'Person Detected',
    ),
    Camera(
      id: 'CAM-002',
      name: 'East Border',
      location: 'East Sector 02',
      zone: 'East',
      status: CameraStatus.online,
      signal: 'Medium',
      lastActive: DateTime.now(),
      detectionModes: {'Person': DetectionMode.active, 'Vehicle': DetectionMode.active},
      currentDetection: 'No Threat',
    ),
    Camera(
      id: 'CAM-003',
      name: 'Sector 07',
      location: 'West Sector 07',
      zone: 'West',
      status: CameraStatus.online,
      signal: 'Strong',
      lastActive: DateTime.now(),
      detectionModes: {'Vehicle': DetectionMode.active},
      currentDetection: 'Vehicle Detected',
    ),
    Camera(
      id: 'CAM-014',
      name: 'North Sector 04',
      location: 'North Border Sector 04',
      zone: 'North',
      status: CameraStatus.online,
      signal: 'Strong',
      lastActive: DateTime.now(),
      detectionModes: {'Intrusion': DetectionMode.active},
      currentDetection: 'Motion Detected',
    ),
    Camera(
      id: 'CAM-021',
      name: 'East Outpost',
      location: 'East Sector 05',
      zone: 'East',
      status: CameraStatus.offline,
      signal: 'Lost',
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      detectionModes: {},
      currentDetection: 'Offline',
    ),
  ];

  List<Alert> alerts = [
    Alert(
      id: 'ALT-101',
      title: 'Border Intrusion Detected',
      severity: AlertSeverity.critical,
      confidence: 94,
      cameraId: 'CAM-014',
      location: 'North Sector',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Alert(
      id: 'ALT-102',
      title: 'Unauthorized Person Detected',
      severity: AlertSeverity.high,
      confidence: 88,
      cameraId: 'CAM-021',
      location: 'East Sector',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    Alert(
      id: 'ALT-103',
      title: 'Vehicle Entered Restricted Zone',
      severity: AlertSeverity.medium,
      confidence: 75,
      cameraId: 'CAM-008',
      location: 'West Sector',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  List<Incident> incidents = [
    Incident(
      id: 'INC-1024',
      threatType: 'Border Intrusion',
      cameraId: 'CAM-014',
      location: 'North Sector',
      severity: IncidentSeverity.critical,
      detectedAt: DateTime.now().subtract(const Duration(hours: 1)),
      assignedTo: 'Operator 01',
      confidence: 94,
      notes: 'Investigating potential breach near sector 4',
      status: IncidentStatus.investigating,
    ),
    Incident(
      id: 'INC-1025',
      threatType: 'Suspicious Vehicle',
      cameraId: 'CAM-003',
      location: 'West Sector',
      severity: IncidentSeverity.medium,
      detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
      assignedTo: 'Unassigned',
      confidence: 82,
      notes: '',
      status: IncidentStatus.newIncident,
    ),
  ];

  List<Zone> zones = [
    Zone(id: 'Z1', name: 'North Border Sector 04', cameraCount: 8, activeAlerts: 2, threatLevel: 'HIGH'),
    Zone(id: 'Z2', name: 'East Sector 02', cameraCount: 12, activeAlerts: 0, threatLevel: 'LOW'),
    Zone(id: 'Z3', name: 'West Sector 07', cameraCount: 5, activeAlerts: 1, threatLevel: 'MEDIUM'),
  ];

  void addCamera(Camera cam) {
    cameras.add(cam);
    notifyListeners();
  }
  
  void deleteCamera(String id) {
    cameras.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void acknowledgeAlert(String id) {
    var a = alerts.firstWhere((a) => a.id == id);
    a.status = AlertStatus.acknowledged;
    notifyListeners();
  }

  void resolveAlert(String id) {
    var a = alerts.firstWhere((a) => a.id == id);
    a.status = AlertStatus.resolved;
    notifyListeners();
  }

  void updateIncidentStatus(String id, IncidentStatus status) {
    var i = incidents.firstWhere((i) => i.id == id);
    i.status = status;
    notifyListeners();
  }
}
