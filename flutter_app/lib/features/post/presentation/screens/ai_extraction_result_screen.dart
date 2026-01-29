import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../domain/models/post.dart';
import '../../domain/models/category.dart';

class AiExtractionResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> extractedData;

  const AiExtractionResultScreen({
    super.key,
    required this.extractedData,
  });

  @override
  ConsumerState<AiExtractionResultScreen> createState() =>
      _AiExtractionResultScreenState();
}

class _AiExtractionResultScreenState
    extends ConsumerState<AiExtractionResultScreen> {
  late Map<String, dynamic> _result;
  late List<String> _images;
  late String? _sourceUrl;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _rewardController;

  PostType _postType = PostType.lost;
  String _category = 'other';

  @override
  void initState() {
    super.initState();
    _result = widget.extractedData['result'] ?? {};
    _images = List<String>.from(widget.extractedData['images'] ?? []);
    _sourceUrl = widget.extractedData['sourceUrl'];

    _titleController = TextEditingController(text: _result['title'] ?? '');
    _descriptionController =
        TextEditingController(text: _result['clean_description'] ?? '');

    final location = _result['location'];
    String locationText = '';
    if (location != null) {
      final parts = <String>[];
      if (location['address'] != null) parts.add(location['address']);
      if (location['city'] != null) parts.add(location['city']);
      if (location['country'] != null) parts.add(location['country']);
      locationText = parts.join(', ');
    }
    _locationController = TextEditingController(text: locationText);
    _rewardController = TextEditingController(text: _result['reward'] ?? '');

    _postType = _result['post_type'] == 'FOUND' ? PostType.found : PostType.lost;
    _category = _result['category'] ?? 'other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  void _proceedToCreate() {
    context.push(AppRoutes.createPost, extra: {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _category,
      'postType': _postType,
      'location': _locationController.text,
      'reward': _rewardController.text,
      'images': _images,
      'sourceUrl': _sourceUrl,
      'aiMetadata': {
        'isAIGenerated': true,
        'confidenceScores': _result['confidence_scores'],
        'sourceType': _images.isNotEmpty ? 'screenshot' : 'text',
        'originalText': _result['original_text'],
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceScores =
        Map<String, double>.from(_result['confidence_scores'] ?? {});

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
                      Icons.arrow_back_ios_new,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              title: GradientText(
                text: 'Review Extraction',
                gradient: AppColors.secondaryGradient,
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
                    // Success header
                    _GlassSuccessCard()
                        .animate()
                        .fadeIn()
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 28),

                    // Post type selector
                    GradientText(
                      text: 'Post Type',
                      gradient: AppColors.primaryGradient,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GlassTypeSelector(
                            label: 'Lost',
                            icon: Icons.search,
                            isSelected: _postType == PostType.lost,
                            gradient: AppColors.lostGradient,
                            color: AppColors.lost,
                            onTap: () => setState(() => _postType = PostType.lost),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _GlassTypeSelector(
                            label: 'Found',
                            icon: Icons.where_to_vote,
                            isSelected: _postType == PostType.found,
                            gradient: AppColors.foundGradient,
                            color: AppColors.found,
                            onTap: () => setState(() => _postType = PostType.found),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // Category selector
                    GradientText(
                      text: 'Category',
                      gradient: AppColors.secondaryGradient,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ItemCategory.all.map((cat) {
                        final isSelected = _category == cat.id;
                        return _GlassCategoryChip(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () => setState(() => _category = cat.id),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    // Title field
                    _GlassConfidenceField(
                      label: 'Title',
                      confidence: confidenceScores['title'],
                      child: GlassTextField(
                        controller: _titleController,
                        hint: 'Brief title for the item',
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 18),

                    // Description field
                    _GlassConfidenceField(
                      label: 'Description',
                      confidence: confidenceScores['description'],
                      child: GlassContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: 16,
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Detailed description of the item',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark.withOpacity(0.6)
                                  : AppColors.textSecondaryLight.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 18),

                    // Location field
                    _GlassConfidenceField(
                      label: 'Location',
                      confidence: confidenceScores['location'],
                      child: GlassTextField(
                        controller: _locationController,
                        hint: 'Where was it lost/found?',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 18),

                    // Reward field (only for lost items)
                    if (_postType == PostType.lost) ...[
                      GlassTextField(
                        controller: _rewardController,
                        label: 'Reward (Optional)',
                        hint: 'Any reward offered?',
                        prefixIcon: Icons.card_giftcard,
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 18),
                    ],

                    // Tags
                    if (_result['tags'] != null &&
                        (_result['tags'] as List).isNotEmpty) ...[
                      GradientText(
                        text: 'Suggested Tags',
                        gradient: AppColors.primaryGradient,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: (_result['tags'] as List).map((tag) {
                          return _GlassTag(tag: tag.toString());
                        }).toList(),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 28),
                    ],

                    // Action buttons
                    GlassButton(
                      text: 'Continue to Post',
                      onPressed: _proceedToCreate,
                      gradient: _postType == PostType.lost
                          ? AppColors.lostGradient
                          : AppColors.foundGradient,
                      icon: Icons.arrow_forward,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 14),

                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Re-extract',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),

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

class _GlassSuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
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
                  text: 'AI Extraction Complete',
                  gradient: AppColors.successGradient,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and edit the extracted information below',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.success.withOpacity(0.8),
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

class _GlassTypeSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final LinearGradient gradient;
  final Color color;
  final VoidCallback onTap;

  const _GlassTypeSelector({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.gradient,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.dividerLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCategoryChip extends StatelessWidget {
  final ItemCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : AppColors.dividerLight),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassConfidenceField extends StatelessWidget {
  final String label;
  final double? confidence;
  final Widget child;

  const _GlassConfidenceField({
    required this.label,
    this.confidence,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GradientText(
              text: label,
              gradient: AppColors.primaryGradient,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (confidence != null) ...[
              const Spacer(),
              _GlassConfidenceBadge(confidence: confidence!),
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _GlassConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _GlassConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toInt();
    final gradient = confidence >= 0.8
        ? AppColors.successGradient
        : confidence >= 0.5
            ? AppColors.secondaryGradient
            : AppColors.errorGradient;
    final icon = confidence >= 0.8
        ? Icons.verified
        : confidence >= 0.5
            ? Icons.help_outline
            : Icons.warning_amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final String tag;

  const _GlassTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Text(
              '#',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            tag,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
