import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isCheckingVerification = false;
  bool _isResending = false;

  Future<void> _resend() async {
    final user = ref.read(authNotifierProvider).valueOrNull?.user;
    if (user == null || user.email == null) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail(user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isCheckingVerification = true);
    try {
      ref.invalidate(authNotifierProvider);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState?.status == AuthStatus.authenticated) {
        context.go('/feed');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please check your inbox.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingVerification = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent a verification link to your email. Check your inbox and click the link to continue.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppButton(
                label: _isCheckingVerification ? 'Checking...' : "I've Verified — Continue",
                onPressed: _isCheckingVerification ? null : _checkVerification,
                isLoading: _isCheckingVerification,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend Email'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.hint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
