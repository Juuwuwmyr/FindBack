import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/services/storage_service.dart';
import '../data/reports_repository.dart';
import '../domain/item_report_model.dart';
import '../domain/reports_provider.dart';

IconData _categoryIcon(ItemCategory cat) {
  switch (cat) {
    case ItemCategory.electronics:
      return Icons.devices;
    case ItemCategory.documentsKeys:
      return Icons.badge;
    case ItemCategory.bagsLuggage:
      return Icons.luggage;
    case ItemCategory.clothingAccessories:
      return Icons.checkroom;
    case ItemCategory.pets:
      return Icons.pets;
    case ItemCategory.jewelry:
      return Icons.diamond;
    case ItemCategory.sportsEquipment:
      return Icons.sports_soccer;
    case ItemCategory.booksStationery:
      return Icons.menu_book;
    case ItemCategory.toys:
      return Icons.toys;
    case ItemCategory.vehicles:
      return Icons.directions_car;
    case ItemCategory.moneyCards:
      return Icons.credit_card;
    case ItemCategory.other:
      return Icons.category;
  }
}

class EditReportScreen extends ConsumerStatefulWidget {
  const EditReportScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _rewardDescCtrl = TextEditingController();

  ItemCategory _category = ItemCategory.other;
  DateTime? _dateOfIncident;
  bool _rewardOffered = false;
  List<String> _existingImageUrls = [];
  final List<File> _newImages = [];
  bool _isSaving = false;
  bool _initialized = false;
  ItemReportModel? _original;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _rewardDescCtrl.dispose();
    super.dispose();
  }

  void _initFromReport(ItemReportModel r) {
    _titleCtrl.text = r.title;
    _descCtrl.text = r.description;
    _locationCtrl.text = r.locationText;
    _rewardDescCtrl.text = r.rewardDescription ?? '';
    _category = r.category;
    _dateOfIncident = r.dateOfIncident;
    _rewardOffered = r.rewardOffered;
    _existingImageUrls = List.from(r.imageUrls);
    _original = r;
    _initialized = true;
  }

  bool get _hasChanges {
    final o = _original;
    if (o == null) return false;
    return _titleCtrl.text.trim() != o.title ||
        _descCtrl.text.trim() != o.description ||
        _locationCtrl.text.trim() != o.locationText ||
        _category != o.category ||
        _dateOfIncident != o.dateOfIncident ||
        _rewardOffered != o.rewardOffered ||
        _rewardDescCtrl.text.trim() != (o.rewardDescription ?? '') ||
        _existingImageUrls.length != o.imageUrls.length ||
        _newImages.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfIncident ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfIncident = picked);
    }
  }

  Future<void> _addImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final result = await ref.read(storageServiceProvider).pickImage(source);
    if (result != null && mounted) {
      setState(() => _newImages.add(File(result.path)));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfIncident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date of incident')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final repo = ref.read(reportsRepositoryProvider);

      // Upload new images
      final newUrls = <String>[];
      for (final file in _newImages) {
        final url = await storage.uploadReportImage(widget.id, file);
        newUrls.add(url);
      }
      final finalImageUrls = [..._existingImageUrls, ...newUrls];

      await repo.updateReport(
        widget.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        dateOfIncident: _dateOfIncident,
        locationText: _locationCtrl.text.trim(),
        rewardOffered: _rewardOffered,
        rewardDescription:
            _rewardOffered && _rewardDescCtrl.text.isNotEmpty
                ? _rewardDescCtrl.text.trim()
                : null,
        imageUrls: finalImageUrls,
      );

      ref.invalidate(reportDetailProvider(widget.id));
      ref.invalidate(reportsFeedProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailProvider(widget.id));

    return reportAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Report'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(e.toString())),
      ),
      data: (report) {
        if (!_initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_initialized && mounted) {
              setState(() => _initFromReport(report));
            }
          });
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _buildForm(context);
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final totalImages = _existingImageUrls.length + _newImages.length;
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
        appBar: AppBar(
          title: const Text('Edit Report'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _save,
                child: const Text('Save',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _titleCtrl,
                  label: 'Title',
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ItemCategory>(
                  initialValue: _category,
                  items: ItemCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Icon(_categoryIcon(c), size: 16),
                              const SizedBox(width: 8),
                              Text(c.label),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  maxLines: 5,
                  maxLength: 2000,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Date of Incident', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.hint, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _dateOfIncident == null
                              ? 'Select date'
                              : DateFormat('MMMM d, yyyy')
                                  .format(_dateOfIncident!),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationCtrl,
                  label: 'Location',
                  maxLength: 200,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _rewardOffered,
                      onChanged: (v) =>
                          setState(() => _rewardOffered = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Offer a reward?',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
                if (_rewardOffered) ...[
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _rewardDescCtrl,
                    label: 'Reward description',
                    maxLength: 200,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Photos', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._existingImageUrls.map(
                      (url) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _existingImageUrls.remove(url)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._newImages.map(
                      (file) => Stack(
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
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _newImages.remove(file)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalImages < 5)
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
                          child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: AppColors.hint),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _hasChanges ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
