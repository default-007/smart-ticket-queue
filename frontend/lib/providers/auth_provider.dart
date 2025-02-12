// lib/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, error }

class AuthState {
  final bool isLoading;
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthStateNotifier extends ChangeNotifier {
  AuthState _state;

  AuthStateNotifier(this._state);

  AuthState get state => _state;

  void update(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final _storage = const FlutterSecureStorage();
  Timer? _refreshTimer;

  AuthNotifier(this._authService) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      print('Checking auth status...'); // Debug print
      state.copyWith(isLoading: true);
      final token = await _storage.read(key: 'token');
      final refreshToken = await _storage.read(key: 'refreshToken');
      print('Token found: ${token != null}'); // Debug print

      if (token == null) {
        print('No token - transitioning to unauthenticated');
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.unauthenticated, // This should trigger navigation
          user: null,
        );
        return;
      }

      try {
        final response = await _authService.validateSession(token);
        if (response['isValid']) {
          state = state.copyWith(
            isLoading: false,
            status: AuthStatus.authenticated,
            user: response['user'] as User,
          );
          _setupTokenRefresh();
          return;
        }
      } catch (e) {
        print('Session validation error: $e');
      }

      state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        user: null,
      );
    } catch (e) {
      print('Auth check error: $e'); // Debug print

      state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        user: null,
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      // Create a new state with loading set to true
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response = await _authService.register(name, email, password);

      // Update state with successful registration
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: response.user,
        error: null,
      );

      _setupTokenRefresh();
    } catch (e) {
      // Update state with error
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _authService.login(email, password);

      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: response.user, // User object already includes token
      );

      _setupTokenRefresh();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _authService.refreshToken(refreshToken);

      // Update the user object with the new token
      final updatedUser = state.user?.copyWith(token: response['token']);

      state = state.copyWith(
        user: updatedUser,
        status: AuthStatus.authenticated,
        isLoading: false,
      );

      _setupTokenRefresh();
    } catch (e) {
      await logout();
    }
  }

  void _setupTokenRefresh() {
    _refreshTimer?.cancel();
    // Refresh token 5 minutes before expiry (assuming 30-minute token lifetime)
    _refreshTimer = Timer(const Duration(minutes: 25), () async {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken != null) {
        await refreshAccessToken(refreshToken);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    if (state.isAuthenticated) {
      try {
        await _authService.logout();
      } catch (e) {
        // If logout fails, we still want to clear local state
        print('Logout error: $e');
      }
    }
    state.copyWith(
      isLoading: false,
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }

  changePassword(
      {required String currentPassword, required String newPassword}) {}

  updateProfile({required String name, required String email}) {}
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
