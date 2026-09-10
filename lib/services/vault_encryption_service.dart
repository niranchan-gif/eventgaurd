import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class VaultEncryptionService {
  static const String _magicHeader = 'BG_DEFENSE_VAULT_V1::';
  // 256-bit military master vault key
  static const String _masterSecret = 'BG-DEFENSE-C2-CLASSIFIED-VAULT-KEY-99482-2026';

  static List<int> get _derivedKey {
    return sha256.convert(utf8.encode(_masterSecret)).bytes;
  }

  /// Hashes a user's password with a unique salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password::BG_SALT_DEFENSE_2026');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cryptographically secure random salt
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Encrypts plaintext string into an authenticated military encrypted vault payload
  static String encryptString(String plaintext) {
    final random = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
    final plainBytes = utf8.encode(plaintext);

    final key = _derivedKey;
    final cipherBytes = Uint8List(plainBytes.length);

    // HMAC-SHA256 Counter Keystream (AES-equivalent CTR stream mode)
    final blockSize = 32;
    final numBlocks = (plainBytes.length + blockSize - 1) ~/ blockSize;

    final hmac = Hmac(sha256, key);

    for (int b = 0; b < numBlocks; b++) {
      final counterBytes = ByteData(4)..setUint32(0, b, Endian.big);
      final blockSeed = Uint8List.fromList([...salt, ...counterBytes.buffer.asUint8List()]);
      final keyStreamBlock = hmac.convert(blockSeed).bytes;

      final start = b * blockSize;
      final end = (start + blockSize > plainBytes.length) ? plainBytes.length : start + blockSize;

      for (int i = start; i < end; i++) {
        cipherBytes[i] = plainBytes[i] ^ keyStreamBlock[i - start];
      }
    }

    // Encrypt-then-MAC authentication tag
    final macTag = hmac.convert([...salt, ...cipherBytes]).bytes;

    final fullPayload = Uint8List.fromList([...salt, ...macTag, ...cipherBytes]);
    return '$_magicHeader${base64.encode(fullPayload)}';
  }

  /// Decrypts encrypted vault payload and verifies authenticity
  static String decryptString(String encryptedPayload) {
    final trimmed = encryptedPayload.trim();
    if (!trimmed.startsWith(_magicHeader)) {
      throw const FormatException('Invalid vault header or corrupted file format');
    }

    final rawBase64 = trimmed.substring(_magicHeader.length);
    final payload = base64.decode(rawBase64);

    if (payload.length < 16 + 32) {
      throw const FormatException('Encrypted payload too short');
    }

    final salt = payload.sublist(0, 16);
    final providedMac = payload.sublist(16, 48);
    final cipherBytes = payload.sublist(48);

    final key = _derivedKey;
    final hmac = Hmac(sha256, key);

    // Verify MAC Tag
    final calculatedMac = hmac.convert([...salt, ...cipherBytes]).bytes;
    if (!_constantTimeEquals(providedMac, calculatedMac)) {
      throw const FormatException('Vault integrity verification failed! File has been tampered with.');
    }

    // Decrypt Keystream
    final plainBytes = Uint8List(cipherBytes.length);
    final blockSize = 32;
    final numBlocks = (cipherBytes.length + blockSize - 1) ~/ blockSize;

    for (int b = 0; b < numBlocks; b++) {
      final counterBytes = ByteData(4)..setUint32(0, b, Endian.big);
      final blockSeed = Uint8List.fromList([...salt, ...counterBytes.buffer.asUint8List()]);
      final keyStreamBlock = hmac.convert(blockSeed).bytes;

      final start = b * blockSize;
      final end = (start + blockSize > cipherBytes.length) ? cipherBytes.length : start + blockSize;

      for (int i = start; i < end; i++) {
        plainBytes[i] = cipherBytes[i] ^ keyStreamBlock[i - start];
      }
    }

    return utf8.decode(plainBytes);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
