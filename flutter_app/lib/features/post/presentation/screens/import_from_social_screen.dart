import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/ai_repository.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';

class ImportFromSocialScreen extends ConsumerStatefulWidget {
  const ImportFromSocialScreen({super.key});

  @override
  ConsumerState<ImportFromSocialScreen> createState() =>
      _ImportFromSocialScreenState();
}

class _ImportFromSocialScreenState
    extends ConsumerState<ImportFromSocialScreen> {
  final _textController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final List<String> _selectedImages = [];
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => e.path));
      });
    }
  }

  Future<void> _takeScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _processContent() async {
    final text = _textController.text.trim();

    if (text.isEmpty && _selectedImages.isEmpty) {
      setState(() {
        _error = 'Please paste text or upload at least one image';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      AIExtractionResult result;

      if (text.isNotEmpty && _selectedImages.isNotEmpty) {
        // Both text and images
        result = await aiRepo.extractFromTextAndImage(text, _selectedImages);
      } else if (_selectedImages.isNotEmpty) {
        // Images only
        result = await aiRepo.extractFromImage(_selectedImages);
      } else {
        // Text only
        result = await aiRepo.extractFromText(text);
      }

      if (mounted) {
        context.push(
          AppRoutes.aiExtractionResult,
          extra: {
            'result': result.toJson(),
            'images': _selectedImages,
            'sourceUrl': _sourceUrlController.text.trim(),
          },
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to process content: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Social'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.accent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Extraction',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paste text from a social media post or upload a screenshot. Our AI will extract all the details.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Text input
            Text(
              'Post Text',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Paste the text from a Facebook post, WhatsApp message, or any social media post...',
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Image upload section
            Text(
              'Screenshots / Images',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),

            // Image grid
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return _AddImageButton(
                        onTap: _pickImages,
                      );
                    }

                    return _ImageTile(
                      imagePath: _selectedImages[index],
                      onRemove: () => _removeImage(index),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 200.ms),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _pickImages,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _takeScreenshot,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ],

            const SizedBox(height: 24),

            // Source URL (optional)
            AppTextField(
              controller: _sourceUrlController,
              label: 'Source URL (Optional)',
              hint: 'Link to original post for reference',
              prefixIcon: Icons.link,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We don\'t scrape or access any social media platforms. The content you paste is processed locally by our AI.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Process button
            GradientButton(
              text: 'Extract with AI',
              onPressed: _processContent,
              isLoading: _isProcessing,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Skip button
            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.createPost),
                child: const Text('Skip and create manually'),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.imagePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: AppColors.dividerLight,
                child: const Icon(Icons.image),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: AppColors.primary),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
