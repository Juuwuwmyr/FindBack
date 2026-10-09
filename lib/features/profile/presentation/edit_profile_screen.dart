import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';
import '../domain/profile_provider.dart';
import '../../auth/domain/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  ProfileModel? _originalProfile;
  String? _currentAvatarUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final profile = ref.read(ownProfileProvider).valueOrNull;
    if (profile != null) {
      setState(() {
        _originalProfile = profile;
        _nameCtrl.text = profile.displayName;
        _bioCtrl.text = profile.bio ?? '';
        _locationCtrl.text = profile.locationText ?? '';
        _currentAvatarUrl = profile.avatarUrl;
      });
    }
  }

  bool get _hasChanges {
    if (_originalProfile == null) return false;
    return _nameCtrl.text.trim() != _originalProfile!.displayName ||
        _bioCtrl.text.trim() != (_originalProfile!.bio ?? '') ||
        _locationCtrl.text.trim() != (_originalProfile!.locationText ?? '') ||
        _currentAvatarUrl != _originalProfile!.avatarUrl;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    Navigator.of(context).pop(); // close bottom sheet
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final compressedPath = '${picked.path}_compressed.jpg';
      // compressAndGetFile returns XFile? in flutter_image_compress 2.x
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        compressedPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );
      final fileToUpload =
          compressed != null ? File(compressed.path) : File(picked.path);
      final url = await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: userId,
            file: fileToUpload,
          );
      if (!mounted) return;
      setState(() => _currentAvatarUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => _pickAndUploadAvatar(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickAndUploadAvatar(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(profileEditProvider.notifier);
      if (_originalProfile != null) {
        notifier.startEditing(_originalProfile!);
      }
      notifier.updateDisplayName(_nameCtrl.text.trim());
      notifier.updateBio(_bioCtrl.text.trim());
      notifier.updateLocationText(_locationCtrl.text.trim());
      if (_currentAvatarUrl != null) {
        notifier.updateAvatarUrl(_currentAvatarUrl!);
      }
      await notifier.save(userId);
      if (!mounted) return;
      ref.invalidate(ownProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch ownProfileProvider to load when it first resolves
    ref.listen(ownProfileProvider, (_, next) {
      if (_originalProfile == null) {
        next.whenData((profile) {
          if (profile != null && mounted) {
            setState(() {
              _originalProfile = profile;
              _nameCtrl.text = profile.displayName;
              _bioCtrl.text = profile.bio ?? '';
              _locationCtrl.text = profile.locationText ?? '';
              _currentAvatarUrl = profile.avatarUrl;
            });
          }
        });
      }
    });

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // ignore: use_build_context_synchronously
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  // ignore: use_build_context_synchronously
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor:
                              AppColors.primaryLight.withValues(alpha: 0.2),
                          child: _isUploadingAvatar
                              ? const CircularProgressIndicator()
                              : (_currentAvatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _currentAvatarUrl!,
                                        width: 128,
                                        height: 128,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          size: 64,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 64,
                                      color: AppColors.primary,
                                    )),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap:
                                _isUploadingAvatar ? null : _showAvatarOptions,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Display Name',
                    hint: 'Your name',
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Display name is required';
                      }
                      if (v.trim().length > 100) {
                        return 'Must be 100 characters or less';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _bioCtrl,
                    label: 'Bio',
                    hint: 'Tell people about yourself...',
                    maxLines: 4,
                    maxLength: 280,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _locationCtrl,
                    label: 'Location',
                    hint: 'e.g. Makati City, Metro Manila',
                    maxLength: 200,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Save Changes',
                    onPressed: _hasChanges && !_isSaving ? _save : null,
                    isLoading: _isSaving,
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
