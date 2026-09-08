import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class BackendLauncher {
  static Process? _backendProcess;
  static int? _backendPid;

  /// Ensures that the Python AI server is actively running.
  /// Launches backend_server.py if not already active.
  static Future<void> ensureBackendRunning() async {
    try {
      // 1. Check if backend is already responding
      if (await isBackendResponding()) {
        debugPrint('[BACKEND] Python AI server is already active on http://127.0.0.1:5000');
        return;
      }

      // 2. Kill any stale/orphaned process lingering on port 5000
      await _killStaleProcessOnPort5000();

      // 3. Resolve Python executable
      final pythonExe = _resolvePythonExecutable();
      debugPrint('[BACKEND] Launching Python backend with: $pythonExe ...');

      // 4. Start backend_server.py managed by Flutter
      final process = await Process.start(
        pythonExe,
        ['backend_server.py'],
        runInShell: false,
      );

      _backendProcess = process;
      _backendPid = process.pid;
      debugPrint('[BACKEND] Python server process started (PID: $_backendPid). Awaiting model warmup...');

      // Capture stdout & stderr for debugging
      process.stdout.transform(utf8.decoder).listen((line) {
        debugPrint('[PYTHON] $line'.trim());
      });
      process.stderr.transform(utf8.decoder).listen((line) {
        debugPrint('[PYTHON ERR] $line'.trim());
      });

      // 5. Poll until port 5000 responds (up to 15 seconds for YOLO model warmup)
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (await isBackendResponding()) {
          debugPrint('[BACKEND] Python AI server successfully synchronized on http://127.0.0.1:5000');
          break;
        }
      }
    } catch (e) {
      debugPrint('[BACKEND LAUNCH ERROR] $e');
    }
  }

  /// Terminates the Python AI server when the Flutter app/dashboard closes.
  static Future<void> shutdownBackend() async {
    debugPrint('[BACKEND] Initiating shutdown of Python AI backend...');
    try {
      // 1. Send clean HTTP shutdown request to release camera handles
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 500);
      try {
        final req = await client.getUrl(Uri.parse('http://127.0.0.1:5000/api/shutdown'));
        await req.close().timeout(const Duration(milliseconds: 600));
      } catch (_) {}
      client.close();

      // 2. Kill tracked child process directly
      if (_backendProcess != null) {
        _backendProcess!.kill(ProcessSignal.sigkill);
      }

      // 3. Windows failsafe: Taskkill PID tree
      if (Platform.isWindows && _backendPid != null) {
        await Process.run('taskkill', ['/F', '/T', '/PID', '$_backendPid']);
      }

      // 4. Guarantee port 5000 is completely freed
      await _killStaleProcessOnPort5000();

      _backendProcess = null;
      _backendPid = null;
      debugPrint('[BACKEND] Python AI backend terminated successfully.');
    } catch (e) {
      debugPrint('[BACKEND SHUTDOWN ERROR] $e');
    }
  }

  /// Checks if http://127.0.0.1:5000/api/telemetry is responding.
  static Future<bool> isBackendResponding() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 400);
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:5000/api/telemetry'));
      final res = await req.close().timeout(const Duration(milliseconds: 500));
      final success = res.statusCode == 200;
      client.close();
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Resolves the preferred Python binary (local virtualenv or system python).
  static String _resolvePythonExecutable() {
    final venvWin = File('venv\\Scripts\\python.exe');
    if (venvWin.existsSync()) return venvWin.path;

    final venvUnix = File('venv/bin/python');
    if (venvUnix.existsSync()) return venvUnix.path;

    return 'python';
  }

  /// Finds any process listening on port 5000 and kills it to prevent conflicts.
  static Future<void> _killStaleProcessOnPort5000() async {
    if (!Platform.isWindows) return;
    try {
      final result = await Process.run('cmd', ['/c', 'netstat -ano | findstr :5000.*LISTENING']);
      final output = (result.stdout as String).trim();
      if (output.isNotEmpty) {
        final lines = output.split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            final pid = parts.last;
            if (int.tryParse(pid) != null) {
              debugPrint('[BACKEND] Reclaiming port 5000 from lingering PID $pid...');
              await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
            }
          }
        }
      }
    } catch (_) {}
  }
}
