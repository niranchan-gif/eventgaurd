import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/eventguard_config.dart';

class BackendLauncher {
  static Process? _backendProcess;
  static Process? _wsProcess;
  static int? _backendPid;
  static int? _wsPid;
  static bool _isStarting = false;
  static Completer<void>? _startCompleter;

  static bool get isStarting => _isStarting;

  static Future<void> ensureBackendRunning() async {
    if (_isStarting) return _startCompleter?.future;

    try {
      _isStarting = true;
      _startCompleter = Completer<void>();

      await _killStaleProcessOnPort(5000);
      await _killStaleProcessOnPort(8765);

      final projectDir = _resolveProjectDirectory();
      final pythonExe = _resolvePythonExecutable(projectDir);

      // Start WebSockets Demo Server
      _wsProcess = await Process.start(
        pythonExe,
        ['-u', 'demo_websocket_server.py'],
        workingDirectory: projectDir.path,
        runInShell: Platform.isWindows,
      );
      _wsPid = _wsProcess?.pid;
      
      _wsProcess?.stdout.transform(utf8.decoder).listen((line) => debugPrint('[WS] ${line.trim()}'));
      _wsProcess?.stderr.transform(utf8.decoder).listen((line) => debugPrint('[WS ERR] ${line.trim()}'));

      // Start AI Camera Backend
      if (!(await isBackendResponding())) {
          _backendProcess = await Process.start(
            pythonExe,
            ['-u', 'backend_server.py'],
            workingDirectory: projectDir.path,
            runInShell: Platform.isWindows,
          );
          _backendPid = _backendProcess?.pid;
          
          _backendProcess?.stdout.transform(utf8.decoder).listen((line) => debugPrint('[AI] ${line.trim()}'));
          _backendProcess?.stderr.transform(utf8.decoder).listen((line) => debugPrint('[AI ERR] ${line.trim()}'));
          
          for (int i = 0; i < 60; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (await isBackendResponding()) break;
          }
      }
    } catch (e) {
      debugPrint('[BACKEND LAUNCH ERROR] $e');
    } finally {
      _isStarting = false;
      if (_startCompleter != null && !_startCompleter!.isCompleted) {
        _startCompleter!.complete();
      }
    }
  }

  static Future<void> shutdownBackend() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 500);
      try {
        final req = await client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/shutdown'));
        await req.close().timeout(const Duration(milliseconds: 600));
      } catch (_) {}
      client.close();

      _backendProcess?.kill(ProcessSignal.sigkill);
      _wsProcess?.kill(ProcessSignal.sigkill);

      if (Platform.isWindows && _backendPid != null) await Process.run('taskkill', ['/F', '/T', '/PID', '$_backendPid']);
      if (Platform.isWindows && _wsPid != null) await Process.run('taskkill', ['/F', '/T', '/PID', '$_wsPid']);

      await _killStaleProcessOnPort(5000);
      await _killStaleProcessOnPort(8765);
    } catch (e) {}
  }

  static Future<bool> isBackendResponding() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 400);
      final req = await client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/telemetry'));
      final res = await req.close().timeout(const Duration(milliseconds: 500));
      final success = res.statusCode == 200;
      client.close();
      return success;
    } catch (_) {
      return false;
    }
  }

  static Directory _resolveProjectDirectory() {
    if (File('${Directory.current.path}/demo_websocket_server.py').existsSync()) return Directory.current;
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 10; i++) {
        if (File('${dir.path}/demo_websocket_server.py').existsSync()) return dir;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}
    return Directory.current;
  }

  static String _resolvePythonExecutable(Directory projectDir) {
    final venvWin = File('${projectDir.path}/venv/Scripts/python.exe');
    if (venvWin.existsSync()) return venvWin.path;
    final venvWinAlt = File('${projectDir.path}\\venv\\Scripts\\python.exe');
    if (venvWinAlt.existsSync()) return venvWinAlt.path;
    return 'python';
  }

  static Future<void> _killStaleProcessOnPort(int port) async {
    if (!Platform.isWindows) return;
    try {
      final result = await Process.run('cmd', ['/c', 'netstat -ano | findstr :$port.*LISTENING']);
      final output = (result.stdout as String).trim();
      if (output.isNotEmpty) {
        for (final line in output.split('\n')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            final pid = parts.last;
            if (int.tryParse(pid) != null) await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
          }
        }
      }
    } catch (_) {}
  }
}
