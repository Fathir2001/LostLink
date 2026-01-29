import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.primaryDark.withOpacity(0.2),
                  ]
                : [
                    AppColors.backgroundLight,
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(homePostsProvider.notifier).refresh(),
            color: AppColors.secondary,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Glass App bar
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
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.secondaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.location_searching,
                              color: Colors.white,
                              size: 20,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LostLink',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.secondary,
                        ),
                        onPressed: () => context.go(AppRoutes.alerts),
                      ),
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
      ),
    );
  }
}

class _ImportBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.importFromSocial),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(isDark ? 0.2 : 0.15),
            AppColors.accent.withOpacity(isDark ? 0.1 : 0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import from Social Media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-powered extraction from text or images',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
