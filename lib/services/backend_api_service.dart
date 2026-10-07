import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/eventguard_config.dart';

class BackendApiService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(milliseconds: EventGuardConfig.apiTimeout);

  static Future<Map<String, dynamic>?> getTelemetry() async {
    try {
      final req = await _client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/telemetry'));
      final res = await req.close().timeout(const Duration(milliseconds: EventGuardConfig.apiTimeout));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Backend offline or unreachable
    }
    return null;
  }

  static Future<bool> startCamera(int cameraIndex) async {
    try {
      final req = await _client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/camera/start?index=$cameraIndex'));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopCamera(int cameraIndex) async {
    try {
      final req = await _client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/camera/stop?index=$cameraIndex'));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
