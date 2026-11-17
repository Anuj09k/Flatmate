import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/image_check_service.dart';
import '../../../core/utils/contact_blocker.dart';
import '../domain/user_profile.dart';

class ProfileDraftState {
  final String name;
  final String bio;
  final String occupation;
  final String collegeOrCompany;
  final List<String> languages;
  final List<ImageCheckInput> photos;
  final List<PromptAnswer> prompts;
  final bool bioHasContactWarning;

  const ProfileDraftState({
    this.name = '',
    this.bio = '',
    this.occupation = '',
    this.collegeOrCompany = '',
    this.languages = const ['English', 'Hindi'],
    this.photos = const [],
    this.prompts = const [],
    this.bioHasContactWarning = false,
  });

  ProfileDraftState copyWith({
    String? name,
    String? bio,
    String? occupation,
    String? collegeOrCompany,
    List<String>? languages,
    List<ImageCheckInput>? photos,
    List<PromptAnswer>? prompts,
    bool? bioHasContactWarning,
  }) {
    return ProfileDraftState(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      collegeOrCompany: collegeOrCompany ?? this.collegeOrCompany,
      languages: languages ?? this.languages,
      photos: photos ?? this.photos,
      prompts: prompts ?? this.prompts,
      bioHasContactWarning: bioHasContactWarning ?? this.bioHasContactWarning,
    );
  }
}

class ProfileSetupController extends StateNotifier<ProfileDraftState> {
  ProfileSetupController() : super(const ProfileDraftState());

  void updateBasicInfo({
    String? name,
    String? bio,
    String? occupation,
    String? collegeOrCompany,
  }) {
    final nextBio = bio ?? state.bio;
    state = state.copyWith(
      name: name,
      bio: nextBio,
      occupation: occupation,
      collegeOrCompany: collegeOrCompany,
      bioHasContactWarning: ContactBlocker.containsContactDetails(nextBio),
    );
  }

  void addSampleProfilePhoto(ImageCheckInput photo) {
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  void setPrompts(List<PromptAnswer> prompts) {
    state = state.copyWith(prompts: prompts);
  }
}

final profileSetupControllerProvider =
    StateNotifierProvider<ProfileSetupController, ProfileDraftState>((ref) {
  return ProfileSetupController();
});
