import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/category.dart';

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
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

      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await postRepo.uploadImages(_images);
      }

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
          SnackBar(
            content: const Text('Post created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/post/${post.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.primaryDark.withOpacity(0.3),
                  ]
                : [
                    AppColors.backgroundLight,
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Glass App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: isDark
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                title: GradientText(
                  text: 'Create Post',
                  gradient: AppColors.primaryGradient,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GlassButton(
                      text: 'Post',
                      onPressed: _isSubmitting ? null : _submitPost,
                      isLoading: _isSubmitting,
                      width: 80,
                      height: 40,
                      borderRadius: 10,
                    ),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post type selector
                        GradientText(
                          text: 'What do you want to post?',
                          gradient: AppColors.primaryGradient,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassTypeCard(
                                label: 'I Lost Something',
                                icon: Icons.search,
                                isSelected: _postType == PostType.lost,
                                gradient: AppColors.lostGradient,
                                onTap: () => setState(() => _postType = PostType.lost),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GlassTypeCard(
                                label: 'I Found Something',
                                icon: Icons.where_to_vote,
                                isSelected: _postType == PostType.found,
                                gradient: AppColors.foundGradient,
                                onTap: () => setState(() => _postType = PostType.found),
                              ),
                            ),
                          ],
                        ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                        const SizedBox(height: 28),

                        // Images section
                        _buildSectionLabel('Photos', Icons.photo_library_outlined),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._images.asMap().entries.map((entry) {
                                return _GlassImageTile(
                                  imagePath: entry.value,
                                  onRemove: () => _removeImage(entry.key),
                                );
                              }),
                              if (_images.length < 5) ...[
                                _GlassAddImageButton(
                                  icon: Icons.photo_library,
                                  label: 'Gallery',
                                  onTap: _pickImages,
                                ),
                                const SizedBox(width: 12),
                                _GlassAddImageButton(
                                  icon: Icons.camera_alt,
                                  label: 'Camera',
                                  onTap: _takePhoto,
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 28),

                        // Category
                        _buildSectionLabel('Category', Icons.category_outlined),
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

                        const SizedBox(height: 28),

                        // Title
                        GlassTextField(
                          controller: _titleController,
                          label: 'Title',
                          hint: 'Brief title for your post',
                          prefixIcon: Icons.title,
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

                        const SizedBox(height: 20),

                        // Description
                        _buildSectionLabel('Description', Icons.description_outlined),
                        const SizedBox(height: 12),
                        GlassContainer(
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
                              hintText: 'Describe the item in detail...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
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
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 20),

                        // Location
                        GlassTextField(
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

                        const SizedBox(height: 20),

                        // Date
                        _buildSectionLabel(
                          'Date ${_postType == PostType.lost ? 'Lost' : 'Found'}',
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _selectDate,
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            borderRadius: 14,
                            child: Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.primaryGradient.createShader(bounds),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  _lostFoundDate != null
                                      ? '${_lostFoundDate!.day}/${_lostFoundDate!.month}/${_lostFoundDate!.year}'
                                      : 'Select date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _lostFoundDate != null
                                        ? (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight)
                                        : (isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        // Reward (only for lost items)
                        if (_postType == PostType.lost) ...[
                          const SizedBox(height: 20),
                          GlassTextField(
                            controller: _rewardController,
                            label: 'Reward (Optional)',
                            hint: 'Any reward you\'re offering?',
                            prefixIcon: Icons.card_giftcard,
                          ).animate().fadeIn(delay: 700.ms),
                        ],

                        const SizedBox(height: 36),

                        // Submit button
                        GlassButton(
                          text: 'Publish Post',
                          onPressed: _submitPost,
                          isLoading: _isSubmitting,
                          gradient: _postType == PostType.lost
                              ? AppColors.lostGradient
                              : AppColors.foundGradient,
                        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _GlassTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GlassTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.dividerLight),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
              textAlign: TextAlign.center,
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
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: AppColors.dividerLight,
                child: const Icon(Icons.image, color: AppColors.textSecondaryLight),
              ),
            ),
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
}

class _GlassAddImageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassAddImageButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.secondaryGradient.createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.secondary,
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
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.dividerLight),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
