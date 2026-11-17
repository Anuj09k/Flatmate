import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../domain/app_user.dart';

abstract class AuthRepository {
  Future<void> requestPhoneOtp(String phone);
  Future<AppUser> verifyOtpAndSignUp({
    required String phone,
    required String otp,
    String? email,
    required DateTime dateOfBirth,
    required String gender,
    DateTime? nowOverride,
  });
  Future<AppUser> updateRole(String userId, UserRole role);
}

class InMemoryAuthRepository implements AuthRepository {
  final AppConfig config;
  final Map<String, AppUser> _users = {};

  InMemoryAuthRepository(this.config);

  int _calculateAgeYears(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {
    if (phone.trim().length < 10) {
      throw ArgumentError('INVALID_PHONE: Enter a valid phone number.');
    }
  }

  @override
  Future<AppUser> verifyOtpAndSignUp({
    required String phone,
    required String otp,
    String? email,
    required DateTime dateOfBirth,
    required String gender,
    DateTime? nowOverride,
  }) async {
    if (otp != '123456') {
      throw StateError('INVALID_OTP: Incorrect verification code.');
    }

    final now = nowOverride ?? DateTime.now().toUtc();
    final age = _calculateAgeYears(dateOfBirth, now);
    if (age < config.minAgeYears) {
      throw StateError(
        'AGE_BELOW_MINIMUM: User must be at least ${config.minAgeYears} years old.',
      );
    }

    final user = AppUser(
      id: 'user_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      phone: phone,
      email: email,
      role: UserRole.seeker,
      dateOfBirth: dateOfBirth,
      gender: gender,
      createdAt: now,
      status: AccountStatus.limited,
      verificationDeadline: now.add(Duration(days: config.verificationWindowDays)),
    );
    _users[user.id] = user;
    return user;
  }

  @override
  Future<AppUser> updateRole(String userId, UserRole role) async {
    final existing = _users[userId];
    if (existing == null) {
      throw StateError('USER_NOT_FOUND');
    }
    final updated = existing.copyWith(role: role);
    _users[userId] = updated;
    return updated;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return InMemoryAuthRepository(config);
});
