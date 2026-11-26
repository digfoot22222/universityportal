import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed encrypted credential & session token vault
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyMatric = 'unicore_saved_matric';
  static const _keyPasswordHash = 'unicore_pwd_sha256_hash';
  static const _keySessionToken = 'unicore_active_jwt_session';
  static const _keyBiometricsEnabled = 'unicore_biometrics_pref';

  String _hashPassword(String rawPassword) {
    final salted = 'UNICORE_ZERO_TRUST_SALT_2026::$rawPassword';
    return sha256.convert(utf8.encode(salted)).toString();
  }

  Future<void> saveCredentials({
    required String matricNumber,
    required String rawPassword,
    required String sessionToken,
    required bool enableBiometrics,
  }) async {
    await _storage.write(key: _keyMatric, value: matricNumber);
    await _storage.write(
        key: _keyPasswordHash, value: _hashPassword(rawPassword));
    await _storage.write(key: _keySessionToken, value: sessionToken);
    await _storage.write(
        key: _keyBiometricsEnabled, value: enableBiometrics.toString());
  }

  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _keySessionToken, value: token);
  }

  Future<bool> verifyPassword(String candidatePassword) async {
    final storedHash = await _storage.read(key: _keyPasswordHash);
    if (storedHash == null) return false;
    return storedHash == _hashPassword(candidatePassword);
  }

  Future<String?> getSavedMatricNumber() async {
    return _storage.read(key: _keyMatric);
  }

  Future<bool> isBiometricPreferenceEnabled() async {
    final val = await _storage.read(key: _keyBiometricsEnabled);
    return val == 'true';
  }

  Future<void> clearActiveSessionOnly() async {
    await _storage.delete(key: _keySessionToken);
  }
}