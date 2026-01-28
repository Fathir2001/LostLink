import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/category.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _rewardController = TextEditingController();

  PostType _postType = PostType.lost;
  String _category = 'other';
  final List<String> _images = [];
  DateTime? _lostFoundDate;
  bool _isSubmitting = false;

  Map<String, dynamic>? _prefilledData;
  Map<String, dynamic>? _aiMetadata;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for pre-filled data from AI extraction
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null && _prefilledData == null) {
      _prefilledData = extra;
      _titleController.text = extra['title'] ?? '';
      _descriptionController.text = extra['description'] ?? '';
      _locationController.text = extra['location'] ?? '';
      _rewardController.text = extra['reward'] ?? '';
      _category = extra['category'] ?? 'other';
      _postType = extra['postType'] ?? PostType.lost;
      _images.addAll(List<String>.from(extra['images'] ?? []));
      _aiMetadata = extra['aiMetadata'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images.map((e) => e.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _images.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lostFoundDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _lostFoundDate = date;
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final postRepo = ref.read(postRepositoryProvider);

      // Upload images first
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await postRepo.uploadImages(_images);
      }

      // Create post data
      final postData = {
        'type': _postType == PostType.found ? 'FOUND' : 'LOST',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'images': imageUrls,
        'location': {
          'address': _locationController.text.trim(),
        },
        'lostFoundDate': _lostFoundDate?.toIso8601String(),
        'reward': _postType == PostType.lost ? _rewardController.text.trim() : null,
        'aiMetadata': _aiMetadata,
      };

      final post = await postRepo.createPost(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        context.go('/post/${post.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post type selector
              Text(
                'What do you want to post?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      label: 'I Lost Something',
                      icon: Icons.search,
                      isSelected: _postType == PostType.lost,
                      color: AppColors.lost,
                      onTap: () => setState(() => _postType = PostType.lost),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      label: 'I Found Something',
                      icon: Icons.where_to_vote,
                      isSelected: _postType == PostType.found,
                      color: AppColors.found,
                      onTap: () => setState(() => _postType = PostType.found),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              const SizedBox(height: 24),

              // Images section
              Text(
                'Photos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.asMap().entries.map((entry) {
                      return _ImageTile(
                        imagePath: entry.value,
                        onRemove: () => _removeImage(entry.key),
                      );
                    }),
                    if (_images.length < 5) ...[
                      _AddImageButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: _pickImages,
                      ),
                      const SizedBox(width: 8),
                      _AddImageButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: _takePhoto,
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Category
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.icon),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Title
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Brief title for your post',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the item in detail...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // Location
              AppTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'Where was it lost/found?',
                prefixIcon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),

              // Date
              Text(
                'Date ${_postType == PostType.lost ? 'Lost' : 'Found'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.dividerLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _lostFoundDate != null
                            ? '${_lostFoundDate!.day}/${_lostFoundDate!.month}/${_lostFoundDate!.year}'
                            : 'Select date',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _lostFoundDate != null
                                  ? AppColors.textPrimaryLight
                                  : AppColors.textTertiaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              // Reward (only for lost items)
              if (_postType == PostType.lost) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: _rewardController,
                  label: 'Reward (Optional)',
                  hint: 'Any reward you\'re offering?',
                  prefixIcon: Icons.card_giftcard,
                ).animate().fadeIn(delay: 700.ms),
              ],

              const SizedBox(height: 32),

              // Submit button
              GradientButton(
                text: 'Publish Post',
                onPressed: _submitPost,
                isLoading: _isSubmitting,
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.dividerLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        isSelected ? Colors.white : AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
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
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
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
                  size: 12,
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddImageButton({
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
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
