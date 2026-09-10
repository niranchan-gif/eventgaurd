import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import 'vault_encryption_service.dart';

class GitHubAuthService {
  static const String defaultRepoOwner = 'niranchan-gif';
  static const String defaultRepoName = 'Bordergaurdai';
  static const String encryptedVaultFileName = 'operators.enc';

  static String? _savedToken;
  static String? get savedToken => _savedToken;

  /// Resolves the local operators.enc file path in the repository
  static File _getLocalVaultFile() {
    final cwd = Directory.current.path;
    final file = File('$cwd/$encryptedVaultFileName');
    if (file.existsSync()) return file;

    final parentFile = File('$cwd/../$encryptedVaultFileName');
    if (parentFile.existsSync()) return parentFile;

    return file;
  }

  /// Loads and decrypts the operator credentials list from operators.enc
  /// Strictly NO dummy accounts. If vault doesn't exist, returns empty list.
  static Future<List<Map<String, dynamic>>> loadOperators({bool checkRemote = false}) async {
    final file = _getLocalVaultFile();

    // 1. Try reading and decrypting local repository encrypted file
    if (await file.exists()) {
      try {
        final encryptedData = await file.readAsString();
        if (encryptedData.trim().isNotEmpty) {
          final decryptedJson = VaultEncryptionService.decryptString(encryptedData);
          final dynamic parsed = json.decode(decryptedJson);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      } catch (e) {
        // Vault corrupt or decrypt issue
        return [];
      }
    }

    // 2. If requested and remote available, attempt fetch of encrypted file from GitHub raw
    if (checkRemote) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final rawUrl = Uri.parse(
          'https://raw.githubusercontent.com/$defaultRepoOwner/$defaultRepoName/main/$encryptedVaultFileName',
        );
        final request = await client.getUrl(rawUrl);
        request.headers.set('User-Agent', 'BorderGuard-AI-Defense/1.0');
        final response = await request.close().timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final encryptedContent = await response.transform(utf8.decoder).join();
          final decryptedJson = VaultEncryptionService.decryptString(encryptedContent);
          final dynamic parsed = json.decode(decryptedJson);
          if (parsed is List) {
            final list = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            // Cache to local file
            await file.writeAsString(encryptedContent);
            return list;
          }
        }
      } catch (_) {}
    }

    return [];
  }

  /// Strictly authenticates ONLY registered operators by decrypting operators.enc
  static Future<UserModel?> authenticateOperator(String username, String password) async {
    final trimmedUser = username.trim().toLowerCase();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) return null;

    final operators = await loadOperators();
    if (operators.isEmpty) return null;

    for (final op in operators) {
      final opUsername = (op['username'] ?? '').toString().toLowerCase();
      final opCallsign = (op['callsign'] ?? '').toString().toLowerCase();

      if (trimmedUser == opUsername || trimmedUser == opCallsign) {
        final salt = op['salt'] as String?;
        final passwordHash = op['passwordHash'] as String?;
        final rawPassword = op['password'] as String?;

        bool isMatch = false;

        if (salt != null && passwordHash != null) {
          final computedHash = VaultEncryptionService.hashPassword(trimmedPass, salt);
          isMatch = (computedHash == passwordHash);
        } else if (rawPassword != null) {
          isMatch = (rawPassword == trimmedPass);
        }

        if (isMatch) {
          return UserModel(
            id: op['id'] ?? 'OP-${DateTime.now().millisecondsSinceEpoch}',
            name: op['name'] ?? op['username'],
            callsign: op['callsign'] ?? op['username'],
            email: op['email'] ?? '${op['username']}@borderguard.mil',
            role: op['role'] ?? 'Defense Operator',
            clearanceLevel: op['clearanceLevel'] ?? 'LEVEL 3 • SENSOR OPERATOR',
            avatarUrl: null,
            provider: AuthProvider.password,
          );
        }
      }
    }

    return null;
  }

  /// Registers a new operator, encrypts the entire vault, and saves operators.enc into the Git repository
  static Future<UserModel> registerOperator({
    required String username,
    required String password,
    required String name,
    required String role,
    required String clearanceLevel,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) {
      throw Exception('Callsign cannot be empty');
    }
    if (password.trim().length < 4) {
      throw Exception('Password must contain at least 4 characters');
    }

    final operators = await loadOperators();

    // Prevent duplicate registrations
    final exists = operators.any((o) => (o['username'] ?? '').toString().toLowerCase() == cleanUsername);
    if (exists) {
      throw Exception('Callsign "$cleanUsername" is already registered. Please choose a different callsign or sign in.');
    }

    // Generate cryptographic salt and hash
    final salt = VaultEncryptionService.generateSalt();
    final passwordHash = VaultEncryptionService.hashPassword(password.trim(), salt);

    final newId = 'OP-${(operators.length + 1).toString().padLeft(3, '0')}';
    final newRecord = {
      "id": newId,
      "username": cleanUsername,
      "callsign": cleanUsername,
      "name": name.trim(),
      "email": '$cleanUsername@borderguard.mil',
      "role": role.trim(),
      "clearanceLevel": clearanceLevel.trim(),
      "salt": salt,
      "passwordHash": passwordHash,
      "registeredAt": DateTime.now().toIso8601String(),
    };

    operators.add(newRecord);

    // Encrypt the updated list with military vault encryption
    final jsonPayload = const JsonEncoder.withIndent('  ').convert(operators);
    final encryptedData = VaultEncryptionService.encryptString(jsonPayload);

    // Save to operators.enc in the local GitHub repository
    final file = _getLocalVaultFile();
    await file.writeAsString(encryptedData);

    // Stage in Git repository automatically
    _stageVaultInGit();

    return UserModel(
      id: newId,
      name: name.trim(),
      callsign: cleanUsername,
      email: '$cleanUsername@borderguard.mil',
      role: role.trim(),
      clearanceLevel: clearanceLevel.trim(),
      avatarUrl: null,
      provider: AuthProvider.password,
    );
  }

  /// Runs background git staging for operators.enc
  static void _stageVaultInGit() async {
    try {
      await Process.run('git', ['add', encryptedVaultFileName]);
    } catch (_) {}
  }

  /// Authenticates using a GitHub Personal Access Token directly with api.github.com
  static Future<UserModel?> authenticateWithGitHubToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(Uri.parse('https://api.github.com/user'));
      request.headers.set('User-Agent', 'BorderGuard-AI-Defense/1.0');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      request.headers.set('Authorization', 'Bearer $trimmedToken');

      final response = await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;

        _savedToken = trimmedToken;

        final login = data['login'] ?? 'github_user';
        final name = data['name'] ?? login;
        final email = data['email'] ?? '$login@users.noreply.github.com';
        final avatarUrl = data['avatar_url'] as String?;

        return UserModel(
          id: 'GH-${data['id'] ?? DateTime.now().millisecondsSinceEpoch}',
          name: name,
          callsign: login,
          email: email,
          role: 'GitHub Defense Lead / Core Contributor',
          clearanceLevel: 'LEVEL 5 • GITHUB DEFENSE ARCHITECT',
          avatarUrl: avatarUrl,
          provider: AuthProvider.github,
        );
      } else {
        throw Exception('GitHub API Authentication failed (Status: ${response.statusCode})');
      }
    } finally {
      client.close();
    }
  }

  /// Check server / repo connectivity
  static Future<bool> checkServerConnection() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('https://api.github.com/zen'));
      request.headers.set('User-Agent', 'BorderGuard-AI-Defense/1.0');
      final response = await request.close().timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
