import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../domain/app_user.dart';
import 'auth_controller.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const strings = AppStrings();
    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('choose_role_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingProgress(currentStep: 2, totalSteps: 5, label: 'Choose your path'),
            Text(
              'What brings you here?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You can update this later in your profile.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              title: strings.tr('role_lister_title'),
              subtitle: strings.tr('role_lister_sub'),
              accent: AppTheme.verifyGreen,
              icon: Icons.home_work_outlined,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).selectRole(UserRole.lister);
                if (context.mounted) context.go('/profile-setup');
              },
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: strings.tr('role_seeker_title'),
              subtitle: strings.tr('role_seeker_sub'),
              accent: AppTheme.chatBlue,
              icon: Icons.person_search_outlined,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).selectRole(UserRole.seeker);
                if (context.mounted) context.go('/profile-setup');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1.5),
          color: accent.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: AppTheme.mutedInk)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: accent, size: 18),
          ],
        ),
      ),
    );
  }
}
