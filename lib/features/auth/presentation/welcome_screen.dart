import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const strings = AppStrings();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.sunshine,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.home_rounded, color: AppTheme.ink, size: 27),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'flatmate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                        ),
                        const Spacer(),
                        const _CityTag(),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight < 700 ? 32 : 52),
                    Text(
                      'Home starts\nwith a good fit.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: constraints.maxWidth < 420 ? 38 : 48,
                            height: 1.04,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Meet people who share your rhythm, your house rules, and your idea of a good home.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.mutedInk,
                            height: 1.45,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 28),
                    const _PromptPreviewCard(),
                    const SizedBox(height: 20),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FeatureTag(icon: Icons.verified_outlined, label: 'Verified people'),
                        _FeatureTag(icon: Icons.chat_bubble_outline, label: 'Real prompts'),
                        _FeatureTag(icon: Icons.location_on_outlined, label: 'Mumbai first'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/auth'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(strings.tr('get_started')),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'A better way to share a home.',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.mutedInk,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptPreviewCard extends StatelessWidget {
  const _PromptPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.sunshine,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.ink),
              const SizedBox(width: 7),
              Text(
                'A LITTLE FLATMATE PROMPT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '“A good shared home feels like…”',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.ink,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 9),
          Text(
            'Everyone can be themselves, and nobody leaves dishes in the sink.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.76),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.ink),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.ink)),
        ],
      ),
    );
  }
}

class _CityTag extends StatelessWidget {
  const _CityTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.coral),
          const SizedBox(width: 4),
          Text(
            'MUMBAI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
