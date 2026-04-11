import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'providers.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notification enabled state provider
final notificationEnabledProvider = StateProvider<bool>((ref) {
  return true; // Default to enabled
});

/// Initialize notification enabled state from storage
final initNotificationStateProvider = FutureProvider<bool>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  final settings = await storageService.getAppSettings();
  
  // Update the state provider
  ref.read(notificationEnabledProvider.notifier).state = settings.notificationsEnabled;
  
  return settings.notificationsEnabled;
});

/// FCM Token provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.initialize();
  return notificationService.fcmToken;
});
