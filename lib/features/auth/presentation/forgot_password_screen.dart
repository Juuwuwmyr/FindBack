import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/auth/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _buildSuccessCard() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Forgot your password?',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we will send you a link to reset your password.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send Reset Link',
            onPressed: _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.success),
        const SizedBox(height: 24),
        const Text(
          'Check Your Email',
          style: AppTextStyles.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to ${_emailCtrl.text.trim()}. Check your inbox and follow the instructions.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Back to Sign In',
          onPressed: () => context.go('/auth/login'),
          variant: AppButtonVariant.secondary,
        ),
      ],
    );
  }
}
