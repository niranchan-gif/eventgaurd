import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screens/qr_scanner_screen.dart';
import 'services/alarm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmNotificationService.initialize();
  runApp(const EventGuardStaffApp());
}

class EventGuardStaffApp extends StatelessWidget {
  const EventGuardStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventGuard Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: const Color(0xFF4F46E5),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF101524),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF121726),
          error: Color(0xFFEF4444),
        ),
      ),
      home: const SetupScreen(),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _ipController = TextEditingController(text: '192.168.0.10');
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController(text: 'EVENTGUARD_DEMO_2026');
  final _staffIdController = TextEditingController(text: 'STAFF-001');
  final _teamIdController = TextEditingController(text: 'SECURITY-A');
  final _zoneController = TextEditingController(text: 'Zone A (Main Concourse)');

  bool _showManualFields = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _staffIdController.dispose();
    _teamIdController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('hq_ip') ?? '192.168.0.10';
      _portController.text = prefs.getString('hq_port') ?? '8765';
      _tokenController.text = prefs.getString('enrollment_token') ?? 'EVENTGUARD_DEMO_2026';
      _staffIdController.text = prefs.getString('staff_id') ?? 'STAFF-001';
      _teamIdController.text = prefs.getString('team_id') ?? 'SECURITY-A';
      _zoneController.text = prefs.getString('zone') ?? 'Zone A (Main Concourse)';
    });
  }

  Future<void> _openQRScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        if (result.containsKey('hq_ip')) _ipController.text = result['hq_ip'].toString();
        if (result.containsKey('hq_port')) _portController.text = result['hq_port'].toString();
        if (result.containsKey('token')) _tokenController.text = result['token'].toString();
        if (result.containsKey('staff_id')) _staffIdController.text = result['staff_id'].toString();
        if (result.containsKey('team_id')) _teamIdController.text = result['team_id'].toString();
        if (result.containsKey('zone')) _zoneController.text = result['zone'].toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('QR Code verified for ${_staffIdController.text}! Connecting to HQ...', style: GoogleFonts.inter()),
        ),
      );

      // Auto-connect on successful scan
      await _connect();
    }
  }

  Future<void> _connect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hq_ip', _ipController.text.trim());
    await prefs.setString('hq_port', _portController.text.trim());
    await prefs.setString('enrollment_token', _tokenController.text.trim());
    await prefs.setString('staff_id', _staffIdController.text.trim());
    await prefs.setString('team_id', _teamIdController.text.trim());
    await prefs.setString('zone', _zoneController.text.trim());

    String deviceId = prefs.getString('device_id') ?? '';
    if (deviceId.isEmpty) {
      deviceId = 'EG-STAFF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await prefs.setString('device_id', deviceId);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 10),
            Text('EVENTGUARD STAFF', style: GoogleFonts.inter(letterSpacing: 0.5)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF181F33), Color(0xFF101524)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF28334E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Mobile Steward Enrollment',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pair this Android device with the EventGuard HQ Console to receive instant emergency crowd dispatches with high-priority audio alarm and vibration.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prominent QR Code Scan Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _openQRScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 28, color: Colors.white),
                label: Text(
                  'SCAN HQ DEPLOYMENT QR',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle for manual setup
            Center(
              child: TextButton.icon(
                icon: Icon(
                  _showManualFields ? Icons.expand_less : Icons.tune_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 18,
                ),
                label: Text(
                  _showManualFields ? 'Hide Manual Settings' : 'Configure IP / Call Sign Manually',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
                onPressed: () => setState(() => _showManualFields = !_showManualFields),
              ),
            ),

            if (_showManualFields) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121726),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: Column(
                  children: [
                    _buildInputField('HQ Host IP', _ipController, Icons.wifi_rounded),
                    const SizedBox(height: 12),
                    _buildInputField('WebSocket Port', _portController, Icons.tag_rounded),
                    const SizedBox(height: 12),
                    _buildInputField('Staff Call Sign', _staffIdController, Icons.person_pin_rounded),
                    const SizedBox(height: 12),
                    _buildInputField('Team ID', _teamIdController, Icons.groups_rounded),
                    const SizedBox(height: 12),
                    _buildInputField('Assigned Zone', _zoneController, Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildInputField('Enrollment Token', _tokenController, Icons.lock_outline_rounded, obscure: true),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('CONNECT MANUALLY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0C101A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E2638))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E2638))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  WebSocketChannel? _channel;
  String _connectionStatus = 'CONNECTING';
  Timer? _heartbeatTimer;
  Map<String, dynamic>? _currentTask;
  final List<Map<String, dynamic>> _alerts = [];

  late SharedPreferences _prefs;
  String _deviceId = '';
  String _staffId = '';
  String _teamId = '';
  String _zone = '';
  String _token = '';
  int _reconnectDelay = 1;
  bool _isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs.getString('device_id') ?? 'EG-STAFF-01';
    _staffId = _prefs.getString('staff_id') ?? 'STAFF-001';
    _teamId = _prefs.getString('team_id') ?? 'SECURITY-A';
    _zone = _prefs.getString('zone') ?? 'Zone A (Main Concourse)';
    _token = _prefs.getString('enrollment_token') ?? 'EVENTGUARD_DEMO_2026';
    _connect();
  }

  void _connect() {
    if (_connectionStatus == 'ONLINE') return;
    setState(() => _connectionStatus = 'CONNECTING');

    final String ip = _prefs.getString('hq_ip') ?? '192.168.0.10';
    final String port = _prefs.getString('hq_port') ?? '8765';

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port/field'));
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleMessage(data);
          } catch (_) {}
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );

      _channel!.sink.add(jsonEncode({
        'type': 'REGISTER',
        'deviceId': _deviceId,
        'unitId': _teamId,
        'staffId': _staffId,
        'teamId': _teamId,
        'zone': _zone,
        'token': _token,
        'appVersion': '2.0.0',
        'battery': 98,
      }));
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data['type'];

    if (type == 'REGISTER_ACK') {
      setState(() {
        _connectionStatus = 'ONLINE';
        _reconnectDelay = 1;
      });
      _startHeartbeat();
    } else if (type == 'ERROR') {
      setState(() => _connectionStatus = 'AUTH_FAILED');
    } else if (type == 'TASK_ASSIGNED' || type == 'DEPLOY') {
      setState(() {
        _currentTask = data;
        _currentTask!['status'] = 'ASSIGNED';
      });

      // TRIGGER FULL-SCREEN NOTIFICATION & HEAVY VIBRATION ALARM
      _triggerDeployAlarm(data);
    } else if (type == 'ALERT' || type == 'CROWD_RISK_ALERT') {
      final alertData = Map<String, dynamic>.from(data);
      if (!alertData.containsKey('eventId') && alertData.containsKey('alert_id')) {
        alertData['eventId'] = alertData['alert_id'];
      }
      setState(() {
        _alerts.insert(0, alertData);
      });

      if (alertData['severity'] == 'CRITICAL') {
        _triggerDeployAlarm({
          'title': 'CRITICAL ALERT - Grid ${alertData['grid'] ?? _zone}',
          'description': alertData['message'] ?? 'Severe crowd congestion detected.',
          'locationName': 'Grid ${alertData['grid'] ?? _zone}',
          'priority': 'CRITICAL',
        });
      }
    }
  }

  Future<void> _triggerDeployAlarm(Map<String, dynamic> taskData) async {
    final title = taskData['title']?.toString() ?? 'EMERGENCY DISPATCH';
    final desc = taskData['description']?.toString() ?? 'Immediate deployment ordered by HQ.';
    final location = taskData['locationName']?.toString() ?? _zone;

    setState(() => _isAlarmActive = true);

    // 1. Post Android Notification (sounds alarm & vibrates even if app is closed or minimized)
    await AlarmNotificationService.triggerDeployAlarm(
      title: title,
      body: '$desc (Location: $location)',
      payload: jsonEncode(taskData),
    );

    // 2. If app is foregrounded, display the high-tech emergency alarm modal
    if (mounted) {
      _showEmergencyDeployDialog(taskData);
    }
  }

  void _showEmergencyDeployDialog(Map<String, dynamic> taskData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151824),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEF4444), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CRITICAL HQ DISPATCH ALARM',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskData['title']?.toString() ?? 'Emergency Crowd Deployment',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Location: ${taskData['locationName'] ?? _zone}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEAB308)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              taskData['description']?.toString() ?? 'Proceed immediately to your assigned position.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AlarmNotificationService.stopAlarm();
              setState(() => _isAlarmActive = false);
              Navigator.pop(ctx);
            },
            child: const Text('Silence Alarm', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text(
              'ACCEPT & MOBILIZE',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            onPressed: () {
              AlarmNotificationService.stopAlarm();
              setState(() => _isAlarmActive = false);
              _updateTaskStatus('ACCEPTED');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _handleDisconnect() {
    if (!mounted) return;
    setState(() => _connectionStatus = 'RECONNECTING');
    _heartbeatTimer?.cancel();

    Future.delayed(Duration(seconds: _reconnectDelay), () {
      if (mounted && _connectionStatus != 'ONLINE') {
        _reconnectDelay = (_reconnectDelay * 2).clamp(1, 16);
        _connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_connectionStatus == 'ONLINE') {
        _channel?.sink.add(jsonEncode({
          'type': 'HEARTBEAT',
          'deviceId': _deviceId,
          'staffId': _staffId,
        }));
      }
    });
  }

  void _updateTaskStatus(String newStatus) {
    if (_currentTask == null) return;
    setState(() {
      _currentTask!['status'] = newStatus;
    });

    if (_connectionStatus == 'ONLINE') {
      _channel?.sink.add(jsonEncode({
        'type': 'TASK_STATUS',
        'taskId': _currentTask!['taskId'] ?? 'TASK-DEMO',
        'deviceId': _deviceId,
        'staffId': _staffId,
        'teamId': _teamId,
        'status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  void _acknowledgeAlert(Map<String, dynamic> alert) {
    if (_connectionStatus == 'ONLINE') {
      _channel?.sink.add(jsonEncode({
        'type': 'ACK',
        'eventId': alert['eventId'],
        'deviceId': _deviceId,
        'staffId': _staffId,
      }));
    }
    setState(() {
      alert['acknowledged'] = true;
    });
  }

  @override
  void dispose() {
    AlarmNotificationService.stopAlarm();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _connectionStatus == 'ONLINE';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_staffId • $_teamId', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(_zone, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOnline ? const Color(0xFF10B981) : Colors.redAccent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: isOnline ? const Color(0xFF10B981) : Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  _connectionStatus,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isOnline ? const Color(0xFF10B981) : Colors.redAccent),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Pair with another QR code',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SetupScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alarm banner if currently vibrating
            if (_isAlarmActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ACTIVE EMERGENCY DISPATCH ALARM',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () {
                        AlarmNotificationService.stopAlarm();
                        setState(() => _isAlarmActive = false);
                      },
                      child: const Text('SILENCE', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),

            // Active Task Section
            _buildActiveTaskCard(),
            const SizedBox(height: 20),

            // Emergency Broadcast Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF161B28),
                border: Border.all(color: const Color(0xFF242E44)),
              ),
              child: ListTile(
                leading: const Icon(Icons.campaign_rounded, color: Color(0xFFEAB308)),
                title: Text('Report Immediate Hazard', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('Broadcast crowd surge / bottleneck at your position', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB308)),
                  onPressed: () {
                    if (isOnline) {
                      _channel?.sink.add(jsonEncode({
                        'type': 'CROWD_RISK_ALERT',
                        'zone': _zone,
                        'severity': 'HIGH_WARNING',
                        'staffId': _staffId,
                        'message': 'Manual hazard report filed by $_staffId at $_zone',
                        'timestamp': DateTime.now().toIso8601String(),
                      }));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hazard report dispatched to HQ console.')),
                      );
                    }
                  },
                  child: Text('SOS', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Alerts Section
            _buildAlertsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard() {
    if (_currentTask == null) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF121726),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2638)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text('No Active Emergency Task', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              'Standing by in $_zone. Incoming HQ dispatches will trigger your vibration alarm immediately.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final task = _currentTask!;
    final status = task['status'] ?? 'ASSIGNED';
    final isCritical = task['priority'] == 'CRITICAL';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFEAB308), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? const Color(0xFFEF4444) : const Color(0xFFEAB308)).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFFEAB308).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCritical ? '🚨 CRITICAL DISPATCH' : 'ACTIVE SAFETY TASK',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFEAB308),
                  ),
                ),
              ),
              Text(
                'Status: $status',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            task['title']?.toString() ?? 'Crowd Control Task',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          Text(
            task['description']?.toString() ?? '',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C101A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFEAB308), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sector: ${task['locationName'] ?? _zone}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Progressive Task Action Stepper Buttons
          _buildTaskActionButton(status),
        ],
      ),
    );
  }

  Widget _buildTaskActionButton(String status) {
    if (status == 'ASSIGNED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.thumb_up_rounded, color: Colors.white),
          label: Text('ACCEPT TASK & ACKNOWLEDGE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => _updateTaskStatus('ACCEPTED'),
        ),
      );
    } else if (status == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEAB308),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.directions_run_rounded, color: Colors.black),
          label: Text('MARK EN ROUTE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
          onPressed: () => _updateTaskStatus('EN_ROUTE'),
        ),
      );
    } else if (status == 'EN_ROUTE') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.pin_drop_rounded, color: Colors.white),
          label: Text('ARRIVED ON SCENE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => _updateTaskStatus('ARRIVED'),
        ),
      );
    } else if (status == 'ARRIVED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.task_alt_rounded, color: Colors.white),
          label: Text('MARK INCIDENT RESOLVED', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () => _updateTaskStatus('COMPLETED'),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Text('TASK RESOLVED & REPORTED TO HQ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
          ],
        ),
      );
    }
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT SAFETY ALERTS', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
            Text('${_alerts.length} Total', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 10),

        if (_alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF121726),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2638)),
            ),
            child: Text('No active hazard alerts in your zone', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          )
        else
          ..._alerts.map((a) {
            final isAck = a['acknowledged'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1318),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        a['severity']?.toString() ?? 'WARNING',
                        style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      if (a['grid'] != null)
                        Text('GRID ${a['grid']}', style: GoogleFonts.inter(color: const Color(0xFFEAB308), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(a['message']?.toString() ?? 'Hazard alert', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 10),
                  if (!isAck)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        onPressed: () => _acknowledgeAlert(a),
                        child: Text('ACKNOWLEDGE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 6),
                        Text('Acknowledged by you', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11)),
                      ],
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
