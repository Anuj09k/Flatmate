import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contact_blocker.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_setup_controller.dart';

class PromptsSetupScreen extends ConsumerStatefulWidget {
  const PromptsSetupScreen({super.key});

  @override
  ConsumerState<PromptsSetupScreen> createState() => _PromptsSetupScreenState();
}

class _PromptsSetupScreenState extends ConsumerState<PromptsSetupScreen> {
  final List<TextEditingController> _controllers =
      List.generate(3, (_) => TextEditingController());
  final List<String> _selectedIds = ['daily_1', 'living_1', 'about_1'];
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const strings = AppStrings();
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authControllerProvider);
    final role = authState.user?.role ?? UserRole.seeker;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('prompts_setup_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingProgress(currentStep: 4, totalSteps: 5, label: 'Show your style'),
            Text(
              'Answer 3 prompts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'A little detail helps future flatmates picture everyday life with you.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < config.promptsPerProfile; i++) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('PROMPT ${i + 1}', style: Theme.of(context).textTheme.labelMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ProfileRepository.defaultCatalog.firstWhere((p) => p.id == _selectedIds[i]).heading,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controllers[i],
                        minLines: 2,
                        maxLines: 4,
                        maxLength: config.promptAnswerMaxChars,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Write a short, specific answer',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (ContactBlocker.containsContactDetails(_controllers[i].text))
                        Text(
                          strings.tr('contact_nudge'),
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () async {
                final answers = <PromptAnswer>[];
                for (var i = 0; i < config.promptsPerProfile; i++) {
                  final text = _controllers[i].text.trim();
                  if (text.isEmpty || text.length > config.promptAnswerMaxChars) {
                    setState(() => _error = 'Please answer all 3 prompts (max 150 chars each).');
                    return;
                  }
                  if (ContactBlocker.containsContactDetails(text)) {
                    setState(() => _error = strings.tr('contact_nudge'));
                    return;
                  }
                  answers.add(PromptAnswer(promptId: _selectedIds[i], answer: text, position: i));
                }

                ref.read(profileSetupControllerProvider.notifier).setPrompts(answers);

                if (role == UserRole.lister) {
                  context.go('/listing-setup');
                } else {
                  final draft = ref.read(profileSetupControllerProvider);
                  await ref.read(profileRepositoryProvider).saveAndValidateProfile(
                        profile: UserProfile(
                          userId: authState.user?.id ?? 'seeker_1',
                          name: draft.name,
                          bio: draft.bio,
                          occupation: draft.occupation,
                          collegeOrCompany: draft.collegeOrCompany,
                          languages: draft.languages,
                          profilePhotos: draft.photos,
                          promptAnswers: answers,
                        ),
                        role: UserRole.seeker,
                        listerFlatPhotosVerified: false,
                      );
                  if (context.mounted) context.go('/onboarding-complete');
                }
              },
              child: Text(role == UserRole.lister ? 'Next: Flat Details & Photos' : 'Finish Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
