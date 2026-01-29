import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../post/data/repositories/post_repository.dart';
import '../../../post/domain/models/post.dart';
import '../../../post/domain/models/category.dart';
import '../../../home/presentation/widgets/post_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  PostType? _selectedType;
  String? _selectedCategory;
  bool _hasImages = false;
  bool _hasReward = false;
  bool _showFilters = false;
  
  List<Post>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == null && _selectedType == null) {
      return;
    }

    setState(() => _isSearching = true);

    try {
      final filters = PostFilters(
        keyword: query.isNotEmpty ? query : null,
        type: _selectedType,
        category: _selectedCategory,
        hasImages: _hasImages ? true : null,
        hasReward: _hasReward ? true : null,
      );

      final result = await ref.read(postRepositoryProvider).getPosts(filters);
      setState(() {
        _searchResults = result.posts;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _hasImages = false;
      _hasReward = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: GradientText(
                text: 'Search',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                gradient: AppColors.primaryGradient,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.heroGradient,
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                children: [
                  // Search input
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    borderRadius: 16,
                    child: TextField(
                      controller: _searchController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search lost or found items...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        prefixIcon: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Icon(Icons.search_rounded, color: Colors.white),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _showFilters = !_showFilters);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: _showFilters
                                      ? AppColors.secondaryGradient
                                      : null,
                                  color: _showFilters
                                      ? null
                                      : (isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: _showFilters
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),

                  // Filters
                  if (_showFilters) ...[
                    const SizedBox(height: 16),
                    _buildFilters(),
                  ],

                  const SizedBox(height: 16),

                  // Search button
                  GlassButton(
                    text: 'Search',
                    onPressed: _search,
                    gradient: AppColors.primaryGradient,
                    height: 52,
                    icon: Icons.search_rounded,
                  ),
                ],
              ),
            ).animate().fadeIn(),

            // Results
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter
          Row(
            children: [
              Text(
                'Type:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              _GlassFilterChip(
                label: 'All',
                isSelected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              const SizedBox(width: 8),
              _GlassFilterChip(
                label: 'Lost',
                isSelected: _selectedType == PostType.lost,
                onTap: () => setState(() => _selectedType = PostType.lost),
                gradient: AppColors.lostGradient,
              ),
              const SizedBox(width: 8),
              _GlassFilterChip(
                label: 'Found',
                isSelected: _selectedType == PostType.found,
                onTap: () => setState(() => _selectedType = PostType.found),
                gradient: AppColors.foundGradient,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Category
          Text(
            'Category:',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _GlassFilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...ItemCategory.all.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _GlassFilterChip(
                      label: '${cat.icon} ${cat.name}',
                      isSelected: _selectedCategory == cat.id,
                      onTap: () => setState(() => _selectedCategory = cat.id),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Additional filters
          Row(
            children: [
              _GlassFilterChip(
                label: 'Has Images',
                icon: Icons.image_rounded,
                isSelected: _hasImages,
                onTap: () => setState(() => _hasImages = !_hasImages),
              ),
              const SizedBox(width: 8),
              _GlassFilterChip(
                label: 'Has Reward',
                icon: Icons.card_giftcard_rounded,
                isSelected: _hasReward,
                onTap: () => setState(() => _hasReward = !_hasReward),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Clear',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: PostCardSkeleton(),
        ),
      );
    }

    if (_searchResults == null) {
      return Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Search for items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter keywords or apply filters\nto find lost & found items',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No results found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or filters',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final post = _searchResults![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PostCard(
            post: post,
            onTap: () => context.push('/post/${post.id}'),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}

class _GlassFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Gradient? gradient;

  const _GlassFilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipGradient = gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? chipGradient : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (chipGradient as LinearGradient).colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
