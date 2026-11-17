import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/phone_otp_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/listings/presentation/listing_setup_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/profile/presentation/prompts_setup_screen.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_progress.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const PhoneOtpScreen(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/prompts-setup',
        builder: (context, state) => const PromptsSetupScreen(),
      ),
      GoRoute(
        path: '/listing-setup',
        builder: (context, state) => const ListingSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding-complete',
        builder: (context, state) => const _OnboardingCompleteScreen(),
      ),
    ],
  );
});

class _OnboardingCompleteScreen extends ConsumerWidget {
  const _OnboardingCompleteScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const strings = AppStrings();
    final user = ref.watch(authControllerProvider).user;
    final isLister = user?.role == UserRole.lister;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OnboardingProgress(currentStep: 5, totalSteps: 5, label: 'Setup complete'),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.verifyGreen.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.verifyGreen, size: 40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isLister ? AppTheme.verifyGreen : AppTheme.chatBlue)
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isLister ? AppTheme.verifyGreen : AppTheme.chatBlue),
                      ),
                      child: Text(
                        isLister
                            ? strings.tr('flat_photos_verified_badge')
                            : strings.tr('looking_for_place_badge'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your profile is ready.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify your ID within 15 days to unlock swiping and chat.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_user_outlined, color: AppTheme.verifyGreen),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Complete ID verification',
                                        style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your verification window is open for 15 days.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.mutedInk),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.visibility_outlined, color: AppTheme.chatBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Browse in limited mode',
                                        style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You can explore profiles while swiping and chat stay locked until verification.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.mutedInk),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
