import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kSessionToken = 'enterprise_session_token';
  static const _kLastMatric = 'enterprise_last_matric';
  static const _kBiometricOptIn = 'enterprise_biometric_opt_in';
  static const _kPasswordHashPrefix = 'pwd_hash_';

  /// Never stores raw passwords; stores salted SHA-256 digest in hardware keychain/keystore
  String _hashPassword(String matric, String rawPassword) {
    final bytes = utf8.encode('UNIV_SALT_${matric.toUpperCase()}_$rawPassword');
    return sha256.convert(bytes).toString();
  }

  Future<void> saveCredentials({
    required String matricNumber,
    required String rawPassword,
    required String sessionToken,
    bool enableBiometrics = true,
  }) async {
    final normalizedMatric = matricNumber.trim().toUpperCase();
    final hash = _hashPassword(normalizedMatric, rawPassword);
    await _storage.write(
        key: '$_kPasswordHashPrefix$normalizedMatric', value: hash);
    await _storage.write(key: _kSessionToken, value: sessionToken);
    await _storage.write(key: _kLastMatric, value: normalizedMatric);
    await _storage.write(
        key: _kBiometricOptIn, value: enableBiometrics.toString());
  }

  Future<bool> verifyPassword(String matricNumber, String rawPassword) async {
    final normalizedMatric = matricNumber.trim().toUpperCase();
    final storedHash =
    await _storage.read(key: '$_kPasswordHashPrefix$normalizedMatric');
    if (storedHash == null) return false;
    return storedHash == _hashPassword(normalizedMatric, rawPassword);
  }

  Future<bool> hasStoredPassword(String matricNumber) async {
    final normalizedMatric = matricNumber.trim().toUpperCase();
    final val =
    await _storage.read(key: '$_kPasswordHashPrefix$normalizedMatric');
    return val != null;
  }

  Future<String?> getLastMatricNumber() => _storage.read(key: _kLastMatric);

  Future<bool> isBiometricOptedIn() async {
    final val = await _storage.read(key: _kBiometricOptIn);
    return val == 'true';
  }

  Future<void> clearActiveSession() async {
    await _storage.delete(key: _kSessionToken);
  }
}