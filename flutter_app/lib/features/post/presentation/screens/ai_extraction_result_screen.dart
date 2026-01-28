import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/post.dart';
import '../../domain/models/category.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';

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

    // Initialize controllers with extracted data
    _titleController = TextEditingController(text: _result['title'] ?? '');
    _descriptionController =
        TextEditingController(text: _result['clean_description'] ?? '');
    
    // Parse location
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

    // Set post type
    _postType = _result['post_type'] == 'FOUND' ? PostType.found : PostType.lost;
    
    // Set category
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
    // Navigate to create post with pre-filled data
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
    final confidenceScores =
        Map<String, double>.from(_result['confidence_scores'] ?? {});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extraction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Extraction Complete',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                        ),
                        Text(
                          'Review and edit the extracted information below',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Post type selector
            Text(
              'Post Type',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeSelector(
                    label: 'Lost',
                    icon: Icons.search,
                    isSelected: _postType == PostType.lost,
                    color: AppColors.lost,
                    onTap: () => setState(() => _postType = PostType.lost),
                    confidence: confidenceScores['post_type'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeSelector(
                    label: 'Found',
                    icon: Icons.where_to_vote,
                    isSelected: _postType == PostType.found,
                    color: AppColors.found,
                    onTap: () => setState(() => _postType = PostType.found),
                    confidence: confidenceScores['post_type'],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // Category selector
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.all.map((cat) {
                final isSelected = _category == cat.id;
                return InkWell(
                  onTap: () => setState(() => _category = cat.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.dividerLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color:
                                    isSelected ? Colors.white : AppColors.textPrimaryLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Title field
            _ConfidenceField(
              label: 'Title',
              confidence: confidenceScores['title'],
              child: AppTextField(
                controller: _titleController,
                hint: 'Brief title for the item',
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Description field
            _ConfidenceField(
              label: 'Description',
              confidence: confidenceScores['description'],
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Detailed description of the item',
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 16),

            // Location field
            _ConfidenceField(
              label: 'Location',
              confidence: confidenceScores['location'],
              child: AppTextField(
                controller: _locationController,
                hint: 'Where was it lost/found?',
                prefixIcon: Icons.location_on_outlined,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 16),

            // Reward field (only for lost items)
            if (_postType == PostType.lost) ...[
              AppTextField(
                controller: _rewardController,
                label: 'Reward (Optional)',
                hint: 'Any reward offered?',
                prefixIcon: Icons.card_giftcard,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),
            ],

            // Tags
            if (_result['tags'] != null &&
                (_result['tags'] as List).isNotEmpty) ...[
              Text(
                'Suggested Tags',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_result['tags'] as List).map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                    labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 24),
            ],

            // Action buttons
            GradientButton(
              text: 'Continue to Post',
              onPressed: _proceedToCreate,
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Re-extract'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final double? confidence;

  const _TypeSelector({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.dividerLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondaryLight,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? color : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceField extends StatelessWidget {
  final String label;
  final double? confidence;
  final Widget child;

  const _ConfidenceField({
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
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (confidence != null) ...[
              const Spacer(),
              _ConfidenceBadge(confidence: confidence!),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? AppColors.success
        : confidence >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence >= 0.8
                ? Icons.verified
                : confidence >= 0.5
                    ? Icons.help_outline
                    : Icons.warning_amber,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
