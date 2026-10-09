import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        );
      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: child,
        );
    }
  }
}
