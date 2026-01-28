import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/models/user.dart';
import '../../features/auth/domain/models/auth_state.dart';
import '../config/app_constants.dart';

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;

  AuthStateNotifier(this._authRepository, this._secureStorage)
      : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        // Validate token and get user
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AsyncValue.data(AuthState.authenticated(user: user, token: token));
        } else {
          state = const AsyncValue.data(AuthState.unauthenticated());
        }
      } else {
        state = const AsyncValue.data(AuthState.unauthenticated());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authRepository.login(email, password);
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: result.token);
      await _secureStorage.write(key: AppConstants.refreshTokenKey, value: result.refreshToken);
      state = AsyncValue.data(AuthState.authenticated(user: result.user, token: result.token));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authRepository.register(name, email, password);
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: result.token);
      await _secureStorage.write(key: AppConstants.refreshTokenKey, value: result.refreshToken);
      state = AsyncValue.data(AuthState.authenticated(user: result.user, token: result.token));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    state = const AsyncValue.data(AuthState.unauthenticated());
  }

  Future<void> updateUser(User user) async {
    final currentState = state.valueOrNull;
    if (currentState != null && currentState.isAuthenticated) {
      state = AsyncValue.data(currentState.copyWith(user: user));
    }
  }
}

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthStateNotifier(authRepository, secureStorage);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.isAuthenticated ?? false;
});
