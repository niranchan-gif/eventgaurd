import os

path = r'd:\vscode\enventguardai\staff_app\lib\main.dart'

dart_code = """import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const EventGuardStaffApp());
}

class EventGuardStaffApp extends StatelessWidget {
  const EventGuardStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventGuard Staff',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1116),
        primaryColor: const Color(0xFF4444EF),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF151722)),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.indigo,
          accentColor: const Color(0xFFEAA61A),
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
  final _ipController = TextEditingController(text: '192.168.1.10');
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController(text: 'EVENTGUARD_DEMO_2026');
  final _staffIdController = TextEditingController(text: 'STAFF-001');
  final _teamIdController = TextEditingController(text: 'SECURITY-A');

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('hq_ip') ?? '192.168.1.10';
      _portController.text = prefs.getString('hq_port') ?? '8765';
      _tokenController.text = prefs.getString('enrollment_token') ?? 'EVENTGUARD_DEMO_2026';
      _staffIdController.text = prefs.getString('staff_id') ?? 'STAFF-001';
      _teamIdController.text = prefs.getString('team_id') ?? 'SECURITY-A';
    });
  }

  Future<void> _connect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hq_ip', _ipController.text);
    await prefs.setString('hq_port', _portController.text);
    await prefs.setString('enrollment_token', _tokenController.text);
    await prefs.setString('staff_id', _staffIdController.text);
    await prefs.setString('team_id', _teamIdController.text);
    
    String deviceId = prefs.getString('device_id') ?? '';
    if (deviceId.isEmpty) {
      deviceId = 'EG-STAFF-' + DateTime.now().millisecondsSinceEpoch.toString();
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
      appBar: AppBar(title: const Text('EVENTGUARD STAFF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Connect to EventGuard HQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'HQ Server IP')),
            TextField(controller: _portController, decoration: const InputDecoration(labelText: 'WebSocket Port')),
            TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'Enrollment Token'), obscureText: true),
            TextField(controller: _staffIdController, decoration: const InputDecoration(labelText: 'Staff ID')),
            TextField(controller: _teamIdController, decoration: const InputDecoration(labelText: 'Team ID')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4444EF), padding: const EdgeInsets.all(16)),
              child: const Text('CONNECT', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
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
  String _token = '';
  int _reconnectDelay = 1;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs.getString('device_id') ?? '';
    _staffId = _prefs.getString('staff_id') ?? '';
    _teamId = _prefs.getString('team_id') ?? '';
    _token = _prefs.getString('enrollment_token') ?? '';
    _connect();
  }

  void _connect() {
    if (_connectionStatus == 'ONLINE') return;
    setState(() => _connectionStatus = 'CONNECTING');
    
    final String ip = _prefs.getString('hq_ip') ?? '127.0.0.1';
    final String port = _prefs.getString('hq_port') ?? '8765';
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://' + ip + ':' + port + '/field'));
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        _handleMessage(data);
      }, onDone: () {
        _handleDisconnect();
      }, onError: (e) {
        _handleDisconnect();
      });
      
      _channel!.sink.add(jsonEncode({
        'type': 'REGISTER',
        'deviceId': _deviceId,
        'unitId': _teamId,
        'staffId': _staffId,
        'teamId': _teamId,
        'token': _token,
        'appVersion': '1.0.0',
        'battery': 100
      }));
    } catch (e) {
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
      setState(() => _connectionStatus = 'OFFLINE (Auth Failed)');
    } else if (type == 'TASK_ASSIGNED') {
      setState(() {
        _currentTask = data;
        _currentTask!['status'] = 'ASSIGNED';
      });
    } else if (type == 'ALERT') {
      setState(() {
        _alerts.insert(0, data);
      });
    }
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
          'deviceId': _deviceId
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
        'taskId': _currentTask!['taskId'],
        'deviceId': _deviceId,
        'staffId': _staffId,
        'status': newStatus,
        'timestamp': DateTime.now().toIso8601String()
      }));
    }
  }

  void _acknowledgeAlert(Map<String, dynamic> alert) {
    if (_connectionStatus == 'ONLINE') {
      _channel?.sink.add(jsonEncode({
        'type': 'ACK',
        'eventId': alert['eventId'],
        'deviceId': _deviceId,
        'staffId': _staffId
      }));
    }
    setState(() {
      alert['acknowledged'] = true;
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVENTGUARD STAFF'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _connectionStatus == 'ONLINE' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(_connectionStatus, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF151722),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff: ' + _staffId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Team: ' + _teamId),
                    Text('Device ID: ' + _deviceId, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('CURRENT TASK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            if (_currentTask == null)
              const Card(
                color: Color(0xFF151722),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No active task')),
                ),
              )
            else
              Card(
                color: const Color(0xFF151722),
                shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFEAA61A)), borderRadius: BorderRadius.circular(4)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('?? NEW TASK', style: TextStyle(color: Color(0xFFEAA61A), fontWeight: FontWeight.bold)),
                          Text(_currentTask!['priority']?.toString() ?? 'NORMAL', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_currentTask!['title']?.toString() ?? 'Unknown Task', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_currentTask!['description']?.toString() ?? ''),
                      const SizedBox(height: 12),
                      Text('Location: ' + (_currentTask!['locationName']?.toString() ?? 'Unknown'), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Text('Status: ' + (_currentTask!['status']?.toString() ?? 'UNKNOWN'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: _buildTaskButton(),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('RECENT ALERTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            if (_alerts.isEmpty)
              const Card(
                color: Color(0xFF151722),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No new alerts')),
                ),
              )
            else
              ..._alerts.map((a) => Card(
                color: const Color(0xFF2A1515),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HIGH PRIORITY ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(a['message']?.toString() ?? 'Unknown alert'),
                      const SizedBox(height: 8),
                      Text('Event: ' + (a['eventId']?.toString() ?? ''), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      if (a['acknowledged'] != true)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _acknowledgeAlert(a),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      else
                        const Center(child: Text('? Acknowledged', style: TextStyle(color: Colors.green))),
                    ],
                  ),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskButton() {
    final status = _currentTask!['status'];
    if (status == 'ASSIGNED') {
      return ElevatedButton(
        onPressed: () => _updateTaskStatus('ACCEPTED'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4444EF)),
        child: const Text('ACCEPT TASK', style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'ACCEPTED') {
      return ElevatedButton(
        onPressed: () => _updateTaskStatus('EN_ROUTE'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('START MOVING', style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'EN_ROUTE') {
      return ElevatedButton(
        onPressed: () => _updateTaskStatus('ARRIVED'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('ARRIVED', style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'ARRIVED') {
      return ElevatedButton(
        onPressed: () => _updateTaskStatus('COMPLETED'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        child: const Text('COMPLETE TASK', style: TextStyle(color: Colors.white)),
      );
    } else {
      return const Center(child: Text('? TASK COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
    }
  }
}
"""

with open(path, 'w', encoding='utf-8') as f:
    f.write(dart_code)
