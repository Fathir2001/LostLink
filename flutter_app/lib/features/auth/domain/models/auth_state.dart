import 'user.dart';

/// Authentication state
class AuthState {
  final User? user;
  final String? token;
  final bool isAuthenticated;

  const AuthState._({
    this.user,
    this.token,
    required this.isAuthenticated,
  });

  const AuthState.unauthenticated()
      : user = null,
        token = null,
        isAuthenticated = false;

  const AuthState.authenticated({
    required User this.user,
    required String this.token,
  }) : isAuthenticated = true;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isAuthenticated,
  }) {
    return AuthState._(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Auth result from login/register
class AuthResult {
  final User user;
  final String token;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    // Backend wraps response in 'data' field
    final data = json['data'] ?? json;
    return AuthResult(
      user: User.fromJson(data['user']),
      token: data['accessToken'] ?? data['token'],
      refreshToken: data['refreshToken'],
    );
  }
}
