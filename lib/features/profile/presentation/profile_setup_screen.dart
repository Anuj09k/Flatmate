import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/image_check_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onboarding_progress.dart';
import 'profile_setup_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _occCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _occCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const strings = AppStrings();
    final config = ref.watch(appConfigProvider);
    final draft = ref.watch(profileSetupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('profile_setup_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingProgress(currentStep: 3, totalSteps: 5, label: 'Build your profile'),
            Text(
              'About you',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (v) =>
                  ref.read(profileSetupControllerProvider.notifier).updateBasicInfo(name: v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _occCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Occupation',
                prefixIcon: Icon(Icons.work_outline),
              ),
              onChanged: (v) =>
                  ref.read(profileSetupControllerProvider.notifier).updateBasicInfo(occupation: v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orgCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'College or Company',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
              onChanged: (v) => ref
                  .read(profileSetupControllerProvider.notifier)
                  .updateBasicInfo(collegeOrCompany: v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Short bio',
                alignLabelWithHint: true,
                helperText: 'Share what it is like to live with you.',
              ),
              onChanged: (v) =>
                  ref.read(profileSetupControllerProvider.notifier).updateBasicInfo(bio: v),
            ),
            if (draft.bioHasContactWarning) ...[
              const SizedBox(height: 8),
              Text(
                strings.tr('contact_nudge'),
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Profile photos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${draft.photos.length} of ${config.maxProfilePhotos} added · minimum ${config.minProfilePhotos}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your first photo should be just you. Avoid wearing sunglasses in every photo.',
              style: TextStyle(color: AppTheme.mutedInk, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in draft.photos)
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                    label: Text(p.id),
                  ),
                if (draft.photos.length < config.maxProfilePhotos)
                  OutlinedButton.icon(
                    onPressed: () {
                      final idx = draft.photos.length + 1;
                      ref.read(profileSetupControllerProvider.notifier).addSampleProfilePhoto(
                            ImageCheckInput(
                              id: 'profile_photo_$idx',
                              url: 'https://example.com/profile_$idx.jpg',
                              perceptualHash: idx * 9876543210123,
                            ),
                          );
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add Verified Photo'),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (draft.photos.length >= config.minProfilePhotos &&
                      !draft.bioHasContactWarning &&
                      draft.name.trim().length >= 2)
                  ? () => context.go('/prompts-setup')
                  : null,
              child: const Text('Next: Pick 3 Prompts'),
            ),
          ],
        ),
      ),
    );
  }
}
