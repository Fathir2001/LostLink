import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/post_card.dart';
import '../widgets/post_type_toggle.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(homePostsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(homePostsProvider);
    final selectedType = ref.watch(selectedPostTypeProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homePostsProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                snap: true,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.link,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('LostLink'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.go(AppRoutes.alerts),
                  ),
                ],
              ),

              // Post type toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PostTypeToggle(
                    selectedType: selectedType,
                    onChanged: (type) {
                      ref.read(selectedPostTypeProvider.notifier).state = type;
                      ref.read(homePostsProvider.notifier).refresh();
                    },
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ),

              // Import from social banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ImportBanner(),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Posts list
              postsAsync.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: const PostCardSkeleton(),
                      ),
                      childCount: 5,
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    message: error.toString(),
                    actionLabel: 'Try Again',
                    onAction: () => ref.read(homePostsProvider.notifier).refresh(),
                  ),
                ),
                data: (paginatedPosts) {
                  if (paginatedPosts.posts.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: selectedType == null
                            ? Icons.inventory_2_outlined
                            : selectedType!.index == 0
                                ? Icons.search_off
                                : Icons.celebration_outlined,
                        title: 'No posts yet',
                        message: selectedType == null
                            ? 'Be the first to post a lost or found item!'
                            : 'No ${selectedType.name} items in your area',
                        actionLabel: 'Create Post',
                        onAction: () => context.push(AppRoutes.createPost),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= paginatedPosts.posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = paginatedPosts.posts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(
                              post: post,
                              onTap: () => context.push('/post/${post.id}'),
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms).slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOut,
                              );
                        },
                        childCount: paginatedPosts.posts.length +
                            (paginatedPosts.hasMore ? 1 : 0),
                      ),
                    ),
                  );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import from Social Media',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paste text or upload a screenshot',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.importFromSocial),
          ),
        ],
      ),
    );
  }
}
