import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../models/incident.dart';
import '../models/zone.dart';
import '../models/user_model.dart';

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
  String activeAiMode = "all";
  Map<String, int> cam1Counts = {'person': 0, 'vehicle': 0, 'animal': 0, 'face': 0};
  bool intrusionDetected = false;

  // Live Stream Performance Metrics
  double liveBitrateKbps = 1450.0;
  int liveLatencyMs = 32;
  String selectedAnalyticsCameraId = 'CAM-001';
  List<LiveFeedEvent> liveFeedEvents = [];

  int _prevPersonCount = 0;
  int _prevVehicleCount = 0;
  int _prevFaceCount = 0;

  // Authentication State
  UserModel? currentUser = UserModel.commanderAlpha;
  bool isAuthenticated = true;

  // System Configuration & Preferences State
  double detectionSensitivity = 0.85;
  bool highContrastMode = true;
  bool audibleSiren = true;
  bool autoPatrolDispatch = true;
  bool biometricConfirmation = false;
  String languageProtocol = 'English (Military Nomenclature)';
  String coordinatesStandard = 'WGS 84 / MGRS';
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

  MockState() {
    _initLiveEvents();
    _startBackendPolling();
  }

  void _initLiveEvents() {
    final now = DateTime.now();
    liveFeedEvents = [
      LiveFeedEvent(
        id: 'EVT-INIT-1',
        title: 'Optical Stream Synchronized • CAM-01',
        cameraId: 'CAM-001',
        location: 'Sector 01 (Laptop Cam)',
        confidence: 99,
        timestamp: now.subtract(const Duration(minutes: 2)),
        badgeColor: const Color(0xFF10B981),
        icon: Icons.videocam,
      ),
      LiveFeedEvent(
        id: 'EVT-INIT-2',
        title: 'YOLOv11 Perimeter Neural Engine Armed',
        cameraId: 'CAM-001',
        location: 'Sector 01 (Laptop Cam)',
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

  Future<void> _pollTelemetry() async {
    final stopwatch = Stopwatch()..start();
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 600);
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:5000/api/telemetry'));
      final response = await request.close().timeout(const Duration(milliseconds: 600));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody) as Map<String, dynamic>;

        stopwatch.stop();
        liveLatencyMs = stopwatch.elapsedMilliseconds.clamp(18, 95);

        bool notifyNeeded = false;
        if (!isBackendConnected) {
          isBackendConnected = true;
          notifyNeeded = true;
        }

        if (data.containsKey('camera_enabled')) {
          final serverCamOn = data['camera_enabled'] == true;
          if (isCameraOn != serverCamOn) {
            isCameraOn = serverCamOn;
            notifyNeeded = true;
          }
        }

        cam1Fps = (data['fps'] as num?)?.toDouble() ?? 0.0;
        liveBitrateKbps = isCameraOn ? (cam1Fps * 90.0 + 820.0).clamp(600.0, 3200.0) : 0.0;
        activeAiMode = (data['mode'] as String?) ?? activeAiMode;
        intrusionDetected = (data['intrusion_detected'] as bool?) ?? false;

        if (data['counts'] is Map) {
          cam1Counts = {
            'person': (data['counts']['person'] as num?)?.toInt() ?? 0,
            'vehicle': (data['counts']['vehicle'] as num?)?.toInt() ?? 0,
            'animal': (data['counts']['animal'] as num?)?.toInt() ?? 0,
            'face': (data['counts']['face'] as num?)?.toInt() ?? 0,
          };
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
              title: 'Human In-Frame Verified (${cam1Counts['person']!} active)',
              cameraId: 'CAM-001',
              location: 'Sector 01 (Laptop Cam)',
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
              title: 'Vehicle In-Frame Tracked (${cam1Counts['vehicle']!} active)',
              cameraId: 'CAM-001',
              location: 'Sector 01 (Laptop Cam)',
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
              location: 'Sector 01 (Laptop Cam)',
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
          if (!liveFeedEvents.any((e) => e.title.contains('INTRUSION') && now.difference(e.timestamp).inSeconds < 8)) {
            liveFeedEvents.insert(
              0,
              LiveFeedEvent(
                id: 'EVT-${now.millisecondsSinceEpoch.toString().substring(8)}',
                title: 'RESTRICTED PERIMETER INTRUSION BREACH',
                cameraId: 'CAM-001',
                location: 'Sector 01 (Laptop Cam)',
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
              ? (data['current_detection'] as String? ?? 'Active Monitoring')
              : 'Camera Hardware Powered Off';
          if (cam.currentDetection != detectionText) {
            cam.currentDetection = detectionText;
            notifyNeeded = true;
          }
        }

        // 1. Live Intrusion Breaches generated directly from CAM-01
        if (intrusionDetected) {
          if (!alerts.any((a) => a.title.contains('Intrusion') && now.difference(a.detectedAt).inSeconds < 12)) {
            final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
            alerts.insert(
              0,
              Alert(
                id: altId,
                title: 'CRITICAL: Perimeter Fence Intrusion in Sector 01',
                severity: AlertSeverity.critical,
                confidence: 96,
                cameraId: 'CAM-001',
                location: 'Sector 01 (Laptop Cam)',
                detectedAt: now,
              ),
            );
            incidents.insert(
              0,
              Incident(
                id: 'INC-${now.millisecondsSinceEpoch.toString().substring(8)}',
                threatType: 'Perimeter Intrusion Breach',
                cameraId: 'CAM-001',
                location: 'Sector 01',
                severity: IncidentSeverity.critical,
                detectedAt: now,
                assignedTo: 'Active Operator',
                confidence: 96,
                notes: 'Automated AI restricted perimeter breach detected by CAM-01',
                status: IncidentStatus.investigating,
              ),
            );
            notifyNeeded = true;
          }
        }

        // 2. Real-time Human Detections from CAM-01
        else if (cam1Counts['person']! > 0) {
          if (!alerts.any((a) => a.title.contains('Person') && now.difference(a.detectedAt).inSeconds < 25)) {
            final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
            alerts.insert(
              0,
              Alert(
                id: altId,
                title: 'Unauthorized Person Tracked in Sector 01',
                severity: AlertSeverity.high,
                confidence: 91,
                cameraId: 'CAM-001',
                location: 'Sector 01 (Laptop Cam)',
                detectedAt: now,
              ),
            );
            notifyNeeded = true;
          }
        }

        // 3. Real-time Vehicle Detections from CAM-01
        else if (cam1Counts['vehicle']! > 0) {
          if (!alerts.any((a) => a.title.contains('Vehicle') && now.difference(a.detectedAt).inSeconds < 25)) {
            final altId = 'ALT-${now.millisecondsSinceEpoch.toString().substring(8)}';
            alerts.insert(
              0,
              Alert(
                id: altId,
                title: 'Vehicle Detected in Sector 01',
                severity: AlertSeverity.medium,
                confidence: 85,
                cameraId: 'CAM-001',
                location: 'Sector 01 (Laptop Cam)',
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
      client.close();
    } catch (_) {
      _handleBackendDisconnect();
    }
  }

  void _handleBackendDisconnect() {
    if (isBackendConnected) {
      isBackendConnected = false;
      final camIndex = cameras.indexWhere((c) => c.id == 'CAM-001');
      if (camIndex != -1) {
        cameras[camIndex].status = CameraStatus.offline;
        cameras[camIndex].currentDetection = 'Offline (Start backend_server.py)';
      }
      notifyListeners();
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
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('http://127.0.0.1:5000/api/mode'));
      request.headers.set('Content-Type', 'application/json');
      request.write(json.encode({'mode': mode}));
      final response = await request.close();
      client.close();
      if (response.statusCode == 200) {
        activeAiMode = mode;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  String get defconStatus {
    if (intrusionDetected) {
      return 'DEFCON 1 • INTRUSION BREACH DETECTED';
    }
    final persons = cam1Counts['person'] ?? 0;
    final vehicles = cam1Counts['vehicle'] ?? 0;
    if (persons > 0 || vehicles > 0) {
      return 'DEFCON 3 • TARGET ACTIVITY IDENTIFIED';
    }
    if (!isCameraOn) {
      return 'STANDBY • CAM 01 HARDWARE MUTED';
    }
    return 'DEFCON 4 • NORMAL VIGILANCE';
  }

  Color get defconColor {
    if (intrusionDetected) return const Color(0xFFEF4444);
    final persons = cam1Counts['person'] ?? 0;
    final vehicles = cam1Counts['vehicle'] ?? 0;
    if (persons > 0 || vehicles > 0) return const Color(0xFFF59E0B);
    if (!isCameraOn) return const Color(0xFF6B7280);
    return const Color(0xFF10B981);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Only CAM-001 has active physical camera input; all other channels are empty slots
  List<Camera> cameras = [
    Camera(
      id: 'CAM-001',
      name: 'Laptop Webcam (CAM-01)',
      location: 'Sector 01 Command Post',
      zone: 'Sector 01',
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
      currentDetection: 'Active Monitoring • Lap Cam 01',
    ),
    Camera(
      id: 'SLOT-02',
      name: 'Channel 02 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Sector 02',
      status: CameraStatus.offline,
      signal: 'Disconnected',
      lastActive: DateTime.now(),
      isEmptySlot: true,
      detectionModes: {},
      currentDetection: 'Vacant Channel • No Input',
    ),
    Camera(
      id: 'SLOT-03',
      name: 'Channel 03 [Empty]',
      location: 'No Physical Stream Assigned',
      zone: 'Sector 03',
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
      zone: 'Sector 04',
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
      zone: 'Sector 05',
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
      zone: 'Sector 06',
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
      name: 'Sector 01 - Laptop Webcam (CAM-01)',
      cameraCount: 1,
      activeAlerts: alerts.where((a) => a.status == AlertStatus.active).length,
      threatLevel: intrusionDetected ? 'CRITICAL' : (cam1Counts['person']! > 0 ? 'WARNING' : 'ACTIVE'),
    ),
    Zone(id: 'Z2', name: 'Sector 02 - East Basin', cameraCount: 0, activeAlerts: 0, threatLevel: 'VACANT'),
    Zone(id: 'Z3', name: 'Sector 03 - West Ridge', cameraCount: 0, activeAlerts: 0, threatLevel: 'VACANT'),
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
        assignedTo: currentUser?.name ?? 'Commander Alpha',
        confidence: 99,
        notes: 'Rapid Tactical Patrol deployed to $sector by ${currentUser?.name ?? "Command"}. High-alert sector sweep underway.',
        status: IncidentStatus.investigating,
      ),
    );

    alerts.insert(
      0,
      Alert(
        id: altId,
        title: 'PATROL DISPATCHED: Quick Reaction Team en route to $sector',
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
  String? loginWithUsernameAndPassword(String username, String password) {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty) {
      return 'Please enter your Operator Call-sign / Username';
    }
    if (trimmedPass.isEmpty) {
      return 'Please enter your Security Key / Password';
    }

    // Default Commander Alpha check
    if (trimmedUser.toLowerCase() == 'commander_alpha' || trimmedUser.toLowerCase() == 'arun kumar') {
      if (trimmedPass == 'password123' || trimmedPass == 'admin123' || trimmedPass == '••••••••••••') {
        currentUser = UserModel.commanderAlpha;
        isAuthenticated = true;
        notifyListeners();
        return null;
      }
      return 'Invalid Security Key for call-sign commander_alpha';
    }

    // Secondary tactical specialist check
    if (trimmedUser.toLowerCase() == 'operator_01' || trimmedUser.toLowerCase() == 'elena rostova') {
      if (trimmedPass == 'operator123' || trimmedPass == '••••••••••••') {
        currentUser = UserModel.tacticalOperator;
        isAuthenticated = true;
        notifyListeners();
        return null;
      }
      return 'Invalid Security Key for call-sign operator_01';
    }

    // Allow custom operator accounts if length >= 4
    if (trimmedPass.length < 4) {
      return 'Security Key must contain at least 4 characters';
    }

    currentUser = UserModel(
      id: 'USR-SEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: trimmedUser,
      callsign: trimmedUser.toLowerCase().replaceAll(' ', '_'),
      email: '${trimmedUser.toLowerCase().replaceAll(' ', '.')}@borderguard.mil',
      role: 'Sector Field Officer',
      clearanceLevel: 'LEVEL 3 • FIELD OPERATOR',
      avatarUrl: null,
      provider: AuthProvider.password,
    );
    isAuthenticated = true;
    notifyListeners();
    return null;
  }

  void loginWithGoogle(UserModel googleUser) {
    currentUser = googleUser;
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
    languageProtocol = 'English (Military Nomenclature)';
    coordinatesStandard = 'WGS 84 / MGRS';
    falseAlarmFilter = 'Aggressive (AI Multi-frame verification)';
    notifyListeners();
  }
}
