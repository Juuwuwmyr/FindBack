import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/domain/auth_provider.dart';
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

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() =>
      _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _pageCtrl = PageController();
  int _currentStep = 0;

  // Step 1
  ReportType _type = ReportType.lost;
  ItemCategory _category = ItemCategory.other;
  final _titleCtrl = TextEditingController();

  // Step 2
  final _descCtrl = TextEditingController();
  DateTime? _dateOfIncident;
  final _locationCtrl = TextEditingController();
  bool _rewardOffered = false;
  final _rewardDescCtrl = TextEditingController();

  // Step 3
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  // Form keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _rewardDescCtrl.dispose();
    super.dispose();
  }

  void _nextStep1() {
    if (_step1Key.currentState!.validate()) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _currentStep = 1);
    }
  }

  void _nextStep2() {
    if (_step2Key.currentState!.validate()) {
      if (_dateOfIncident == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date of incident')),
        );
        return;
      }
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _currentStep = 2);
    }
  }

  void _prevPage() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep--);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    final result =
        await ref.read(storageServiceProvider).pickImage(source);
    if (result != null && mounted) {
      setState(() => _selectedImages.add(File(result.path)));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_dateOfIncident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date of incident')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      final repo = ref.read(reportsRepositoryProvider);
      final storage = ref.read(storageServiceProvider);
      final report = await repo.createReport(
        type: _type,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        dateOfIncident: _dateOfIncident!,
        locationText: _locationCtrl.text.trim(),
        rewardOffered: _rewardOffered,
        rewardDescription: _rewardOffered && _rewardDescCtrl.text.isNotEmpty
            ? _rewardDescCtrl.text.trim()
            : null,
        reporterId: userId,
      );
      if (_selectedImages.isNotEmpty) {
        final urls = <String>[];
        for (final file in _selectedImages) {
          final url = await storage.uploadReportImage(report.id, file);
          urls.add(url);
        }
        await repo.addImagesToReport(report.id, urls);
      }
      ref.invalidate(reportsFeedProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted!')),
      );
      context.go('/report/${report.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 0) {
              context.pop();
            } else {
              _prevPage();
            }
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildPage1();
                  case 1:
                    return _buildPage2();
                  case 2:
                    return _buildPage3();
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 1 of 3 — Item Type & Category',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.hint)),
            const SizedBox(height: 16),
            const Text('Report Type', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    label: 'LOST',
                    icon: Icons.search_off,
                    selected: _type == ReportType.lost,
                    selectedColor: AppColors.primary,
                    onTap: () =>
                        setState(() => _type = ReportType.lost),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    label: 'FOUND',
                    icon: Icons.check_circle_outline,
                    selected: _type == ReportType.found,
                    selectedColor: AppColors.success,
                    onTap: () =>
                        setState(() => _type = ReportType.found),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Category', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
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
              validator: (v) =>
                  v == null ? 'Select a category' : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _titleCtrl,
              label: 'Title',
              hint: 'Brief description of the item',
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                if (v.length > 100) return 'Max 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Next →', onPressed: _nextStep1),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 2 of 3 — Details & Location',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.hint)),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descCtrl,
              label: 'Description',
              hint:
                  'Describe the item in detail — color, brand, markings...',
              maxLines: 5,
              maxLength: 2000,
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
                  border: Border.all(
                    color: _dateOfIncident == null
                        ? AppColors.error
                        : AppColors.divider,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.hint, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _dateOfIncident == null
                          ? 'Select date (required)'
                          : DateFormat('MMMM d, yyyy')
                              .format(_dateOfIncident!),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _dateOfIncident == null
                            ? AppColors.hint
                            : AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _locationCtrl,
              label: 'Location',
              hint: 'e.g. Makati City, Metro Manila',
              maxLength: 200,
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
                hint: 'e.g. Cash reward for safe return',
                maxLength: 200,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _prevPage,
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                      label: 'Next →', onPressed: _nextStep2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Step 3 of 3 — Photos (Optional)',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.hint)),
          const SizedBox(height: 16),
          const Text('Add up to 5 photos', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedImages.map(
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
                            setState(() => _selectedImages.remove(file)),
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
              if (_selectedImages.length < 5)
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _prevPage,
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: _isSubmitting ? 'Submitting...' : 'Submit Report',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? selectedColor.withValues(alpha: 0.1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? selectedColor : AppColors.divider,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: selected ? selectedColor : AppColors.hint),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? selectedColor
                      : AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
