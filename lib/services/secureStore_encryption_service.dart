import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;

class SecureStoreEncryptionService {
  static const String _magicHeader = 'EG_SECURITY_SECURE_STORE_V2::';
  
  // A dynamic runtime key rather than a hardcoded source code secret.
  // In a full production system, this should come from a secure hardware enclave or user password derivation.
  static String? _runtimeSecret;

  static void initializeSecret(String secret) {
    _runtimeSecret = secret;
  }

  static List<int> get _derivedKey {
    // If not initialized, fallback to a local machine-specific identifier in a real app,
    // but here we just derive a key from a standard environment variable or default fallback.
    final secret = _runtimeSecret ?? 'EG_DEFAULT_FALLBACK_DO_NOT_USE_IN_PROD';
    return sha256.convert(utf8.encode(secret)).bytes;
  }

  /// Hashes a user's password with a unique salt using SHA-256 (in real prod: Argon2/bcrypt)
  static String hashPassword(String password, String salt) {
    // Basic iterative hashing as a minimal step up from pure SHA256
    List<int> bytes = utf8.encode('$salt::$password::EG_SALT_SECURITY_2026');
    for (int i = 0; i < 1000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  /// Generates a cryptographically secure random salt
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Encrypts plaintext string using AES-256-GCM
  static String encryptString(String plaintext) {
    final key = encrypt_lib.Key(Uint8List.fromList(_derivedKey));
    final iv = encrypt_lib.IV.fromSecureRandom(16);
    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Payload format: IV + Ciphertext (GCM tag is appended by the encryptor internally)
    return '$_magicHeader${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts AES-256-GCM payload and verifies authenticity
  static String decryptString(String encryptedPayload) {
    final trimmed = encryptedPayload.trim();
    if (!trimmed.startsWith(_magicHeader)) {
      throw const FormatException('Invalid secureStore header or corrupted file format');
    }

    final rawPayload = trimmed.substring(_magicHeader.length);
    final parts = rawPayload.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload format');
    }

    final iv = encrypt_lib.IV.fromBase64(parts[0]);
    final encrypted = encrypt_lib.Encrypted.fromBase64(parts[1]);
    
    final key = encrypt_lib.Key(Uint8List.fromList(_derivedKey));
    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
