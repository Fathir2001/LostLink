import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_client.dart';
import '../../domain/models/user.dart';
import '../../domain/models/auth_state.dart';

/// Auth repository for authentication operations
class AuthRepository {
  final Ref _ref;

  AuthRepository(this._ref);

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  /// Login with email and password
  Future<AuthResult> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResult.fromJson(response.data);
  }

  /// Register new user
  Future<AuthResult> register(String name, String email, String password) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return AuthResult.fromJson(response.data);
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      final data = response.data['data'] ?? response.data;
      return User.fromJson(data['user']);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiClient.patch('/auth/me', data: profileData);
    final data = response.data['data'] ?? response.data;
    return User.fromJson(data['user']);
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _apiClient.post('/auth/forgot-password', data: {'email': email});
  }

  /// Reset password with token
  Future<void> resetPassword(String token, String newPassword) async {
    await _apiClient.post('/auth/reset-password', data: {
      'token': token,
      'password': newPassword,
    });
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _apiClient.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors during logout
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _apiClient.delete('/auth/me');
  }
}
