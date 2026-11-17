import 'package:equatable/equatable.dart';
import '../../../core/services/image_check_service.dart';

class PromptItem extends Equatable {
  final String id;
  final String groupName;
  final String heading;
  final bool listerOnly;

  const PromptItem({
    required this.id,
    required this.groupName,
    required this.heading,
    this.listerOnly = false,
  });

  @override
  List<Object?> get props => [id, groupName, heading, listerOnly];
}

class PromptAnswer extends Equatable {
  final String promptId;
  final String answer;
  final int position;

  const PromptAnswer({
    required this.promptId,
    required this.answer,
    required this.position,
  });

  @override
  List<Object?> get props => [promptId, answer, position];
}

class UserProfile extends Equatable {
  final String userId;
  final String name;
  final String bio;
  final String occupation;
  final String collegeOrCompany;
  final List<String> languages;
  final List<ImageCheckInput> profilePhotos;
  final List<PromptAnswer> promptAnswers;
  final bool membershipHidden;
  final bool onboardingCompleted;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.bio,
    required this.occupation,
    required this.collegeOrCompany,
    required this.languages,
    required this.profilePhotos,
    required this.promptAnswers,
    this.membershipHidden = false,
    this.onboardingCompleted = false,
  });

  @override
  List<Object?> get props => [
        userId,
        name,
        bio,
        occupation,
        collegeOrCompany,
        languages,
        profilePhotos,
        promptAnswers,
        membershipHidden,
        onboardingCompleted,
      ];
}
