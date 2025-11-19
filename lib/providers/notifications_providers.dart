import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'patient_providers.dart';

// 通知 provider
final notificationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  if (selectedPatient == null) return [];
  
  return repository.getNotifications(selectedPatient.id);
});

// 未讀通知數量 provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  
  return notifications.where((n) => !(n['isRead'] as bool)).length;
});

// 標記通知為已讀 provider
final markNotificationReadProvider = Provider.family<void Function(String), String>((ref, notificationId) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  return (String id) {
    if (selectedPatient != null) {
      repository.markNotificationAsRead(selectedPatient.id, id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
  };
});

// 清除所有通知 provider
final clearAllNotificationsProvider = Provider<void Function()>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  final selectedPatient = ref.watch(selectedPatientProvider);
  
  return () {
    if (selectedPatient != null) {
      repository.clearAllNotifications(selectedPatient.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
  };
});

// 按類型篩選通知 provider
final filteredNotificationsProvider = Provider.family<List<Map<String, dynamic>>, String?>((ref, type) {
  final notifications = ref.watch(notificationsProvider);
  
  if (type == null || type.isEmpty) return notifications;
  
  return notifications.where((n) => n['type'] == type).toList();
});

// 按時間排序的通知 provider (最新在上)
final sortedNotificationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  
  return List.from(notifications)..sort((a, b) {
    final aTime = a['timestamp'] as DateTime;
    final bTime = b['timestamp'] as DateTime;
    return bTime.compareTo(aTime);
  });
});
