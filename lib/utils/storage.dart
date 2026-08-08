import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants.dart';

/// Contract for persisting the session token + cached user. Injected into
/// [SessionManager] so tests can use an in-memory implementation.
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<String?> readCachedUser();
  Future<void> writeCachedUser(String userJson);
  Future<void> clear();
}

/// Production implementation on top of `flutter_secure_storage`.
///
/// Falls back to an in-memory map when secure storage is unavailable so the
/// app never crashes (e.g. platforms without a keychain, or test runners).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage._();

  static final SecureTokenStorage instance = SecureTokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _memoryFallback = <String, String>{};

  @override
  Future<String?> readToken() => _read(AppConstants.secureStorageKey);

  @override
  Future<void> writeToken(String token) =>
      _write(AppConstants.secureStorageKey, token);

  @override
  Future<String?> readCachedUser() => _read(AppConstants.userCacheKey);

  @override
  Future<void> writeCachedUser(String userJson) =>
      _write(AppConstants.userCacheKey, userJson);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: AppConstants.secureStorageKey);
      await _storage.delete(key: AppConstants.userCacheKey);
    } catch (_) {
      // ignore
    }
    _memoryFallback.clear();
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _memoryFallback[key] = value;
    }
  }
}

/// In-memory implementation for widget tests.
class MemoryTokenStorage implements TokenStorage {
  final _data = <String, String>{};

  @override
  Future<String?> readToken() async => _data[AppConstants.secureStorageKey];

  @override
  Future<void> writeToken(String token) async =>
      _data[AppConstants.secureStorageKey] = token;

  @override
  Future<String?> readCachedUser() async => _data[AppConstants.userCacheKey];

  @override
  Future<void> writeCachedUser(String userJson) async =>
      _data[AppConstants.userCacheKey] = userJson;

  @override
  Future<void> clear() async => _data.clear();
}