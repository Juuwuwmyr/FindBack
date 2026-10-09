import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    final authValue = ref.read(authNotifierProvider);
    if (authValue.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authValue.error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      context.go('/auth/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/auth/login'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.manage_search, size: 64, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Join FindBack',
                    style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create your account to get started',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Display Name',
                    hint: 'How you appear to others',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Display name is required';
                      if (v.trim().length > 100) return 'Display name must be 100 characters or less';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: 'At least 8 characters',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmCtrl,
                    label: 'Confirm Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?', style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
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

