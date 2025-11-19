import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/patient_providers.dart';
import '../../providers/notifications_providers.dart';
import '../widgets/alert_banner.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final notifications = ref.watch(sortedNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(clearAllNotificationsProvider)();
              },
              tooltip: '清除所有通知',
            ),
        ],
      ),
      body: selectedPatient == null
          ? const Center(child: Text('請選擇病人'))
          : notifications.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isRead = notification['isRead'] as bool;
                    
                    return AlertBanner(
                      title: notification['title'] as String,
                      message: notification['message'] as String,
                      type: notification['type'] as String,
                      onDismiss: () {
                        ref.read(markNotificationReadProvider(notification['id'] as String));
                      },
                      actionText: isRead ? null : '標記已讀',
                      onAction: isRead ? null : () {
                        ref.read(markNotificationReadProvider(notification['id'] as String));
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暫無通知',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.black, // 改成黑色
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '所有通知都會顯示在這裡',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.7), // 改成黑色
            ),
          ),
        ],
      ),
    );
  }
}
