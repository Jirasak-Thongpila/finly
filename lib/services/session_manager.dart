import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../utils/storage.dart';
import 'api_client.dart';
import 'auth_service.dart';

enum SessionStatus { restoring, unauthenticated, authenticated }

/// Global authentication state for the application.
///
/// - Restores a persisted token at startup (with a cached user, so the UI can
///   render immediately).
/// - Handles login / register / logout.
/// - Any 401 anywhere in the app should go through [handleUnauthorized] so all
///   screens automatically bounce back to the welcome screen.
class SessionManager extends ChangeNotifier {
  SessionStatus _status = SessionStatus.restoring;
  String? _token;
  User? _user;
  final TokenStorage _storage;

  SessionManager({TokenStorage? storage})
      : _storage = storage ?? SecureTokenStorage.instance;

  SessionStatus get status => _status;
  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  /// Loads the persisted token + cached user at startup.
  Future<void> restore() async {
    final stored = await _storage.readToken();
    if (stored == null || stored.isEmpty) {
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _token = stored;
    final cachedRaw = await _storage.readCachedUser();
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        _user = User.fromJson(jsonDecode(cachedRaw));
      } catch (_) {
        _user = null;
      }
    }
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final result = await AuthService.login(email: email, password: password);
    await _apply(result);
  }

  Future<void> register({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    final result = await AuthService.register(
      fname: fname,
      lname: lname,
      email: email,
      password: password,
    );
    await _apply(result);
  }

  Future<void> _apply(AuthResult result) async {
    _token = result.token;
    _user = result.user;
    await _storage.writeToken(result.token);
    await _storage.writeCachedUser(jsonEncode(result.user.toJson()));
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  /// Calls `POST /api/auth/logout`, clears local token and returns to welcome.
  /// The API call is best-effort: even if it fails, the session is cleared.
  Future<void> logout() async {
    final wasLoggedIn = _status == SessionStatus.authenticated;
    final currentToken = _token;
    if (wasLoggedIn && currentToken != null) {
      try {
        await AuthService.logout(currentToken);
      } catch (_) {
        // Revocation best effort — local session is cleared regardless.
      }
    }
    await _clearLocal();
  }

  /// Clears local session without server call (used on 401 handling too).
  Future<void> _clearLocal() async {
    _token = null;
    _user = null;
    _status = SessionStatus.unauthenticated;
    await _storage.clear();
    notifyListeners();
  }

  /// Central 401 handler: drops the token and signals a login-required UI.
  Future<void> handleUnauthorized() => _clearLocal();

  /// Refetches the user profile from `GET /api/auth/me`.
  Future<void> refreshProfile() async {
    final t = _token;
    if (t == null) return;
    try {
      final fresh = await AuthService.me(t);
      _user = fresh;
      await _storage.writeCachedUser(jsonEncode(fresh.toJson()));
      notifyListeners();
    } on ApiException {
      rethrow;
    }
  }
}