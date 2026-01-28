import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../post/domain/models/post.dart';
import '../../../home/presentation/widgets/post_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// Bookmarks state
final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, AsyncValue<List<Post>>>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  BookmarksNotifier() : super(const AsyncValue.loading()) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    await Future.delayed(const Duration(seconds: 1));
    // Return empty for now - would load from local storage
    state = const AsyncValue.data([]);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadBookmarks();
  }

  void removeBookmark(String postId) {
    state.whenData((posts) {
      state = AsyncValue.data(
        posts.where((p) => p.id != postId).toList(),
      );
    });
  }
}

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
      ),
      body: bookmarksAsync.when(
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
          onRetry: () => ref.read(bookmarksProvider.notifier).refresh(),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No saved items',
              message: 'Tap the bookmark icon on posts to save them for later.',
              actionLabel: 'Browse Posts',
              onAction: () => context.go('/home'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(bookmarksProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: Key(post.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      ref.read(bookmarksProvider.notifier).removeBookmark(post.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from bookmarks')),
                      );
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bookmark_remove,
                        color: Colors.white,
                      ),
                    ),
                    child: PostCard(
                      post: post,
                      onTap: () => context.push('/post/${post.id}'),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms);
              },
            ),
          );
        },
      ),
    );
  }
}
