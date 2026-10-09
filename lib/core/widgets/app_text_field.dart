import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.validator,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final IconData? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.hint,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
