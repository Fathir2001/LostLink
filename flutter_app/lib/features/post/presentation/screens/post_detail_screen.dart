import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
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
    return FutureBuilder<Post>(
      future: ref.read(postRepositoryProvider).getPostById(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            ),
          );
        }

        final post = snapshot.data!;
        final category = ItemCategory.findById(post.category);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar with image gallery
              SliverAppBar(
                expandedHeight: post.hasImages ? 300 : 150,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: post.hasImages
                      ? _ImageGallery(
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
                            child: Text(
                              category?.icon ?? '📦',
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
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
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showShareSheet(context, post),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, post),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined),
                            SizedBox(width: 8),
                            Text('Report'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: post.isLost ? AppColors.lost : AppColors.found,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              post.isLost ? 'LOST' : 'FOUND',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category?.icon ?? '📦'),
                                const SizedBox(width: 6),
                                Text(
                                  category?.name ?? 'Other',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeago.format(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        post.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondaryLight,
                              height: 1.6,
                            ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // Location
                      if (post.location != null) ...[
                        _InfoSection(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          content: post.location!.displayText,
                        ).animate().fadeIn(delay: 300.ms),

                        // Map preview
                        if (post.location!.hasCoordinates) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
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
                                        child: Icon(
                                          Icons.location_pin,
                                          color: post.isLost
                                              ? AppColors.lost
                                              : AppColors.found,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 350.ms),
                        ],

                        const SizedBox(height: 16),
                      ],

                      // Date
                      if (post.lostFoundDate != null) ...[
                        _InfoSection(
                          icon: Icons.calendar_today,
                          title: 'Date ${post.isLost ? 'Lost' : 'Found'}',
                          content:
                              '${post.lostFoundDate!.day}/${post.lostFoundDate!.month}/${post.lostFoundDate!.year}',
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 16),
                      ],

                      // Reward
                      if (post.hasReward) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reward Offered',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      post.reward!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                        const SizedBox(height: 16),
                      ],

                      // Item attributes
                      if (post.attributes != null) ...[
                        Text(
                          'Item Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (post.attributes!.brand != null)
                              _AttributeChip(
                                label: 'Brand',
                                value: post.attributes!.brand!,
                              ),
                            if (post.attributes!.model != null)
                              _AttributeChip(
                                label: 'Model',
                                value: post.attributes!.model!,
                              ),
                            if (post.attributes!.color != null)
                              _AttributeChip(
                                label: 'Color',
                                value: post.attributes!.color!,
                              ),
                            if (post.attributes!.size != null)
                              _AttributeChip(
                                label: 'Size',
                                value: post.attributes!.size!,
                              ),
                          ],
                        ).animate().fadeIn(delay: 500.ms),
                        if (post.attributes!.uniqueMarks != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.fingerprint,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unique Marks',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                      Text(
                                        post.attributes!.uniqueMarks!,
                                        style: Theme.of(context).textTheme.bodyMedium,
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
                      _MatchesSection(postId: widget.postId)
                          .animate()
                          .fadeIn(delay: 600.ms),

                      const SizedBox(height: 24),

                      // Posted by
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dividerLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: post.userAvatar != null
                                  ? CachedNetworkImageProvider(post.userAvatar!)
                                  : null,
                              child: post.userAvatar == null
                                  ? Text(
                                      post.userName.isNotEmpty
                                          ? post.userName[0].toUpperCase()
                                          : 'U',
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posted by',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    post.userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Contact user
                              },
                              child: const Text('Contact'),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  // Contact poster
                },
                child: Text(
                  post.isLost ? 'I Found This Item' : 'This Is My Item',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ShareBottomSheet(post: post),
    );
  }

  void _handleMenuAction(String value, Post post) {
    switch (value) {
      case 'report':
        _showReportDialog(context, post);
        break;
    }
  }

  void _showReportDialog(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Spam or Scam'),
              onTap: () {
                Navigator.pop(context);
                _submitReport(post.id, 'spam');
              },
            ),
            ListTile(
              title: const Text('Inappropriate Content'),
              onTap: () {
                Navigator.pop(context);
                _submitReport(post.id, 'inappropriate');
              },
            ),
            ListTile(
              title: const Text('Duplicate'),
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
          const SnackBar(content: Text('Report submitted. Thank you!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    }
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _ImageGallery({
    required this.images,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out invalid image URLs
    final validImages = images.where((url) => 
      url.startsWith('http://') || url.startsWith('https://')
    ).toList();
    
    if (validImages.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
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
            return CachedNetworkImage(
              imageUrl: validImages[index],
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
              ),
            );
          },
        ),
        if (validImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(validImages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttributeChip extends StatelessWidget {
  final String label;
  final String value;

  const _AttributeChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _MatchesSection extends ConsumerWidget {
  final String postId;

  const _MatchesSection({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Possible Matches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => context.push('/post/${match.matchedPostId}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: match.type == PostType.found
                                        ? AppColors.foundLight
                                        : AppColors.lostLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    match.type == PostType.found ? 'FOUND' : 'LOST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: match.type == PostType.found
                                          ? AppColors.found
                                          : AppColors.lost,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(match.score * 100).toInt()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match.title ?? 'Untitled',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

class _ShareBottomSheet extends ConsumerWidget {
  final Post post;

  const _ShareBottomSheet({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Post',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy Link'),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: 'https://lostlink.app/post/${post.id}'),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Generate AI Caption'),
            subtitle: const Text('For social media sharing'),
            onTap: () async {
              Navigator.pop(context);
              final caption = await ref.read(aiRepositoryProvider).generateCaption(
                    title: post.title,
                    description: post.description,
                    postType: post.isLost ? 'LOST' : 'FOUND',
                    location: post.location?.displayText,
                  );
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Generated Caption'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(caption),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: caption));
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Caption copied!')),
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share via...'),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                '${post.title}\n\n${post.description}\n\nView on LostLink: https://lostlink.app/post/${post.id}',
              );
            },
          ),
        ],
      ),
    );
  }
}
