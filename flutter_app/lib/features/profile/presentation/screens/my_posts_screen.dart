import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../post/domain/models/post.dart';
import '../../../post/data/repositories/post_repository.dart';
import '../../../home/presentation/widgets/post_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';

// Provider for user's posts
final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.read(postRepositoryProvider);
  final result = await repo.getPosts(const PostFilters());
  return result.posts;
});

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Glass App Bar with Tabs
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  expandedHeight: 120,
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  title: GradientText(
                    text: 'My Posts',
                    gradient: AppColors.primaryGradient,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassContainer(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Active'),
                            Tab(text: 'Resolved'),
                            Tab(text: 'All'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: postsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: PostCardSkeleton(),
                ),
              ),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(myPostsProvider),
              ),
              data: (posts) {
                final activePosts =
                    posts.where((p) => p.status == PostStatus.active).toList();
                final resolvedPosts =
                    posts.where((p) => p.status == PostStatus.resolved).toList();

                return TabBarView(
                  children: [
                    _GlassPostsList(posts: activePosts, emptyMessage: 'No active posts'),
                    _GlassPostsList(posts: resolvedPosts, emptyMessage: 'No resolved posts'),
                    _GlassPostsList(posts: posts, emptyMessage: 'You haven\'t posted anything yet'),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: _GlassFloatingButton(
          onPressed: () => context.push('/create-post'),
        ),
      ),
    );
  }
}

class _GlassPostsList extends StatelessWidget {
  final List<Post> posts;
  final String emptyMessage;

  const _GlassPostsList({
    required this.posts,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'No posts',
        message: emptyMessage,
        actionLabel: 'Create Post',
        onAction: () => context.push('/create-post'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _GlassMyPostCard(post: post),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}

class _GlassMyPostCard extends StatelessWidget {
  final Post post;

  const _GlassMyPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          PostCard(
            post: post,
            onTap: () => context.push('/post/${post.id}'),
          ),
          // Status badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: _getStatusGradient(post.status),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(post.status).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _getStatusLabel(post.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // More options
          Positioned(
            bottom: 12,
            right: 12,
            child: _GlassOptionsButton(
              post: post,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient(PostStatus status) {
    switch (status) {
      case PostStatus.active:
        return AppColors.successGradient;
      case PostStatus.resolved:
        return AppColors.foundGradient;
      case PostStatus.expired:
        return AppColors.darkGradient;
      case PostStatus.hidden:
        return AppColors.darkGradient;
    }
  }

  Color _getStatusColor(PostStatus status) {
    switch (status) {
      case PostStatus.active:
        return AppColors.success;
      case PostStatus.resolved:
        return AppColors.found;
      case PostStatus.expired:
        return AppColors.textSecondaryLight;
      case PostStatus.hidden:
        return AppColors.textSecondaryLight;
    }
  }

  String _getStatusLabel(PostStatus status) {
    switch (status) {
      case PostStatus.active:
        return 'ACTIVE';
      case PostStatus.resolved:
        return 'RESOLVED';
      case PostStatus.expired:
        return 'EXPIRED';
      case PostStatus.hidden:
        return 'HIDDEN';
    }
  }
}

class _GlassOptionsButton extends StatelessWidget {
  final Post post;
  final bool isDark;

  const _GlassOptionsButton({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.push('/edit-post/${post.id}');
                  break;
                case 'mark_resolved':
                  _showResolveDialog(context);
                  break;
                case 'delete':
                  _showDeleteDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              _buildMenuItem(
                value: 'edit',
                icon: Icons.edit_outlined,
                label: 'Edit',
                gradient: AppColors.primaryGradient,
              ),
              if (post.status == PostStatus.active)
                _buildMenuItem(
                  value: 'mark_resolved',
                  icon: Icons.check_circle_outline,
                  label: 'Mark as Reunited',
                  gradient: AppColors.successGradient,
                ),
              _buildMenuItem(
                value: 'delete',
                icon: Icons.delete_outline,
                label: 'Delete',
                gradient: AppColors.errorGradient,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? AppColors.error : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.celebration, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Mark as Reunited?'),
          ],
        ),
        content: Text(
          'Great news! This will mark the item as reunited with its owner.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🎉 Item marked as reunited!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Post?'),
          ],
        ),
        content: Text(
          'This action cannot be undone. The post will be permanently deleted.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.errorGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GlassFloatingButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'New Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
