import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class OnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String label;

  const OnboardingProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '$currentStep of $totalSteps',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppTheme.lightBorder,
              color: AppTheme.sunshine,
            ),
          ),
        ],
      ),
    );
  }
}
