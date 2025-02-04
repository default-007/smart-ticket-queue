import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

// Create a provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Create a provider for AuthService that depends on ApiService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      try {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(user: user);
      } catch (e) {
        await _authService.logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.login(email, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.register(name, email, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.updateProfile(name, email);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}
