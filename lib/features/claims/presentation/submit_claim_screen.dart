import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/claims_repository.dart';
import '../domain/claim_model.dart';
import '../domain/claims_provider.dart';

class SubmitClaimScreen extends ConsumerStatefulWidget {
  const SubmitClaimScreen({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends ConsumerState<SubmitClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  ContactPreference _contactPref = ContactPreference.inApp;
  final _contactDetailCtrl = TextEditingController();
  final List<File> _evidenceImages = [];
  bool _isSubmitting = false;
  bool _submitAttempted = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _contactDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final xfile = await ref.read(storageServiceProvider).pickImage(source);
    if (xfile == null) return;
    setState(() => _evidenceImages.add(File(xfile.path)));
  }

  Future<void> _submit() async {
    setState(() => _submitAttempted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_evidenceImages.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      final repo = ref.read(claimsRepositoryProvider);
      await repo.submitClaim(
        reportId: widget.reportId,
        claimantId: userId,
        description: _descCtrl.text.trim(),
        evidenceFiles: _evidenceImages,
        contactPreference: _contactPref,
        contactDetail: _contactPref != ContactPreference.inApp
            ? _contactDetailCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      ref.invalidate(myClaimForReportProvider(widget.reportId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim submitted successfully!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Claim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'How claims work',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Describe why this item belongs to you and upload photos as evidence. The reporter will review your claim.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Description label
              const Text('Your Description *', style: AppTextStyles.titleSmall),

              const SizedBox(height: 8),

              // 5. Description field
              AppTextField(
                controller: _descCtrl,
                hint:
                    'Explain why this item is yours — include identifying details, purchase history, etc.',
                maxLines: 5,
                maxLength: 1000,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 7. Evidence label
              const Text('Evidence Photos * (1–5 required)',
                  style: AppTextStyles.titleSmall),

              const SizedBox(height: 8),

              // 9. Evidence image picker
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._evidenceImages.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _evidenceImages.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_evidenceImages.length < 5)
                    GestureDetector(
                      onTap: _addImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.primary),
                      ),
                    ),
                ],
              ),

              // 10. Evidence validation error
              if (_submitAttempted && _evidenceImages.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'At least 1 photo required',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),

              const SizedBox(height: 16),

              // 12. Contact preference label
              const Text('How should the reporter contact you? *',
                  style: AppTextStyles.titleSmall),

              const SizedBox(height: 8),

              // 14. Contact preference radio buttons
              Column(
                children: [
                  RadioListTile<ContactPreference>(
                    contentPadding: EdgeInsets.zero,
                    value: ContactPreference.inApp,
                    groupValue: _contactPref,
                    title: const Text('In-App Message'),
                    onChanged: (v) => setState(() => _contactPref = v!),
                  ),
                  RadioListTile<ContactPreference>(
                    contentPadding: EdgeInsets.zero,
                    value: ContactPreference.email,
                    groupValue: _contactPref,
                    title: const Text('Email'),
                    onChanged: (v) => setState(() => _contactPref = v!),
                  ),
                  RadioListTile<ContactPreference>(
                    contentPadding: EdgeInsets.zero,
                    value: ContactPreference.phone,
                    groupValue: _contactPref,
                    title: const Text('Phone'),
                    onChanged: (v) => setState(() => _contactPref = v!),
                  ),
                ],
              ),

              // 15. Contact detail field (shown when not inApp)
              if (_contactPref != ContactPreference.inApp)
                AppTextField(
                  controller: _contactDetailCtrl,
                  label: _contactPref == ContactPreference.email
                      ? 'Email Address'
                      : 'Phone Number',
                  keyboardType: _contactPref == ContactPreference.email
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Contact detail required';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 32),

              // 17. Submit button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Submit Claim',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
