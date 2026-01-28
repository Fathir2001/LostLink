import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../post/domain/models/post.dart';
import '../../../post/data/repositories/post_repository.dart';
import '../../../home/presentation/widgets/post_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';

// Provider for user's posts
final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.read(postRepositoryProvider);
  final result = await repo.getPosts(const PostFilters());
  // In real app, filter by current user ID
  return result.posts;
});

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myPostsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Posts'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Resolved'),
              Tab(text: 'All'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryLight,
            indicatorColor: AppColors.primary,
          ),
        ),
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
            final activePosts = posts.where((p) => p.status == PostStatus.active).toList();
            final resolvedPosts = posts.where((p) => p.status == PostStatus.resolved).toList();

            return TabBarView(
              children: [
                _PostsList(posts: activePosts, emptyMessage: 'No active posts'),
                _PostsList(posts: resolvedPosts, emptyMessage: 'No resolved posts'),
                _PostsList(posts: posts, emptyMessage: 'You haven\'t posted anything yet'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-post'),
          icon: const Icon(Icons.add),
          label: const Text('New Post'),
        ),
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  final List<Post> posts;
  final String emptyMessage;

  const _PostsList({
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
          child: _MyPostCard(post: post),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}

class _MyPostCard extends StatelessWidget {
  final Post post;

  const _MyPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PostCard(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
        ),
        // Status badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(post.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getStatusLabel(post.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // More options
        Positioned(
          bottom: 8,
          right: 8,
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.more_vert, size: 20),
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
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              if (post.status == PostStatus.active)
                const PopupMenuItem(
                  value: 'mark_resolved',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Mark as Reunited'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  void _showResolveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Reunited?'),
        content: const Text(
          'Great news! This will mark the item as reunited with its owner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update post status
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Item marked as reunited!'),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'This action cannot be undone. The post will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete post
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
