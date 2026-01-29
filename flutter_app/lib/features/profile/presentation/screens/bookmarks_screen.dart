import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../post/domain/models/post.dart';
import '../../../home/presentation/widgets/post_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// Bookmarks state
final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<Post>>>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  BookmarksNotifier() : super(const AsyncValue.loading()) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    await Future.delayed(const Duration(seconds: 1));
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
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(bottom: 16),
                      centerTitle: true,
                      title: GradientText(
                        text: 'Saved Items',
                        gradient: AppColors.primaryGradient,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: _GlassBookmarkIcon(),
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
            ),

            // Content
            bookmarksAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: PostCardSkeleton(),
                    ),
                    childCount: 5,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(bookmarksProvider.notifier).refresh(),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: _GlassEmptyBookmarks(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GlassDismissiblePostCard(
                            post: post,
                            onDismissed: () {
                              ref.read(bookmarksProvider.notifier).removeBookmark(post.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Removed from bookmarks'),
                                  backgroundColor: AppColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            onTap: () => context.push('/post/${post.id}'),
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms);
                      },
                      childCount: posts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBookmarkIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.bookmark,
        color: Colors.white,
        size: 32,
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
  }
}

class _GlassEmptyBookmarks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.secondaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.bookmark_outline,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ).animate().fadeIn().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                ),
            const SizedBox(height: 24),
            GradientText(
              text: 'No saved items',
              gradient: AppColors.primaryGradient,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Text(
              'Tap the bookmark icon on posts to save them for later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),
            GlassButton(
              text: 'Browse Posts',
              onPressed: () => context.go('/home'),
              gradient: AppColors.primaryGradient,
              icon: Icons.explore,
              width: 200,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

class _GlassDismissiblePostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const _GlassDismissiblePostCard({
    required this.post,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(post.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: AppColors.errorGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_remove,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            PostCard(
              post: post,
              onTap: onTap,
            ),
            // Bookmark indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
