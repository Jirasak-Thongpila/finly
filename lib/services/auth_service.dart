import '../models/user.dart';
import 'api_client.dart';

/// Authentication endpoints: register, login, logout, me.
class AuthService {
  AuthService._();

  static Future<AuthResult> register({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/register', body: {
      'fname': fname,
      'lname': lname,
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(data);
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthResult.fromJson(data);
  }

  static Future<User> me(String token) async {
    final data = await ApiClient.get('/auth/me', token: token);
    return User.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  static Future<void> logout(String? token) async {
    await ApiClient.post('/auth/logout', token: token);
  }
}

/// Parsed result of login / register responses.
class AuthResult {
  final String token;
  final User user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token']?.toString() ?? '',
        user: User.fromJson(
            (json['user'] as Map? ?? {}).cast<String, dynamic>()),
      );

  bool get hasToken => token.isNotEmpty;
}