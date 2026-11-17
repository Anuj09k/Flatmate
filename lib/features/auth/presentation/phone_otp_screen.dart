import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onboarding_progress.dart';
import 'auth_controller.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phoneCtrl = TextEditingController(text: '+919820012345');
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController(text: '123456');
  DateTime _dob = DateTime(1999, 6, 15);
  String _gender = 'woman';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const strings = AppStrings();
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('phone_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const OnboardingProgress(currentStep: 1, totalSteps: 5, label: 'Your details'),
            Text(
              strings.tr('phone_subtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: strings.tr('phone_label'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: strings.tr('email_label'),
                prefixIcon: const Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'woman', child: Text('Woman')),
                DropdownMenuItem(value: 'man', child: Text('Man')),
                DropdownMenuItem(value: 'lgbtq', child: Text('LGBTQ')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'woman'),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cake_outlined, color: AppTheme.chatBlue),
                title: Text(strings.tr('dob_label')),
                subtitle: Text(
                  '${_dob.day.toString().padLeft(2, '0')}/${_dob.month.toString().padLeft(2, '0')}/${_dob.year}',
                ),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dob,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dob = picked);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '6-digit verification code',
                helperText: 'Demo code: 123456',
                prefixIcon: Icon(Icons.password_outlined),
              ),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 12),
              Text(authState.error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final ok = await ref.read(authControllerProvider.notifier).signUpWithOtp(
                            phone: _phoneCtrl.text.trim(),
                            otp: _otpCtrl.text.trim(),
                            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                            dateOfBirth: _dob,
                            gender: _gender,
                          );
                      if (ok && context.mounted) {
                        context.go('/role');
                      }
                    },
              child: Text(strings.tr('verify_otp')),
            ),
          ],
        ),
      ),
    );
  }
}
