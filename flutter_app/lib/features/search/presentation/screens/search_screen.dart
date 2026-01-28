import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
          SnackBar(content: Text('Search failed: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search lost or found items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: _showFilters
                                ? AppColors.primary
                                : AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            setState(() => _showFilters = !_showFilters);
                          },
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),

                // Filters
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  _buildFilters(),
                ],

                const SizedBox(height: 12),

                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _search,
                    child: const Text('Search'),
                  ),
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
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type filter
        Row(
          children: [
            Text(
              'Type:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'All',
              isSelected: _selectedType == null,
              onTap: () => setState(() => _selectedType = null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Lost',
              isSelected: _selectedType == PostType.lost,
              onTap: () => setState(() => _selectedType = PostType.lost),
              color: AppColors.lost,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Found',
              isSelected: _selectedType == PostType.found,
              onTap: () => setState(() => _selectedType = PostType.found),
              color: AppColors.found,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Category
        Text(
          'Category:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              ...ItemCategory.all.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: '${cat.icon} ${cat.name}',
                    isSelected: _selectedCategory == cat.id,
                    onTap: () => setState(() => _selectedCategory = cat.id),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Additional filters
        Row(
          children: [
            _FilterChip(
              label: 'Has Images',
              icon: Icons.image,
              isSelected: _hasImages,
              onTap: () => setState(() => _hasImages = !_hasImages),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Has Reward',
              icon: Icons.card_giftcard,
              isSelected: _hasReward,
              onTap: () => setState(() => _hasReward = !_hasReward),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildResults() {
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
      return EmptyState(
        icon: Icons.search,
        title: 'Search for items',
        message: 'Enter keywords or apply filters to find lost & found items',
      );
    }

    if (_searchResults!.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        message: 'Try different keywords or filters',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
