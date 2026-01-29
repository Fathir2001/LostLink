import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/widgets/platform_network_image.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/ai_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/category.dart';
import '../../../shared/widgets/empty_state.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  int _currentImageIndex = 0;
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Post>(
      future: ref.read(postRepositoryProvider).getPostById(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            ),
          );
        }

        final post = snapshot.data!;
        final category = ItemCategory.findById(post.category);

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
                // Glass App bar with image gallery
                SliverAppBar(
                  expandedHeight: post.hasImages ? 320 : 180,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: post.hasImages
                        ? _GlassImageGallery(
                            images: post.images,
                            currentIndex: _currentImageIndex,
                            onIndexChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: post.isLost
                                  ? AppColors.lostGradient
                                  : AppColors.foundGradient,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category?.icon ?? '📦',
                                    style: const TextStyle(fontSize: 64),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category?.name ?? 'Item',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    _GlassIconButton(
                      icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      onPressed: () async {
                        final postRepo = ref.read(postRepositoryProvider);
                        if (_isBookmarked) {
                          await postRepo.unbookmarkPost(widget.postId);
                        } else {
                          await postRepo.bookmarkPost(widget.postId);
                        }
                        setState(() => _isBookmarked = !_isBookmarked);
                      },
                    ),
                    _GlassIconButton(
                      icon: Icons.share,
                      onPressed: () => _showShareSheet(context, post),
                    ),
                    _GlassIconButton(
                      icon: Icons.more_vert,
                      onPressed: () => _showMoreOptions(context, post),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge and category
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: post.isLost
                                    ? AppColors.lostGradient
                                    : AppColors.foundGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: (post.isLost ? AppColors.lost : AppColors.found)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    post.isLost ? Icons.search : Icons.where_to_vote,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    post.isLost ? 'LOST' : 'FOUND',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              borderRadius: 10,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(category?.icon ?? '📦', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    category?.name ?? 'Other',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeago.format(post.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          post.title,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 16),

                        // Description
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 16,
                          child: Text(
                            post.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.7,
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),

                        // Location
                        if (post.location != null) ...[
                          _GlassInfoSection(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            content: post.location!.displayText,
                            gradient: AppColors.primaryGradient,
                          ).animate().fadeIn(delay: 300.ms),

                          // Map preview
                          if (post.location!.hasCoordinates) ...[
                            const SizedBox(height: 12),
                            GlassContainer(
                              padding: const EdgeInsets.all(4),
                              borderRadius: 20,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 180,
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        post.location!.latitude!,
                                        post.location!.longitude!,
                                      ),
                                      initialZoom: 14,
                                      interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.none,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.lostlink.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(
                                              post.location!.latitude!,
                                              post.location!.longitude!,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: post.isLost
                                                    ? AppColors.lostGradient
                                                    : AppColors.foundGradient,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (post.isLost
                                                            ? AppColors.lost
                                                            : AppColors.found)
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 350.ms),
                          ],

                          const SizedBox(height: 20),
                        ],

                        // Date
                        if (post.lostFoundDate != null) ...[
                          _GlassInfoSection(
                            icon: Icons.calendar_today,
                            title: 'Date ${post.isLost ? 'Lost' : 'Found'}',
                            content:
                                '${post.lostFoundDate!.day}/${post.lostFoundDate!.month}/${post.lostFoundDate!.year}',
                            gradient: AppColors.secondaryGradient,
                          ).animate().fadeIn(delay: 400.ms),
                          const SizedBox(height: 20),
                        ],

                        // Reward
                        if (post.hasReward) ...[
                          _GlassRewardCard(reward: post.reward!)
                              .animate()
                              .fadeIn(delay: 450.ms),
                          const SizedBox(height: 20),
                        ],

                        // Item attributes
                        if (post.attributes != null) ...[
                          GradientText(
                            text: 'Item Details',
                            gradient: AppColors.primaryGradient,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (post.attributes!.brand != null)
                                _GlassAttributeChip(
                                  label: 'Brand',
                                  value: post.attributes!.brand!,
                                ),
                              if (post.attributes!.model != null)
                                _GlassAttributeChip(
                                  label: 'Model',
                                  value: post.attributes!.model!,
                                ),
                              if (post.attributes!.color != null)
                                _GlassAttributeChip(
                                  label: 'Color',
                                  value: post.attributes!.color!,
                                ),
                              if (post.attributes!.size != null)
                                _GlassAttributeChip(
                                  label: 'Size',
                                  value: post.attributes!.size!,
                                ),
                            ],
                          ).animate().fadeIn(delay: 500.ms),
                          if (post.attributes!.uniqueMarks != null) ...[
                            const SizedBox(height: 12),
                            GlassContainer(
                              padding: const EdgeInsets.all(14),
                              borderRadius: 12,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppColors.secondaryGradient.createShader(bounds),
                                    child: const Icon(
                                      Icons.fingerprint,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unique Marks',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          post.attributes!.uniqueMarks!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],

                        // Possible matches section
                        _GlassMatchesSection(postId: widget.postId)
                            .animate()
                            .fadeIn(delay: 600.ms),

                        const SizedBox(height: 24),

                        // Posted by
                        _GlassUserCard(post: post).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _GlassBottomBar(post: post),
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassShareBottomSheet(post: post),
    );
  }

  void _showMoreOptions(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassOptionsSheet(
        post: post,
        onReport: () {
          Navigator.pop(context);
          _showReportDialog(context, post);
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReportOption(
              title: 'Spam or Scam',
              onTap: () {
                Navigator.pop(context);
                _submitReport(post.id, 'spam');
              },
            ),
            _ReportOption(
              title: 'Inappropriate Content',
              onTap: () {
                Navigator.pop(context);
                _submitReport(post.id, 'inappropriate');
              },
            ),
            _ReportOption(
              title: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                _submitReport(post.id, 'duplicate');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String postId, String reason) async {
    try {
      await ref.read(postRepositoryProvider).reportPost(postId, reason, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(icon, color: Colors.white, size: 22),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _GlassImageGallery({
    required this.images,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validImages = images.where((url) => 
      url.startsWith('http://') || url.startsWith('https://')
    ).toList();
    
    if (validImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.white54),
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: validImages.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (context, index) {
            return PlatformNetworkImage(
              imageUrl: validImages[index],
              fit: BoxFit.cover,
              errorWidget: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.darkGradient,
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 48, color: Colors.white54),
                ),
              ),
            );
          },
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        // Page indicators
        if (validImages.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(validImages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: currentIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _GlassInfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Gradient gradient;

  const _GlassInfoSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassRewardCard extends StatelessWidget {
  final String reward;

  const _GlassRewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1.5,
        ),
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
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.secondaryGradient.createShader(bounds),
                  child: const Text(
                    'Reward Offered',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassAttributeChip extends StatelessWidget {
  final String label;
  final String value;

  const _GlassAttributeChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassMatchesSection extends ConsumerWidget {
  final String postId;

  const _GlassMatchesSection({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<PostMatch>>(
      future: ref.read(postRepositoryProvider).getMatches(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final matches = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                GradientText(
                  text: 'Possible Matches',
                  gradient: AppColors.secondaryGradient,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return GestureDetector(
                    onTap: () => context.push('/post/${match.matchedPostId}'),
                    child: GlassContainer(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: match.type == PostType.found
                                      ? AppColors.foundGradient
                                      : AppColors.lostGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  match.type == PostType.found ? 'FOUND' : 'LOST',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(match.score * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            match.title ?? 'Untitled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassUserCard extends StatelessWidget {
  final Post post;

  const _GlassUserCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              backgroundImage: post.userAvatar != null
                  ? platformNetworkImageProvider(post.userAvatar!)
                  : null,
              child: post.userAvatar == null
                  ? Text(
                      post.userName.isNotEmpty
                          ? post.userName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posted by',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          GlassButton(
            text: 'Contact',
            onPressed: () {
              // Contact user
            },
            isPrimary: false,
            width: 100,
            height: 42,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  final Post post;

  const _GlassBottomBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.dividerLight,
              ),
            ),
          ),
          child: SafeArea(
            child: GlassButton(
              text: post.isLost ? 'I Found This Item' : 'This Is My Item',
              onPressed: () {
                // Contact poster
              },
              gradient: post.isLost ? AppColors.foundGradient : AppColors.lostGradient,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassShareBottomSheet extends ConsumerWidget {
  final Post post;

  const _GlassShareBottomSheet({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientText(
              text: 'Share Post',
              gradient: AppColors.primaryGradient,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _ShareOption(
              icon: Icons.link,
              title: 'Copy Link',
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: 'https://lostlink.app/post/${post.id}'),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            _ShareOption(
              icon: Icons.auto_awesome,
              title: 'Generate AI Caption',
              subtitle: 'For social media sharing',
              onTap: () async {
                Navigator.pop(context);
                final caption = await ref.read(aiRepositoryProvider).generateCaption(
                      title: post.title,
                      description: post.description,
                      postType: post.isLost ? 'LOST' : 'FOUND',
                      location: post.location?.displayText,
                    );
                if (context.mounted) {
                  _showCaptionDialog(context, caption);
                }
              },
            ),
            _ShareOption(
              icon: Icons.share,
              title: 'Share via...',
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  '${post.title}\n\n${post.description}\n\nView on LostLink: https://lostlink.app/post/${post.id}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCaptionDialog(BuildContext context, String caption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Generated Caption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(caption),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: caption));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Caption copied!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Share.share(caption);
                    },
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _GlassOptionsSheet extends StatelessWidget {
  final Post post;
  final VoidCallback onReport;

  const _GlassOptionsSheet({
    required this.post,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_outlined, color: AppColors.error),
              ),
              title: const Text(
                'Report Post',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Report inappropriate content'),
              onTap: onReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ReportOption({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
