import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../shared/widgets/empty_state.dart';

// Alert types
enum AlertType {
  match,
  message,
  statusUpdate,
  system,
}

// Alert model
class AlertItem {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;
  final String? matchId;
  final String? imageUrl;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.postId,
    this.matchId,
    this.imageUrl,
  });
}

// Mock alerts provider
final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<AlertItem>>>((ref) {
  return AlertsNotifier();
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AlertItem>>> {
  AlertsNotifier() : super(const AsyncValue.loading()) {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    // Simulated delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    state = AsyncValue.data([
      AlertItem(
        id: '1',
        type: AlertType.match,
        title: 'Potential Match Found!',
        message: 'Your lost iPhone 15 Pro might have been found. Someone reported a similar item.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        postId: 'post123',
        matchId: 'match456',
        imageUrl: 'https://picsum.photos/200',
      ),
      AlertItem(
        id: '2',
        type: AlertType.message,
        title: 'New Message',
        message: 'John Doe sent you a message about "Found: Black Wallet"',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        postId: 'post456',
        isRead: true,
      ),
      AlertItem(
        id: '3',
        type: AlertType.statusUpdate,
        title: 'Item Reunited!',
        message: 'Congratulations! Your lost dog "Max" has been marked as reunited.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        postId: 'post789',
        isRead: true,
      ),
      AlertItem(
        id: '4',
        type: AlertType.system,
        title: 'Welcome to LostLink!',
        message: 'Start by posting a lost or found item, or set up alerts for specific categories.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isRead: true,
      ),
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAlerts();
  }

  void markAsRead(String alertId) {
    state.whenData((alerts) {
      state = AsyncValue.data(
        alerts.map((a) {
          if (a.id == alertId) {
            return AlertItem(
              id: a.id,
              type: a.type,
              title: a.title,
              message: a.message,
              createdAt: a.createdAt,
              isRead: true,
              postId: a.postId,
              matchId: a.matchId,
              imageUrl: a.imageUrl,
            );
          }
          return a;
        }).toList(),
      );
    });
  }

  void markAllAsRead() {
    state.whenData((alerts) {
      state = AsyncValue.data(
        alerts.map((a) {
          return AlertItem(
            id: a.id,
            type: a.type,
            title: a.title,
            message: a.message,
            createdAt: a.createdAt,
            isRead: true,
            postId: a.postId,
            matchId: a.matchId,
            imageUrl: a.imageUrl,
          );
        }).toList(),
      );
    });
  }

  void delete(String alertId) {
    state.whenData((alerts) {
      state = AsyncValue.data(
        alerts.where((a) => a.id != alertId).toList(),
      );
    });
  }

  void clearAll() {
    state = const AsyncValue.data([]);
  }
}

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
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
                text: 'Alerts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                gradient: AppColors.secondaryGradient,
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: isDark ? Colors.white70 : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'read_all':
                        ref.read(alertsProvider.notifier).markAllAsRead();
                        break;
                      case 'clear_all':
                        _showClearConfirmation(context, ref);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'read_all',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text('Mark all as read'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.error),
                          ),
                          const SizedBox(width: 12),
                          const Text('Clear all'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.heroGradient,
        ),
        child: alertsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          error: (error, stack) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.read(alertsProvider.notifier).refresh(),
          ),
          data: (alerts) {
            if (alerts.isEmpty) {
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
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No alerts yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll be notified when there are\nmatches for your items',
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

            return RefreshIndicator(
              onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
              color: AppColors.secondary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlertTile(
                      alert: alert,
                      onTap: () => _handleAlertTap(context, ref, alert),
                      onDismiss: () {
                        ref.read(alertsProvider.notifier).delete(alert.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Alert deleted'),
                            backgroundColor: AppColors.surfaceDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: AppColors.secondary,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleAlertTap(BuildContext context, WidgetRef ref, AlertItem alert) {
    ref.read(alertsProvider.notifier).markAsRead(alert.id);
    if (alert.postId != null) {
      context.push('/post/${alert.postId}');
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              const Text('Clear all alerts?'),
            ],
          ),
          content: const Text('This action cannot be undone.'),
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
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withRed(220)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                  ref.read(alertsProvider.notifier).clearAll();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AlertTile({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.error.withOpacity(0.8), AppColors.error],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          borderRadius: 16,
          color: alert.isRead
              ? null
              : (isDark
                  ? AppColors.secondary.withOpacity(0.1)
                  : AppColors.secondary.withOpacity(0.05)),
          borderColor: alert.isRead
              ? null
              : AppColors.secondary.withOpacity(0.3),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeading(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(alert.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    IconData icon;
    Gradient gradient;

    switch (alert.type) {
      case AlertType.match:
        icon = Icons.link_rounded;
        gradient = AppColors.successGradient;
        break;
      case AlertType.message:
        icon = Icons.message_rounded;
        gradient = AppColors.primaryGradient;
        break;
      case AlertType.statusUpdate:
        icon = Icons.check_circle_rounded;
        gradient = AppColors.foundGradient;
        break;
      case AlertType.system:
        icon = Icons.info_rounded;
        gradient = AppColors.accentGradient;
        break;
    }

    if (alert.imageUrl != null && 
        (alert.imageUrl!.startsWith('http://') || alert.imageUrl!.startsWith('https://'))) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              alert.imageUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient).colors.first.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
