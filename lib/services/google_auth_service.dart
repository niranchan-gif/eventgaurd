import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class GoogleAuthService {
  // Stored Client ID for desktop OAuth
  static String? _savedClientId;
  static String? _savedClientSecret;

  static String? get savedClientId => _savedClientId;
  static String? get savedClientSecret => _savedClientSecret;

  static void setCredentials({required String clientId, String? clientSecret}) {
    _savedClientId = clientId.trim();
    _savedClientSecret = clientSecret?.trim();
  }

  /// Opens the system browser on Windows to a specified URL
  static Future<void> openBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      // Fallback
      await Process.run('powershell', ['Start-Process', '"$url"']);
    }
  }

  /// Executes full RFC 8252 Loopback OAuth 2.0 flow with Google in the system browser
  static Future<UserModel?> authenticateWithBrowser({
    required String clientId,
    String? clientSecret,
    Function(String status)? onStatusUpdate,
  }) async {
    HttpServer? server;
    try {
      onStatusUpdate?.call('Initializing local authentication listener...');

      // 1. Bind to an ephemeral loopback port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://127.0.0.1:$port';

      // 2. Build Google OAuth 2.0 Authorization URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.trim(),
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid profile email',
        'access_type': 'offline',
        'prompt': 'select_account consent',
      });

      onStatusUpdate?.call('Launching Google authentication in your default browser...');
      await openBrowser(authUrl.toString());

      onStatusUpdate?.call('Waiting for Google authorization in browser...');

      // 3. Listen for callback from Google
      final request = await server.first.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          throw TimeoutException('Authentication timed out. Please try again.');
        },
      );

      final queryParams = request.uri.queryParameters;
      final code = queryParams['code'];
      final error = queryParams['error'];

      // Send tactical dark HTML response back to the browser
      request.response.headers.contentType = ContentType.html;
      if (error != null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(_buildHtmlResponse(
          success: false,
          title: 'Google Authentication Denied',
          message: 'Error: $error. You may close this window and return to BorderGuard AI.',
        ));
        await request.response.close();
        throw Exception('Google OAuth error: $error');
      }

      if (code == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(_buildHtmlResponse(
          success: false,
          title: 'Authorization Code Missing',
          message: 'No authorization code received. Please try again.',
        ));
        await request.response.close();
        throw Exception('No code received from Google');
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.write(_buildHtmlResponse(
        success: true,
        title: 'Authentication Successful',
        message: 'Google credentials verified! You can return to BorderGuard AI now.',
      ));
      await request.response.close();

      onStatusUpdate?.call('Exchanging Google security tokens...');

      // 4. Exchange authorization code for tokens
      final httpClient = HttpClient();
      final tokenRequest = await httpClient.postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
      tokenRequest.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final tokenBody = {
        'code': code,
        'client_id': clientId.trim(),
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      };
      if (clientSecret != null && clientSecret.trim().isNotEmpty) {
        tokenBody['client_secret'] = clientSecret.trim();
      }

      final encodedBody = tokenBody.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      tokenRequest.write(encodedBody);
      final tokenResponse = await tokenRequest.close();
      final tokenResponseBody = await tokenResponse.transform(utf8.decoder).join();
      final tokenData = jsonDecode(tokenResponseBody) as Map<String, dynamic>;

      if (tokenResponse.statusCode != 200 || !tokenData.containsKey('access_token')) {
        final errDesc = tokenData['error_description'] ?? tokenData['error'] ?? 'Token exchange failed';
        throw Exception(errDesc);
      }

      final accessToken = tokenData['access_token'];

      onStatusUpdate?.call('Retrieving Google operator profile...');

      // 5. Fetch user profile from Google UserInfo endpoint
      final userRequest = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'));
      userRequest.headers.set('Authorization', 'Bearer $accessToken');
      final userResponse = await userRequest.close();
      final userResponseBody = await userResponse.transform(utf8.decoder).join();
      final userData = jsonDecode(userResponseBody) as Map<String, dynamic>;
      httpClient.close();

      final name = userData['name'] as String? ?? 'Google Operator';
      final email = userData['email'] as String? ?? 'operator@gmail.com';
      final picture = userData['picture'] as String?;
      final sub = userData['sub'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Persist working credentials
      _savedClientId = clientId;
      _savedClientSecret = clientSecret;

      return UserModel(
        id: 'GGL-$sub',
        name: name,
        callsign: email.split('@').first,
        email: email,
        role: 'Tactical Analyst (Google Verified SSO)',
        clearanceLevel: 'LEVEL 4 • VERIFIED GOOGLE ACCOUNT',
        avatarUrl: picture,
        provider: AuthProvider.google,
      );
    } catch (e) {
      rethrow;
    } finally {
      await server?.close(force: true);
    }
  }

  static String _buildHtmlResponse({required bool success, required String title, required String message}) {
    final color = success ? '#10B981' : '#EF4444';
    final icon = success ? '&#10004;' : '&#10008;';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>BorderGuard AI - $title</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #0C0D10;
      color: #F4F5F7;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background-color: #16181D;
      border: 1px solid #2B2F3A;
      border-radius: 12px;
      padding: 36px 44px;
      text-align: center;
      max-width: 440px;
      box-shadow: 0 16px 36px rgba(0,0,0,0.6);
    }
    .badge {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: $color;
      color: #0C0D10;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 28px;
      font-weight: bold;
      margin-bottom: 20px;
    }
    h2 {
      margin: 0 0 10px 0;
      color: #F4F5F7;
      font-size: 20px;
      letter-spacing: 0.5px;
    }
    p {
      color: #9CA3AF;
      font-size: 13px;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .app-tag {
      display: inline-block;
      padding: 4px 10px;
      background: #0C0D10;
      border: 1px solid #2B2F3A;
      border-radius: 4px;
      color: #F59E0B;
      font-size: 11px;
      font-weight: bold;
      letter-spacing: 0.8px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">$icon</div>
    <h2>$title</h2>
    <p>$message</p>
    <div class="app-tag">BORDERGUARD AI • SECURE DEFENSE TERMINAL</div>
  </div>
  <script>
    setTimeout(function() {
      try { window.close(); } catch(e) {}
    }, 4000);
  </script>
</body>
</html>
''';
  }
}
