import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          PopupMenuButton<String>(
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
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(alertsProvider.notifier).refresh(),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: 'No alerts yet',
              message: 'You\'ll be notified when there are matches for your items or when someone contacts you.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertTile(
                  alert: alert,
                  onTap: () => _handleAlertTap(context, ref, alert),
                  onDismiss: () {
                    ref.read(alertsProvider.notifier).delete(alert.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Alert deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Would need to implement undo logic
                          },
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
              },
            ),
          );
        },
      ),
    );
  }

  void _handleAlertTap(BuildContext context, WidgetRef ref, AlertItem alert) {
    // Mark as read
    ref.read(alertsProvider.notifier).markAsRead(alert.id);

    // Navigate based on type
    if (alert.postId != null) {
      context.push('/post/${alert.postId}');
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all alerts?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(alertsProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
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
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildLeading(),
        title: Text(
          alert.title,
          style: TextStyle(
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(alert.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
        trailing: alert.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildLeading() {
    IconData icon;
    Color color;

    switch (alert.type) {
      case AlertType.match:
        icon = Icons.link;
        color = AppColors.success;
        break;
      case AlertType.message:
        icon = Icons.message;
        color = AppColors.primary;
        break;
      case AlertType.statusUpdate:
        icon = Icons.check_circle;
        color = AppColors.found;
        break;
      case AlertType.system:
        icon = Icons.info;
        color = AppColors.textSecondaryLight;
        break;
    }

    if (alert.imageUrl != null && 
        (alert.imageUrl!.startsWith('http://') || alert.imageUrl!.startsWith('https://'))) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              alert.imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
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
