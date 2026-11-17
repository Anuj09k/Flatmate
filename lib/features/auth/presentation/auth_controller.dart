import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({AppUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(const AuthState());

  Future<bool> signUpWithOtp({
    required String phone,
    required String otp,
    String? email,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.verifyOtpAndSignUp(
        phone: phone,
        otp: otp,
        email: email,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> selectRole(UserRole role) async {
    final current = state.user;
    if (current == null) return;
    final updated = await _repo.updateRole(current.id, role);
    state = state.copyWith(user: updated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
