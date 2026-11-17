import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/image_check_service.dart';
import '../../../core/utils/contact_blocker.dart';
import '../../auth/domain/app_user.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  final AppConfig config;
  final ImageCheckService imageChecker;
  final Map<String, UserProfile> _profiles = {};

  ProfileRepository({required this.config, required this.imageChecker});

  static const List<PromptItem> defaultCatalog = [
    PromptItem(id: 'daily_1', groupName: 'Daily life', heading: 'A normal weekday at home looks like...'),
    PromptItem(id: 'daily_2', groupName: 'Daily life', heading: 'My ideal weekend at home is...'),
    PromptItem(id: 'living_1', groupName: 'Living together', heading: 'My flatmate rule that never changes is...'),
    PromptItem(id: 'living_3', groupName: 'Living together', heading: 'Cleaning in my world means...'),
    PromptItem(id: 'about_1', groupName: 'About me', heading: 'You will find me at home when I am...'),
    PromptItem(id: 'flags_1', groupName: 'Green flags and deal breakers', heading: 'My biggest green flag is...'),
    PromptItem(id: 'lister_1', groupName: 'For listers', heading: 'What makes this flat special is...', listerOnly: true),
  ];

  /// Enforces Section 6 & 12 profile rules on save:
  /// - No contact details in bio or prompts
  /// - 2..6 profile photos, no group photo first, not all wearing sunglasses
  /// - 3 prompts, each <= 150 chars
  /// - If Lister, flat photos must be verified before going live
  Future<UserProfile> saveAndValidateProfile({
    required UserProfile profile,
    required UserRole role,
    required bool listerFlatPhotosVerified,
  }) async {
    if (ContactBlocker.containsContactDetails(profile.bio)) {
      throw StateError('CONTACT_DETAILS_BLOCKED: Contact details are not allowed in bio.');
    }

    final photos = profile.profilePhotos;
    if (photos.length < config.minProfilePhotos || photos.length > config.maxProfilePhotos) {
      throw StateError(
        'PROFILE_PHOTO_COUNT_INVALID: Must upload between ${config.minProfilePhotos} and ${config.maxProfilePhotos} profile photos.',
      );
    }

    if (photos.first.isGroupPhoto) {
      throw StateError('GROUP_PHOTO_FIRST_NOT_ALLOWED: First photo cannot be a group photo.');
    }

    if (photos.every((p) => p.hasSunglasses)) {
      throw StateError('SUNGLASSES_ALL_PHOTOS: Cannot wear sunglasses in all profile photos.');
    }

    final acceptedPhotos = <ImageCheckInput>[];
    for (final photo in photos) {
      final res = await imageChecker.checkPhoto(
        candidate: photo,
        existingUserPhotos: acceptedPhotos,
      );
      if (!res.isApproved) {
        throw StateError('PROFILE_PHOTO_REJECTED: ${res.message}');
      }
      acceptedPhotos.add(photo);
    }

    if (profile.promptAnswers.length != config.promptsPerProfile) {
      throw StateError(
        'PROMPT_COUNT_INVALID: Please answer ${config.promptsPerProfile} prompts.',
      );
    }

    for (final ans in profile.promptAnswers) {
      if (ans.answer.trim().isEmpty || ans.answer.length > config.promptAnswerMaxChars) {
        throw StateError(
          'PROMPT_ANSWER_LENGTH_INVALID: Prompt answers must be 1–${config.promptAnswerMaxChars} characters.',
        );
      }
      if (ContactBlocker.containsContactDetails(ans.answer)) {
        throw StateError(
          'CONTACT_DETAILS_BLOCKED: Contact details are not allowed in prompt answers.',
        );
      }
    }

    if (role == UserRole.lister && !listerFlatPhotosVerified) {
      throw StateError(
        'LISTER_FLAT_PHOTOS_REQUIRED: Listers cannot go live without at least ${config.minListerInteriorPhotos} non-duplicate interior photos and ${config.minListerExteriorPhotos} exterior photo.',
      );
    }

    final saved = UserProfile(
      userId: profile.userId,
      name: profile.name,
      bio: profile.bio,
      occupation: profile.occupation,
      collegeOrCompany: profile.collegeOrCompany,
      languages: profile.languages,
      profilePhotos: acceptedPhotos,
      promptAnswers: profile.promptAnswers,
      membershipHidden: profile.membershipHidden,
      onboardingCompleted: true,
    );
    _profiles[saved.userId] = saved;
    return saved;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    config: ref.watch(appConfigProvider),
    imageChecker: ref.watch(imageCheckServiceProvider),
  );
});
