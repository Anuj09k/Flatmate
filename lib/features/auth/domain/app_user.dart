import 'package:equatable/equatable.dart';

enum UserRole { lister, seeker, admin }

enum AccountStatus { limited, active, locked, suspended }

class AppUser extends Equatable {
  final String id;
  final String phone;
  final String? email;
  final UserRole role;
  final DateTime dateOfBirth;
  final String gender;
  final DateTime createdAt;
  final AccountStatus status;
  final DateTime verificationDeadline;
  final DateTime? lockEndsAt;

  const AppUser({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    required this.dateOfBirth,
    required this.gender,
    required this.createdAt,
    required this.status,
    required this.verificationDeadline,
    this.lockEndsAt,
  });

  AppUser copyWith({
    UserRole? role,
    AccountStatus? status,
    DateTime? verificationDeadline,
    DateTime? lockEndsAt,
  }) {
    return AppUser(
      id: id,
      phone: phone,
      email: email,
      role: role ?? this.role,
      dateOfBirth: dateOfBirth,
      gender: gender,
      createdAt: createdAt,
      status: status ?? this.status,
      verificationDeadline: verificationDeadline ?? this.verificationDeadline,
      lockEndsAt: lockEndsAt ?? this.lockEndsAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        email,
        role,
        dateOfBirth,
        gender,
        createdAt,
        status,
        verificationDeadline,
        lockEndsAt,
      ];
}
