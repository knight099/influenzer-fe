import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        actions: [
          notifAsync.whenData((list) {
            final hasUnread = list.any((n) => !n.isRead);
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: () async {
                await ref.read(notificationRepositoryProvider).markAllRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadCountProvider);
              },
              child: const Text('Mark all read', style: TextStyle(fontSize: 13)),
            );
          }).value ?? const SizedBox.shrink(),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: notifAsync.when(
          loading: () => const _NotifSkeleton(),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 30),
                ),
                const SizedBox(height: 16),
                const Text('Failed to load notifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const _EmptyNotifications();
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72, endIndent: 16, color: AppColors.divider),
              itemBuilder: (context, index) => _NotifTile(
                notification: notifications[index],
                onTap: () => _onTap(notifications[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onTap(AppNotification notif) async {
    if (!notif.isRead) {
      await ref.read(notificationRepositoryProvider).markRead(notif.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotifTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final meta = _NotifMeta.from(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primaryLight.withValues(alpha: 0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: meta.color, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

// ── Meta mapping ──────────────────────────────────────────────────────────────

class _NotifMeta {
  final IconData icon;
  final Color color;

  const _NotifMeta(this.icon, this.color);

  factory _NotifMeta.from(String type) {
    switch (type) {
      case 'NEW_PROPOSAL':
        return _NotifMeta(Icons.assignment_turned_in_rounded, AppColors.primary);
      case 'PROPOSAL_ACCEPTED':
        return _NotifMeta(Icons.check_circle_rounded, AppColors.success);
      case 'PROPOSAL_REJECTED':
        return _NotifMeta(Icons.cancel_rounded, AppColors.error);
      case 'NEW_MESSAGE':
        return _NotifMeta(Icons.chat_bubble_rounded, Color(0xFF0EA5E9));
      case 'CAMPAIGN_CREATED':
        return _NotifMeta(Icons.campaign_rounded, AppColors.secondary);
      case 'PAYMENT_RECEIVED':
        return _NotifMeta(Icons.currency_rupee_rounded, AppColors.success);
      default:
        return _NotifMeta(Icons.notifications_rounded, AppColors.primary);
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.subtleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ll be notified about proposals,\nmessages, and campaign updates here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _NotifSkeleton extends StatelessWidget {
  const _NotifSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(44, 44, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(double.infinity, 13),
                  const SizedBox(height: 6),
                  _box(double.infinity, 11),
                  const SizedBox(height: 4),
                  _box(140, 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ── Bell icon widget with unread badge (used in feed headers) ─────────────────

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadCountProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
            ),
            countAsync.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
