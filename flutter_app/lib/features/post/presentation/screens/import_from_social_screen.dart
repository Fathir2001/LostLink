import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../data/repositories/ai_repository.dart';

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
        result = await aiRepo.extractFromTextAndImage(text, _selectedImages);
      } else if (_selectedImages.isNotEmpty) {
        result = await aiRepo.extractFromImage(_selectedImages);
      } else {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.primaryDark.withOpacity(0.2)]
                : [AppColors.backgroundLight, AppColors.primaryLight.withOpacity(0.1)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Glass App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.dividerLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                child: GlassContainer(
                  borderRadius: 12,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      size: 22,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              title: GradientText(
                text: 'Import from Social',
                gradient: AppColors.primaryGradient,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Feature Header Card
                    _GlassAICard().animate().fadeIn().slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 28),

                    // Text Input Section
                    GradientText(
                      text: 'Post Text',
                      gradient: AppColors.primaryGradient,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(4),
                      borderRadius: 16,
                      child: TextFormField(
                        controller: _textController,
                        maxLines: 6,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Paste the text from a Facebook post, WhatsApp message, or any social media post...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark.withOpacity(0.6)
                                : AppColors.textSecondaryLight.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 28),

                    // Image Upload Section
                    GradientText(
                      text: 'Screenshots / Images',
                      gradient: AppColors.secondaryGradient,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              return _GlassAddImageButton(onTap: _pickImages);
                            }
                            return _GlassImageTile(
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
                            child: _GlassUploadOption(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              onTap: _pickImages,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _GlassUploadOption(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              onTap: _takeScreenshot,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ],

                    const SizedBox(height: 28),

                    // Source URL
                    GlassTextField(
                      controller: _sourceUrlController,
                      hint: 'Link to original post for reference',
                      label: 'Source URL (Optional)',
                      prefixIcon: Icons.link,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 20),

                    // Info Note
                    _GlassInfoNote().animate().fadeIn(delay: 400.ms),

                    // Error Message
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _GlassErrorMessage(error: _error!),
                    ],

                    const SizedBox(height: 32),

                    // Process Button
                    GlassButton(
                      text: _isProcessing ? 'Processing...' : 'Extract with AI',
                      onPressed: _isProcessing ? null : _processContent,
                      gradient: AppColors.secondaryGradient,
                      icon: _isProcessing ? null : Icons.auto_awesome,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // Skip Button
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.createPost),
                        child: Text(
                          'Skip and create manually',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassAICard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  text: 'AI-Powered Extraction',
                  gradient: AppColors.primaryGradient,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste text from a social media post or upload a screenshot. Our AI will extract all the details.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassUploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassUploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 28),
        borderRadius: 16,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassImageTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _GlassImageTile({
    required this.imagePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: 110,
      height: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.errorGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

  Widget _buildImage() {
    Widget errorWidget = Container(
      decoration: BoxDecoration(
        color: AppColors.dividerLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, color: Colors.white54),
    );

    // On web, we need to handle file paths differently
    // XFile from image_picker on web gives us a blob URL
    if (kIsWeb) {
      // On web, imagePath from image_picker is a blob URL
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => errorWidget,
      );
    } else {
      // On mobile/desktop, use File
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => errorWidget,
      );
    }
  }
}

class _GlassAddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassAddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.add_photo_alternate,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            GradientText(
              text: 'Add',
              gradient: AppColors.primaryGradient,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassInfoNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We don\'t scrape or access any social media platforms. The content you paste is processed locally by our AI.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassErrorMessage extends StatelessWidget {
  final String error;

  const _GlassErrorMessage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
