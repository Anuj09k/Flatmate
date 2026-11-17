import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/image_check_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_setup_controller.dart';
import 'listing_setup_controller.dart';

class ListingSetupScreen extends ConsumerWidget {
  const ListingSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const strings = AppStrings();
    final config = ref.watch(appConfigProvider);
    final state = ref.watch(listingSetupControllerProvider);
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('listing_setup_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingProgress(currentStep: 5, totalSteps: 5, label: 'Your flat'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.verifyGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.verifyGreen),
              ),
              child: Text(strings.tr('flat_photo_rule_banner')),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.verifyGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            draft.locality,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _ListingStat(label: 'Monthly rent', value: '₹${draft.rent}')),
                        const SizedBox(width: 12),
                        Expanded(child: _ListingStat(label: 'Deposit', value: '₹${draft.deposit}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Interior photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${draft.interiorPhotos.length} uploaded · minimum ${config.minListerInteriorPhotos}',
                style: const TextStyle(color: AppTheme.mutedInk)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final idx = draft.interiorPhotos.length + 1;
                ref.read(listingSetupControllerProvider.notifier).addInteriorPhoto(
                      ImageCheckInput(
                        id: 'interior_$idx',
                        url: 'https://example.com/interior_$idx.jpg',
                        // Distinct perceptual hashes so each room passes pHash check
                        perceptualHash: idx == 1 ? 0x0000000000000000 : 0x000FFFFFFFFFFFFF,
                        exifLat: draft.latitude,
                        exifLng: draft.longitude,
                      ),
                    );
              },
              icon: const Icon(Icons.meeting_room_outlined),
              label: const Text('Add Distinct Interior Room Photo'),
            ),
            const SizedBox(height: 20),
            Text(
              'Exterior photo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${draft.exteriorPhotos.length} uploaded · minimum ${config.minListerExteriorPhotos}',
                style: const TextStyle(color: AppTheme.mutedInk)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final idx = draft.exteriorPhotos.length + 1;
                ref.read(listingSetupControllerProvider.notifier).addExteriorPhoto(
                      ImageCheckInput(
                        id: 'exterior_$idx',
                        url: 'https://example.com/exterior_$idx.jpg',
                        perceptualHash: 0x00000F0F0F0F0F0F,
                        exifLat: draft.latitude,
                        exifLng: draft.longitude,
                      ),
                    );
              },
              icon: const Icon(Icons.apartment_outlined),
              label: const Text('Add Exterior Building Photo'),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final verified =
                          await ref.read(listingSetupControllerProvider.notifier).publishListing();
                      if (!verified) return;

                      final profileDraft = ref.read(profileSetupControllerProvider);
                      final user = ref.read(authControllerProvider).user;
                      await ref.read(profileRepositoryProvider).saveAndValidateProfile(
                            profile: UserProfile(
                              userId: user?.id ?? 'lister_1',
                              name: profileDraft.name,
                              bio: profileDraft.bio,
                              occupation: profileDraft.occupation,
                              collegeOrCompany: profileDraft.collegeOrCompany,
                              languages: profileDraft.languages,
                              profilePhotos: profileDraft.photos,
                              promptAnswers: profileDraft.prompts,
                            ),
                            role: UserRole.lister,
                            listerFlatPhotosVerified: true,
                          );
                      if (context.mounted) context.go('/onboarding-complete');
                    },
              child: Text(strings.tr('publish_profile')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingStat extends StatelessWidget {
  final String label;
  final String value;

  const _ListingStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.mutedInk)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
