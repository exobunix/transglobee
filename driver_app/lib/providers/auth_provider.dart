import 'package:flutter_riverpod/legacy.dart';
import '../services/rest_api_repository.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final RestApiRepository _repo;
  final AuthService _auth;

  AuthController(this._repo, this._auth) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.login(email: email, password: password);
    
    if (res.success) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.register(data);
    
    if (res.success) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: res.message);
      return false;
    }
  }

  Future<void> logout(String deviceId) async {
    state = state.copyWith(isLoading: true);
    // Notify backend and clear local state
    await _repo.updateStatus(isOnline: false, status: 'offline'); // Ensure offline on logout
    await _auth.clearRestAuth();
    state = AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(restApiRepositoryProvider),
    ref.watch(authServiceProvider),
  );
});
