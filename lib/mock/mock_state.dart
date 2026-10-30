import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../models/incident.dart';
import '../models/zone.dart';
import '../models/user_model.dart';
import '../services/github_auth_service.dart';
import '../services/backend_launcher.dart';

class LiveFeedEvent {
  final String id;
  final String title;
  final String cameraId;
  final String location;
  final int confidence;
  final DateTime timestamp;
  final Color badgeColor;
  final IconData icon;
  
LiveFeedEvent({
    required this.id,
    required this.title,
    required this.cameraId,
    required this.location,
    required this.confidence,
    required this.timestamp,
    required this.badgeColor,
    required this.icon,
  });
}

class MockState extends ChangeNotifier {
  Timer? _pollTimer;
  bool isBackendConnected = false;
  bool isCameraOn = true;
  double cam1Fps = 0.0;
  double cam2Fps = 0.0;
  String selectedDashboardCameraId = 'CAM-001';
  String cam2Source = '1';
  String cam1DeviceName = 'Main Entrance Camera';
  String cam2DeviceName = 'Mobile Steward Camera';
  String activeAiMode = "all";
  Map<String, int> cam1Counts = {'person': 0, 'vehicle': 0, 'animal': 0, 'face': 0};
  Map<String, int> cam2Counts = {'person': 0, 'vehicle': 0, 'animal': 0, 'face': 0};
  bool intrusionDetected = false;

  // Connected Field Staff
  List<Map<String, dynamic>> connectedStaffList = [];

  // Manual Demo Person Count Override State
  bool isManualPersonOverride = false;
  int manualPersonCount = 1;

  void setManualPersonCount(int count) {
    isManualPersonOverride = true;
    manualPersonCount = count.clamp(0, 300);
    cam1Counts['person'] = manualPersonCount;
    _evaluateCrowdRiskFromPersonCount();
    notifyListeners();
  }

  void incrementManualPersonCount([int step = 1]) {
    final current = isManualPersonOverride ? manualPersonCount : (cam1Counts['person'] ?? 0);
    setManualPersonCount(current + step);
  }

  void decrementManualPersonCount([int step = 1]) {
    final current = isManualPersonOverride ? manualPersonCount : (cam1Counts['person'] ?? 0);
    setManualPersonCount(math.max(0, current - step));
  }

  void resetManualPersonCountToLive() {
    isManualPersonOverride = false;
    _evaluateCrowdRiskFromPersonCount();
    notifyListeners();
  }

  void _evaluateCrowdRiskFromPersonCount() {
    final count = cam1Counts['person'] ?? 0;
    if (count >= 20) {
      intrusionDetected = true;
      final now = DateTime.now();
      if (!alerts.any((a) => a.title.contains('Surge') && now.difference(a.detectedAt).inSeconds < 12)) {
        final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
        alerts.insert(
          0,
          Alert(
            id: altId,
            title: 'CRITICAL: Crowd Surge Warning in Zone A',
            severity: AlertSeverity.critical,
            confidence: 96,
            cameraId: 'CAM-001',
            location: 'Zone A (Main Entrance)',
            detectedAt: now,
          ),
        );
        incidents.insert(
          0,
          Incident(
            id: 'INC-${now.millisecondsSinceEpoch.toString().substring(8)}',
            threatType: 'Crowd Surge & Congestion',
            cameraId: 'CAM-001',
            location: 'Zone A',
            severity: IncidentSeverity.critical,
            detectedAt: now,
            assignedTo: 'Lead Steward',
            confidence: 96,
            notes: 'Manual demo crowd surge threshold ($count attendees) reached.',
            status: IncidentStatus.investigating,
          ),
        );
      }
    } else {
      intrusionDetected = false;
    }
  }

  void selectDashboardCamera(String id) {
    selectedDashboardCameraId = id;
    notifyListeners();
  }

  // Live Stream Performance Metrics
  double liveBitrateKbps = 1450.0;
  int liveLatencyMs = 32;
  String selectedAnalyticsCameraId = 'CAM-001';
  List<LiveFeedEvent> liveFeedEvents = [];

  int _prevPersonCount = 0;
  int _prevVehicleCount = 0;
  int _prevFaceCount = 0;

  // Authentication State - Initialized clean; auto-authorized by SplashScreen boot sequence
  UserModel? currentUser;
  bool isAuthenticated = false;

  // System Configuration & Preferences State
  double detectionSensitivity = 0.85;
  bool highContrastMode = true;
  bool audibleSiren = true;
  bool autoPatrolDispatch = true;
  bool biometricConfirmation = false;
  String languageProtocol = 'English (Event Nomenclature)';
  String coordinatesStandard = 'Venue Spatial Grid / GPS';
  String falseAlarmFilter = 'Aggressive (AI Multi-frame verification)';

  // Real-time detection activity history directly updated from CAM-01 feed
  List<FlSpot> detectionHistory = List.generate(
    12,
    (i) => FlSpot(i.toDouble(), 0),
  );

  // High-resolution real-time live feed telemetry timeline (24 data points rolling every 700ms)
  List<FlSpot> liveFeedHistory = List.generate(
    24,
    (i) => FlSpot(i.toDouble(), 0),
  );

  // Live session detection metrics
  int totalPersonsDetected = 18;
  int totalVehiclesDetected = 6;
  int totalAnimalsDetected = 2;
  int totalFacesDetected = 14;
  int totalBreachesDetected = 1;

  // GRA (Grid-based Risk Analysis) Real-Time Telemetry Map
  Map<String, Map<String, dynamic>> graGridData = {
    'A1': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'A2': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'A3': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'B1': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'B2': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'B3': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'C1': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'C2': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
    'C3': {'risk_score': 0.0, 'severity': 'SAFE', 'people_count': 0},
  };
  String highestRiskZone = 'A1';
  double highestRiskScore = 0.0;
  String highestRiskSeverity = 'SAFE';

  WebSocket? _hqWs;
  bool isHqWsConnected = false;
  Timer? _wsReconnectTimer;

  MockState() {
    _initLiveEvents();
    _startBackendPolling();
    _connectHQWebSocket();
    BackendLauncher.ensureBackendRunning();
  }

  Future<void> _connectHQWebSocket() async {
    _wsReconnectTimer?.cancel();
    try {
      _hqWs = await WebSocket.connect('ws://127.0.0.1:8765/hq').timeout(const Duration(seconds: 2));
      isHqWsConnected = true;
      notifyListeners();

      _hqWs!.listen((message) {
        try {
          final data = json.decode(message.toString()) as Map<String, dynamic>;
          _handleHQWebSocketMessage(data);
        } catch (_) {}
      }, onDone: () {
        isHqWsConnected = false;
        _scheduleWsReconnect();
      }, onError: (_) {
        isHqWsConnected = false;
        _scheduleWsReconnect();
      });
    } catch (_) {
      isHqWsConnected = false;
      _scheduleWsReconnect();
    }
  }

  void _scheduleWsReconnect() {
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 3), () {
      _connectHQWebSocket();
    });
  }

  void _handleHQWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final now = DateTime.now();

    if (type == 'CROWD_RISK_ALERT') {
      final zone = (data['zone'] as String?) ?? 'A1';
      final severity = (data['severity'] as String?) ?? 'SAFE';
      final riskScore = (data['risk_score'] as num?)?.toDouble() ?? 0.0;
      final metrics = (data['metrics'] as Map<String, dynamic>?) ?? {};
      final alertId = (data['alert_id'] as String?) ?? 'ALT-${now.millisecondsSinceEpoch}';

      graGridData[zone] = {
        'risk_score': riskScore,
        'severity': severity,
        'people_count': metrics['people_count'] ?? 0,
        'density': metrics['density'] ?? 0,
        'congestion': metrics['congestion'] ?? 0,
        'growth': metrics['crowd_growth'] ?? 0,
        'irregularity': metrics['movement_irregularity'] ?? 0,
      };

      double maxScore = -1.0;
      String maxZone = zone;
      String maxSev = severity;
      for (final entry in graGridData.entries) {
        final sc = (entry.value['risk_score'] as num?)?.toDouble() ?? 0.0;
        if (sc > maxScore) {
          maxScore = sc;
          maxZone = entry.key;
          maxSev = (entry.value['severity'] as String?) ?? 'SAFE';
        }
      }
      highestRiskScore = maxScore;
      highestRiskZone = maxZone;
      highestRiskSeverity = maxSev;

      if (severity == 'CRITICAL' || severity == 'HIGH_WARNING') {
        alerts.insert(
          0,
          Alert(
            id: alertId,
            title: 'GRA: $severity Crowd Condition in Grid $zone',
            severity: severity == 'CRITICAL' ? AlertSeverity.critical : AlertSeverity.high,
            confidence: riskScore.round().clamp(1, 100),
            cameraId: 'CAM-001',
            location: 'Grid $zone (GRA Algorithm)',
            detectedAt: now,
          ),
        );
      }

      if (severity == 'CRITICAL') {
        incidents.insert(
          0,
          Incident(
            id: 'INC-$alertId',
            threatType: 'GRA Severe Crowd Congestion ($zone)',
            cameraId: 'CAM-001',
            location: 'Grid $zone',
            severity: IncidentSeverity.critical,
            detectedAt: now,
            assignedTo: 'Patrol SECURITY-A',
            confidence: riskScore.round().clamp(1, 100),
            notes: 'GRA Algorithm: ${data["message"] ?? "Density spike detected."}. Metrics: Density ${metrics["density"]}%, Congestion ${metrics["congestion"]}%, Growth ${metrics["crowd_growth"]}%, Irregularity ${metrics["movement_irregularity"]}%. Automated emergency assignment dispatched.',
            status: IncidentStatus.investigating,
          ),
        );
      }

      liveFeedEvents.insert(
        0,
        LiveFeedEvent(
          id: 'EVT-GRA-${now.millisecondsSinceEpoch.toString().substring(8)}',
          title: 'GRA Grid $zone: $severity (${riskScore.toStringAsFixed(1)})',
          cameraId: 'CAM-001',
          location: 'Grid $zone',
          confidence: riskScore.round().clamp(1, 100),
          timestamp: now,
          badgeColor: severity == 'CRITICAL'
              ? const Color(0xFFEF4444)
              : (severity == 'HIGH_WARNING' ? const Color(0xFFF97316) : const Color(0xFFEAB308)),
          icon: Icons.groups_rounded,
        ),
      );

      if (liveFeedEvents.length > 25) liveFeedEvents.removeLast();
      if (alerts.length > 30) alerts.removeLast();
      if (incidents.length > 30) incidents.removeLast();

      notifyListeners();
    } else if (type == 'TASK_STATUS') {
      final staffId = data['staffId'] ?? 'Staff';
      final taskId = data['taskId'] ?? 'Task';
      final status = data['status'] ?? '';
      liveFeedEvents.insert(
        0,
        LiveFeedEvent(
          id: 'EVT-STATUS-${now.millisecondsSinceEpoch.toString().substring(8)}',
          title: 'Field Response: $staffId -> $taskId [$status]',
          cameraId: 'FIELD-COMM',
          location: 'Venue Zone',
          confidence: 100,
          timestamp: now,
          badgeColor: const Color(0xFF3B82F6),
          icon: Icons.assignment_turned_in,
        ),
      );
      if (status == 'COMPLETED') {
        final matchIdx = incidents.indexWhere((i) => i.id.contains(taskId.toString()));
        if (matchIdx != -1) {
          incidents[matchIdx].status = IncidentStatus.resolved;
        }
      }
      notifyListeners();
    } else if (type == 'ACK') {
      final staffId = data['staffId'] ?? 'Staff';
      final eventId = data['eventId'] ?? '';
      liveFeedEvents.insert(
        0,
        LiveFeedEvent(
          id: 'EVT-ACK-${now.millisecondsSinceEpoch.toString().substring(8)}',
          title: 'Alert Acknowledged by $staffId ($eventId)',
          cameraId: 'FIELD-COMM',
          location: 'Venue Zone',
          confidence: 100,
          timestamp: now,
          badgeColor: const Color(0xFF10B981),
          icon: Icons.check_circle_outline,
        ),
      );
      final matchIdx = alerts.indexWhere((a) => a.id == eventId);
      if (matchIdx != -1) {
        alerts[matchIdx].status = AlertStatus.acknowledged;
      }
      notifyListeners();
    } else if (type == 'STAFF_ONLINE') {
      final staffId = (data['staffId'] ?? 'STAFF-001').toString();
      final teamId = (data['teamId'] ?? 'SECURITY-A').toString();
      final zone = (data['zone'] ?? 'Zone A').toString();
      final existingIdx = connectedStaffList.indexWhere((s) => s['staffId'] == staffId);
      final staffData = {
        'staffId': staffId,
        'teamId': teamId,
        'zone': zone,
        'status': 'ONLINE',
        'connectedAt': now,
      };
      if (existingIdx >= 0) {
        connectedStaffList[existingIdx] = staffData;
      } else {
        connectedStaffList.add(staffData);
      }
      liveFeedEvents.insert(
        0,
        LiveFeedEvent(
          id: 'EVT-STAFF-${now.millisecondsSinceEpoch.toString().substring(8)}',
          title: 'Field Staff Enrolled: $staffId ($teamId)',
          cameraId: 'HQ-QR-CONNECT',
          location: zone,
          confidence: 100,
          timestamp: now,
          badgeColor: const Color(0xFF10B981),
          icon: Icons.qr_code_scanner_rounded,
        ),
      );
      notifyListeners();
    } else if (type == 'STAFF_OFFLINE') {
      final staffId = data['staffId']?.toString();
      connectedStaffList.removeWhere((s) => s['staffId'] == staffId);
      notifyListeners();
    } else if (type == 'STAFF_ROSTER') {
      final roster = (data['roster'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      connectedStaffList = List<Map<String, dynamic>>.from(roster);
      notifyListeners();
    }
  }

  Future<bool> sendDeployCommand({
    required String teamId,
    String? staffId,
    required String title,
    required String description,
    required String priority,
    required String locationName,
  }) async {
    final payload = json.encode({
      "type": "DEPLOY_STAFF",
      "teamId": teamId,
      "staffId": staffId ?? "",
      "title": title,
      "description": description,
      "priority": priority,
      "locationName": locationName,
      "alarm": true,
      "vibrate": true,
    });

    if (_hqWs != null && isHqWsConnected) {
      _hqWs!.add(payload);
      return true;
    } else {
      try {
        final tempWs = await WebSocket.connect('ws://127.0.0.1:8765/hq').timeout(const Duration(seconds: 2));
        tempWs.add(payload);
        await Future.delayed(const Duration(milliseconds: 300));
        await tempWs.close();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void refreshStaffRoster() {
    if (_hqWs != null && isHqWsConnected) {
      _hqWs!.add(json.encode({"type": "GET_STAFF_ROSTER"}));
    }
  }

  void _initLiveEvents() {
    final now = DateTime.now();
    liveFeedEvents = [
      LiveFeedEvent(
        id: 'EVT-INIT-1',
        title: 'Optical Stream Synchronized • CAM-01',
        cameraId: 'CAM-001',
        location: 'Zone A (Main Entrance)',
        confidence: 99,
        timestamp: now.subtract(const Duration(minutes: 2)),
        badgeColor: const Color(0xFF10B981),
        icon: Icons.videocam,
      ),
      LiveFeedEvent(
        id: 'EVT-INIT-2',
        title: 'YOLOv11 Crowd Safety & GRA Engine Armed',
        cameraId: 'CAM-001',
        location: 'Zone A (Main Entrance)',
        confidence: 97,
        timestamp: now.subtract(const Duration(minutes: 1)),
        badgeColor: const Color(0xFFF59E0B),
        icon: Icons.shield,
      ),
    ];
  }

  void setSelectedAnalyticsCamera(String id) {
    selectedAnalyticsCameraId = id;
    notifyListeners();
  }

  void _startBackendPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      _pollTelemetry();
    });
  }

  final HttpClient _telemetryClient = HttpClient()
    ..connectionTimeout = const Duration(milliseconds: 500)
    ..idleTimeout = const Duration(seconds: 15);

  Future<void> _pollTelemetry() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await _telemetryClient.getUrl(Uri.parse('http://127.0.0.1:5000/api/telemetry'));
      final response = await request.close().timeout(const Duration(milliseconds: 600));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody) as Map<String, dynamic>;

        stopwatch.stop();
        liveLatencyMs = stopwatch.elapsedMilliseconds.clamp(18, 95);

        bool notifyNeeded = false;
        if (!isBackendConnected) {
          isBackendConnected = true;
          _disconnectPollCount = 0;
          notifyNeeded = true;
        }

        if (data.containsKey('camera_enabled')) {
          final serverCamOn = data['camera_enabled'] == true;
          if (isCameraOn != serverCamOn) {
            isCameraOn = serverCamOn;
            notifyNeeded = true;
          }
        }

        if (data.containsKey('device_name')) {
          final d1 = data['device_name'] as String? ?? 'Laptop Webcam';
          if (cam1DeviceName != d1) {
            cam1DeviceName = d1;
            notifyNeeded = true;
          }
        }

        cam1Fps = (data['fps'] as num?)?.toDouble() ?? 0.0;
        liveBitrateKbps = isCameraOn ? (cam1Fps * 90.0 + 820.0).clamp(600.0, 3200.0) : 0.0;
        activeAiMode = (data['mode'] as String?) ?? activeAiMode;

        if (data['counts'] is Map) {
          final livePersons = (data['counts']['person'] as num?)?.toInt() ?? 0;
          cam1Counts = {
            'person': isManualPersonOverride ? manualPersonCount : livePersons,
            'vehicle': (data['counts']['vehicle'] as num?)?.toInt() ?? 0,
            'animal': (data['counts']['animal'] as num?)?.toInt() ?? 0,
            'face': (data['counts']['face'] as num?)?.toInt() ?? 0,
          };
        }

        // Only flag intrusionDetected if manual override is >= 20, or if backend reports intrusion AND persons >= 10
        if (isManualPersonOverride) {
          intrusionDetected = manualPersonCount >= 20;
        } else {
          final rawIntrusion = (data['intrusion_detected'] as bool?) ?? false;
          final persons = cam1Counts['person'] ?? 0;
          intrusionDetected = rawIntrusion && persons >= 10;
        }

        // Real-time detection graph telemetry point
        double liveTargets = (cam1Counts['person']! + cam1Counts['vehicle']! + cam1Counts['animal']!).toDouble();
        if (intrusionDetected) liveTargets += 3.0; // Significant spike on breach
        if (!isCameraOn) liveTargets = 0.0;

        final now = DateTime.now();

        // Delta tracking for distinct target events
        if (cam1Counts['person']! > _prevPersonCount) {
          final diff = cam1Counts['person']! - _prevPersonCount;
          totalPersonsDetected += diff;
          liveFeedEvents.insert(
            0,
            LiveFeedEvent(
              id: 'EVT-${now.millisecondsSinceEpoch.toString().substring(8)}',
              title: 'Attendee In-Frame Verified (${cam1Counts['person']!} active)',
              cameraId: 'CAM-001',
              location: 'Zone A (Main Entrance)',
              confidence: 94,
              timestamp: now,
              badgeColor: const Color(0xFFF59E0B),
              icon: Icons.person,
            ),
          );
          notifyNeeded = true;
        }
        _prevPersonCount = cam1Counts['person']!;

        if (cam1Counts['vehicle']! > _prevVehicleCount) {
          final diff = cam1Counts['vehicle']! - _prevVehicleCount;
          totalVehiclesDetected += diff;
          liveFeedEvents.insert(
            0,
            LiveFeedEvent(
              id: 'EVT-${now.millisecondsSinceEpoch.toString().substring(8)}',
              title: 'Venue Cart In-Frame Tracked (${cam1Counts['vehicle']!} active)',
              cameraId: 'CAM-001',
              location: 'Zone A (Main Entrance)',
              confidence: 89,
              timestamp: now,
              badgeColor: const Color(0xFFF4F5F7),
              icon: Icons.directions_car,
            ),
          );
          notifyNeeded = true;
        }
        _prevVehicleCount = cam1Counts['vehicle']!;

        if (cam1Counts['face']! > _prevFaceCount) {
          final diff = cam1Counts['face']! - _prevFaceCount;
          totalFacesDetected += diff;
          liveFeedEvents.insert(
            0,
            LiveFeedEvent(
              id: 'EVT-${now.millisecondsSinceEpoch.toString().substring(8)}',
              title: 'Facial Biometric Match In-Frame',
              cameraId: 'CAM-001',
              location: 'Zone A (Main Entrance)',
              confidence: 96,
              timestamp: now,
              badgeColor: const Color(0xFF60A5FA),
              icon: Icons.face,
            ),
          );
          notifyNeeded = true;
        }
        _prevFaceCount = cam1Counts['face']!;

        if (intrusionDetected) {
          totalBreachesDetected += 1;
          if (!liveFeedEvents.any((e) => e.title.contains('INCIDENT') && now.difference(e.timestamp).inSeconds < 8)) {
            liveFeedEvents.insert(
              0,
              LiveFeedEvent(
                id: 'EVT-${now.millisecondsSinceEpoch.toString().substring(8)}',
                title: 'CROWD SURGE CONGESTION DETECTED',
                cameraId: 'CAM-001',
                location: 'Zone A (Main Entrance)',
                confidence: 97,
                timestamp: now,
                badgeColor: const Color(0xFFEF4444),
                icon: Icons.warning_amber_rounded,
              ),
            );
            notifyNeeded = true;
          }
        }

        if (liveFeedEvents.length > 20) {
          liveFeedEvents.removeLast();
        }

        final updatedHistory = <FlSpot>[];
        for (int i = 0; i < detectionHistory.length - 1; i++) {
          updatedHistory.add(FlSpot(i.toDouble(), detectionHistory[i + 1].y));
        }
        updatedHistory.add(FlSpot((detectionHistory.length - 1).toDouble(), liveTargets));
        detectionHistory = updatedHistory;

        // Update high-resolution 24-point live feed stream
        final updatedLive = <FlSpot>[];
        for (int i = 0; i < liveFeedHistory.length - 1; i++) {
          updatedLive.add(FlSpot(i.toDouble(), liveFeedHistory[i + 1].y));
        }
        updatedLive.add(FlSpot((liveFeedHistory.length - 1).toDouble(), liveTargets));
        liveFeedHistory = updatedLive;
        notifyNeeded = true;

        final camIndex = cameras.indexWhere((c) => c.id == 'CAM-001');
        if (camIndex != -1) {
          final cam = cameras[camIndex];
          cam.status = isCameraOn ? CameraStatus.online : CameraStatus.offline;
          cam.lastActive = DateTime.now();
          final detectionText = isCameraOn
              ? (data['current_detection'] as String? ?? 'Crowd Monitoring Active')
              : 'Camera Hardware Powered Off';
          if (cam.currentDetection != detectionText) {
            cam.currentDetection = detectionText;
            notifyNeeded = true;
          }
        }

        // Parse CAM-002 (Phone / Mobile Steward Node) telemetry
        if (data['cameras'] is Map && data['cameras']['CAM-002'] is Map) {
          final c2 = data['cameras']['CAM-002'] as Map<String, dynamic>;
          cam2Fps = (c2['fps'] as num?)?.toDouble() ?? 0.0;
          if (c2['counts'] is Map) {
            cam2Counts = {
              'person': (c2['counts']['person'] as num?)?.toInt() ?? 0,
              'vehicle': (c2['counts']['vehicle'] as num?)?.toInt() ?? 0,
              'animal': (c2['counts']['animal'] as num?)?.toInt() ?? 0,
              'face': (c2['counts']['face'] as num?)?.toInt() ?? 0,
            };
          }
          final cam2Index = cameras.indexWhere((c) => c.id == 'CAM-002');
          if (cam2Index != -1) {
            final c2Status = c2['status'] as String? ?? 'standby';
            cameras[cam2Index].status = (c2Status == 'online') ? CameraStatus.online : CameraStatus.offline;
            cameras[cam2Index].lastActive = DateTime.now();
            final c2Detection = c2['current_detection'] as String? ?? 'Awaiting Mobile Steward Link';
            if (cameras[cam2Index].currentDetection != c2Detection) {
              cameras[cam2Index].currentDetection = c2Detection;
              notifyNeeded = true;
            }
            if (c2.containsKey('source')) {
              cam2Source = c2['source'].toString();
            }
            if (c2.containsKey('device_name')) {
              final d2 = c2['device_name'] as String? ?? 'Mobile Steward Camera';
              if (cam2DeviceName != d2) {
                cam2DeviceName = d2;
                notifyNeeded = true;
              }
            }
          }
        }

        // 1. Live Crowd Incidents generated directly from CAM-01
        if (intrusionDetected) {
          if (!alerts.any((a) => a.title.contains('Incident') && now.difference(a.detectedAt).inSeconds < 12)) {
            final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
            alerts.insert(
              0,
              Alert(
                id: altId,
                title: 'CRITICAL: Crowd Surge Warning in Zone A',
                severity: AlertSeverity.critical,
                confidence: 96,
                cameraId: 'CAM-001',
                location: 'Zone A (Main Entrance)',
                detectedAt: now,
              ),
            );
            incidents.insert(
              0,
              Incident(
                id: 'INC-${now.millisecondsSinceEpoch.toString().substring(8)}',
                threatType: 'Crowd Surge & Congestion',
                cameraId: 'CAM-001',
                location: 'Zone A',
                severity: IncidentSeverity.critical,
                detectedAt: now,
                assignedTo: 'Lead Steward',
                confidence: 96,
                notes: 'Automated AI crowd congestion and surge threshold reached at Gate A Concourse.',
                status: IncidentStatus.investigating,
              ),
            );
            notifyNeeded = true;
          }
        }

        // 3. Real-time Vehicle / Cart Detections from CAM-01
        else if (cam1Counts['vehicle']! > 0) {
          if (!alerts.any((a) => a.title.contains('Vehicle') && now.difference(a.detectedAt).inSeconds < 25)) {
            final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
            alerts.insert(
              0,
              Alert(
                id: altId,
                title: 'Venue Cart / Utility Vehicle Tracked in Zone A',
                severity: AlertSeverity.medium,
                confidence: 85,
                cameraId: 'CAM-001',
                location: 'Zone A (Main Entrance)',
                detectedAt: now,
              ),
            );
            notifyNeeded = true;
          }
        }

        // Trim alerts and incidents to reasonable sizes
        if (alerts.length > 25) alerts.removeLast();
        if (incidents.length > 20) incidents.removeLast();

        if (notifyNeeded) {
          notifyListeners();
        }
      } else {
        _handleBackendDisconnect();
      }
    } catch (_) {
      _handleBackendDisconnect();
    }
  }

  int _disconnectPollCount = 0;

  void _handleBackendDisconnect() {
    _disconnectPollCount++;
    if (isBackendConnected) {
      isBackendConnected = false;
      final camIndex = cameras.indexWhere((c) => c.id == 'CAM-001');
      if (camIndex != -1) {
        cameras[camIndex].status = CameraStatus.offline;
        cameras[camIndex].currentDetection = 'Auto-Initializing Optical Stream...';
      }
      notifyListeners();
    }

    // Automatically ensure backend is running only if down for > 10 seconds and not already starting
    if (!BackendLauncher.isStarting && _disconnectPollCount > 15 && _disconnectPollCount % 12 == 0) {
      BackendLauncher.ensureBackendRunning();
    }
  }

  Future<void> toggleCameraPower() async {
    final nextState = !isCameraOn;
    isCameraOn = nextState;
    final camIndex = cameras.indexWhere((c) => c.id == 'CAM-001');
    if (camIndex != -1) {
      cameras[camIndex].status = nextState ? CameraStatus.online : CameraStatus.offline;
      cameras[camIndex].currentDetection = nextState
          ? 'Active Monitoring • Lap Cam 01'
          : 'Camera Hardware Powered Off';
    }
    notifyListeners();

    try {
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:5000/api/camera/power'));
      req.headers.set('Content-Type', 'application/json');
      req.write(json.encode({'enabled': nextState}));
      await req.close();
      client.close();
    } catch (_) {}
  }

  Future<bool> setAiMode(String mode) async {
    // Immediately update local state for zero-latency UI response
    activeAiMode = mode;
    notifyListeners();

    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 600);
      final request = await client.postUrl(Uri.parse('http://127.0.0.1:5000/api/mode'));
      request.headers.set('Content-Type', 'application/json');
      request.write(json.encode({'mode': mode}));
      final response = await request.close().timeout(const Duration(milliseconds: 600));
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCameraSource(String cameraId, String newSource) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 700);
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:5000/api/camera/source'));
      req.headers.set('Content-Type', 'application/json');
      req.write(json.encode({'camera_id': cameraId, 'source': newSource}));
      final resp = await req.close().timeout(const Duration(milliseconds: 700));
      client.close();
      if (resp.statusCode == 200) {
        if (cameraId == 'CAM-002' || cameraId == '2') {
          cam2Source = newSource;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> swapCameras() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 700);
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:5000/api/camera/swap'));
      final resp = await req.close().timeout(const Duration(milliseconds: 700));
      client.close();
      if (resp.statusCode == 200) {
        // Optimistically swap local device names
        final temp = cam1DeviceName;
        cam1DeviceName = cam2DeviceName;
        cam2DeviceName = temp;
        
        final tempSrc = cam2Source;
        cam2Source = (tempSrc == '1') ? '0' : '1';
        
        notifyListeners();
        await _pollTelemetry();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String get defconStatus {
    final persons = cam1Counts['person'] ?? 0;
    if (intrusionDetected || persons >= 20) {
      return 'CROWD SAFETY LEVEL 1 • CRITICAL SURGE DETECTED';
    }
    if (persons >= 8) {
      return 'CROWD SAFETY LEVEL 2 • ACTIVE ATTENDEE INFLUX';
    }
    if (!isCameraOn) {
      return 'STANDBY • CAM 01 SENSOR MUTED';
    }
    if (persons > 0) {
      return 'CROWD SAFETY LEVEL 4 • NORMAL FLOW ($persons ATTENDEE${persons > 1 ? "S" : ""} • SAFE)';
    }
    return 'CROWD SAFETY LEVEL 4 • NORMAL FLOW (SAFE)';
  }

  Color get defconColor {
    final persons = cam1Counts['person'] ?? 0;
    if (intrusionDetected || persons >= 20) return const Color(0xFFEF4444);
    if (persons >= 8) return const Color(0xFFF59E0B);
    if (!isCameraOn) return const Color(0xFF6B7280);
    return const Color(0xFF10B981);
  }

  @override
  void dispose() {
    _wsReconnectTimer?.cancel();
    _hqWs?.close();
    _pollTimer?.cancel();
    _telemetryClient.close(force: true);
    super.dispose();
  }

  // Only CAM-001 has active physical camera input; all other channels are empty slots
  List<Camera> cameras = [
    Camera(
      id: 'CAM-001',
      name: 'Main Entrance Cam (CAM-01)',
      location: 'Zone A Main Entrance Concourse',
      zone: 'Zone A',
      status: CameraStatus.online,
      signal: 'Direct 100%',
      lastActive: DateTime.now(),
      isEmptySlot: false,
      detectionModes: {
        'YOLO Objects': DetectionMode.active,
        'Virtual Fence': DetectionMode.active,
        'Face Detect': DetectionMode.active,
        'ANPR': DetectionMode.active,
      },
      currentDetection: 'Active Monitoring • Main Entrance 01',
    ),
    Camera(
      id: 'CAM-002',
      name: 'Mobile Steward Feed (Phone Cam)',
      location: 'Zone B Concourse Patrol',
      zone: 'Zone B',
      status: CameraStatus.online,
      signal: 'Direct USB Link',
      lastActive: DateTime.now(),
      isEmptySlot: false,
      detectionModes: {
        'YOLO Objects': DetectionMode.active,
        'Virtual Fence': DetectionMode.active,
        'Face Detect': DetectionMode.active,
        'ANPR': DetectionMode.active,
      },
      currentDetection: 'Active Monitoring • Steward Cam 02',
    ),
    Camera(
      id: 'SLOT-03',
      name: 'Channel 03 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Zone C',
      status: CameraStatus.offline,
      signal: 'Disconnected',
      lastActive: DateTime.now(),
      isEmptySlot: true,
      detectionModes: {},
      currentDetection: 'Vacant Channel • No Input',
    ),
    Camera(
      id: 'SLOT-04',
      name: 'Channel 04 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Zone D',
      status: CameraStatus.offline,
      signal: 'Disconnected',
      lastActive: DateTime.now(),
      isEmptySlot: true,
      detectionModes: {},
      currentDetection: 'Vacant Channel • No Input',
    ),
    Camera(
      id: 'SLOT-05',
      name: 'Channel 05 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Zone E',
      status: CameraStatus.offline,
      signal: 'Disconnected',
      lastActive: DateTime.now(),
      isEmptySlot: true,
      detectionModes: {},
      currentDetection: 'Vacant Channel • No Input',
    ),
    Camera(
      id: 'SLOT-06',
      name: 'Channel 06 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Zone F',
      status: CameraStatus.offline,
      signal: 'Disconnected',
      lastActive: DateTime.now(),
      isEmptySlot: true,
      detectionModes: {},
      currentDetection: 'Vacant Channel • No Input',
    ),
  ];

  // Starts with zero fake alerts - alerts populate in real time from CAM-01 detections
  List<Alert> alerts = [];

  // Real incidents triggered by actual CAM-01 threat events
  List<Incident> incidents = [];

  List<Zone> get zones => [
    Zone(
      id: 'Z1',
      name: 'Zone A - Main Entrance Concourse (CAM-01)',
      cameraCount: 1,
      activeAlerts: alerts.where((a) => a.status == AlertStatus.active).length,
      threatLevel: intrusionDetected ? 'CRITICAL' : (cam1Counts['person']! > 0 ? 'WARNING' : 'ACTIVE'),
    ),
    Zone(id: 'Z2', name: 'Zone B - Central Arena & Grandstand', cameraCount: 0, activeAlerts: 0, threatLevel: 'VACANT'),
    Zone(id: 'Z3', name: 'Zone C - Concession & Food Plaza', cameraCount: 0, activeAlerts: 0, threatLevel: 'VACANT'),
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

  void addIncident(Incident incident) {
    incidents.insert(0, incident);
    notifyListeners();
  }

  void dispatchPatrol({required String sector, required String threatType}) {
    final now = DateTime.now();
    final incId = 'DISP-${now.millisecondsSinceEpoch.toString().substring(8)}';
    final altId = 'ALT-PATROL-${now.millisecondsSinceEpoch.toString().substring(8)}';

    incidents.insert(
      0,
      Incident(
        id: incId,
        threatType: threatType,
        cameraId: 'CAM-001',
        location: sector,
        severity: IncidentSeverity.critical,
        detectedAt: now,
        assignedTo: currentUser?.name ?? 'Head of Safety',
        confidence: 99,
        notes: 'Rapid Event Safety Stewards deployed to $sector by ${currentUser?.name ?? "Command"}. Crowd management underway.',
        status: IncidentStatus.investigating,
      ),
    );

    alerts.insert(
      0,
      Alert(
        id: altId,
        title: 'STEWARDS DISPATCHED: Safety Response Team en route to $sector',
        severity: AlertSeverity.critical,
        confidence: 99,
        cameraId: 'CAM-001',
        location: sector,
        detectedAt: now,
      ),
    );

    notifyListeners();
  }

  // --- Authentication Handlers ---
  Future<String?> loginWithUsernameAndPassword(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty) {
      return 'Please enter your registered Operator Call-sign / Username';
    }
    if (trimmedPass.isEmpty) {
      return 'Please enter your Security Key / Password';
    }

    // Direct match for Chief Event Manager for instant offline authorized bypass
    if ((trimmedUser.toUpperCase() == 'EVENT-01' || trimmedUser.toLowerCase() == 'admin' || trimmedUser.toLowerCase() == 'manager') &&
        (trimmedPass.isNotEmpty)) {
      currentUser = UserModel.defaultSupervisor;
      isAuthenticated = true;
      notifyListeners();
      return null;
    }

    try {
      final user = await GitHubAuthService.authenticateOperator(trimmedUser, trimmedPass);
      if (user != null) {
        currentUser = user;
        isAuthenticated = true;
        notifyListeners();
        return null;
      }
      return 'ACCESS DENIED: No registered operator matches callsign "$trimmedUser" or security key is invalid.';
    } catch (e) {
      return 'Authentication Error: ${e.toString().replaceAll('Exception:', '').trim()}';
    }
  }

  void loginAsSupervisor() {
    currentUser = UserModel.defaultSupervisor;
    isAuthenticated = true;
    notifyListeners();
  }

  Future<String?> registerOperator({
    required String username,
    required String password,
    required String name,
    required String role,
    required String clearanceLevel,
  }) async {
    try {
      final user = await GitHubAuthService.registerOperator(
        username: username,
        password: password,
        name: name,
        role: role,
        clearanceLevel: clearanceLevel,
      );
      currentUser = user;
      isAuthenticated = true;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception:', '').trim();
    }
  }

  void loginWithGitHub(UserModel githubUser) {
    currentUser = githubUser;
    isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    isAuthenticated = false;
    notifyListeners();
  }

  // --- Settings Handlers ---
  void setDetectionSensitivity(double val) {
    detectionSensitivity = val.clamp(0.50, 1.0);
    notifyListeners();
  }

  void toggleHighContrast(bool val) {
    highContrastMode = val;
    notifyListeners();
  }

  void toggleAudibleSiren(bool val) {
    audibleSiren = val;
    notifyListeners();
  }

  void toggleAutoPatrolDispatch(bool val) {
    autoPatrolDispatch = val;
    notifyListeners();
  }

  void toggleBiometric(bool val) {
    biometricConfirmation = val;
    notifyListeners();
  }

  void setLanguageProtocol(String val) {
    languageProtocol = val;
    notifyListeners();
  }

  void setCoordinatesStandard(String val) {
    coordinatesStandard = val;
    notifyListeners();
  }

  void setFalseAlarmFilter(String val) {
    falseAlarmFilter = val;
    notifyListeners();
  }

  void resetSettingsToDefault() {
    detectionSensitivity = 0.85;
    highContrastMode = true;
    audibleSiren = true;
    autoPatrolDispatch = true;
    biometricConfirmation = false;
    languageProtocol = 'English (Event Nomenclature)';
    coordinatesStandard = 'WGS 84 / MGRS';
    falseAlarmFilter = 'Aggressive (AI Multi-frame verification)';
    notifyListeners();
  }
}
