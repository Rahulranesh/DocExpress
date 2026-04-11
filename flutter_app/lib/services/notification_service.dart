import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification payload data
class NotificationPayload {
  final String type;
  final String? jobId;
  final String? fileId;
  final String? route;
  final Map<String, dynamic>? data;

  NotificationPayload({
    required this.type,
    this.jobId,
    this.fileId,
    this.route,
    this.data,
  });

  String toJson() {
    return '{"type":"$type","jobId":"$jobId","fileId":"$fileId","route":"$route"}';
  }

  factory NotificationPayload.fromJson(String json) {
    final map = json.split(',').fold<Map<String, String>>({}, (acc, item) {
      final parts = item.replaceAll(RegExp(r'[{}":]'), '').split(':');
      if (parts.length == 2) acc[parts[0]] = parts[1];
      return acc;
    });
    return NotificationPayload(
      type: map['type'] ?? 'unknown',
      jobId: map['jobId'],
      fileId: map['fileId'],
      route: map['route'],
    );
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [NOTIFICATION] Background message: ${message.messageId}');
}

/// Notification Service - handles Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔔 [NOTIFICATION] Initializing...');

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔔 [NOTIFICATION] FCM Token: $_fcmToken');

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('🔔 [NOTIFICATION] Token refreshed: $token');
      });

      _initialized = true;
      debugPrint('✅ [NOTIFICATION] Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      // Android 13+ requires runtime permission
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Job completion channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'job_completion',
        'Job Completion',
        description: 'Notifications for completed conversions and compressions',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Job failure channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'job_failure',
        'Job Failures',
        description: 'Notifications for failed operations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Job progress channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'job_progress',
        'Job Progress',
        description: 'Shows progress of ongoing jobs',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'general',
        'General',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    );

    debugPrint('✅ [NOTIFICATION] Android channels created');
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [NOTIFICATION] Foreground message: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'DocXpress',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [NOTIFICATION] Notification tapped: ${message.data}');
    // TODO: Navigate to relevant screen based on message.data
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [NOTIFICATION] Local notification tapped: ${response.payload}');
    // TODO: Navigate to relevant screen based on payload
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        actions: actions,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('✅ [NOTIFICATION] Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show notification: $e');
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'job_completion':
        return 'Job Completion';
      case 'job_failure':
        return 'Job Failures';
      case 'job_progress':
        return 'Job Progress';
      default:
        return 'General';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'job_completion':
        return 'Notifications for completed conversions and compressions';
      case 'job_failure':
        return 'Notifications for failed operations';
      case 'job_progress':
        return 'Shows progress of ongoing jobs';
      default:
        return 'General app notifications';
    }
  }

  /// Show job completion notification
  Future<void> showJobCompletionNotification({
    required String jobType,
    required String fileName,
    String? jobId,
    String? fileId,
  }) async {
    final payload = NotificationPayload(
      type: 'job_completed',
      jobId: jobId,
      fileId: fileId,
      route: '/jobs',
    );

    await showLocalNotification(
      title: '$jobType Completed',
      body: '$fileName has been processed successfully',
      channelId: 'job_completion',
      payload: payload.toJson(),
      actions: fileId != null
          ? [
              const AndroidNotificationAction(
                'open',
                'Open',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'share',
                'Share',
                showsUserInterface: true,
              ),
            ]
          : null,
    );
  }

  /// Show job failure notification
  Future<void> showJobFailureNotification({
    required String jobType,
    required String fileName,
    String? error,
    String? jobId,
  }) async {
    final payload = NotificationPayload(
      type: 'job_failed',
      jobId: jobId,
      route: '/jobs',
    );

    await showLocalNotification(
      title: '$jobType Failed',
      body: 'Failed to process $fileName${error != null ? ': $error' : ''}',
      channelId: 'job_failure',
      payload: payload.toJson(),
      actions: [
        const AndroidNotificationAction(
          'retry',
          'Retry',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'view',
          'View Details',
          showsUserInterface: true,
        ),
      ],
    );
  }

  /// Show batch job completion notification
  Future<void> showBatchJobCompletionNotification({
    required int totalJobs,
    required int successCount,
    required int failureCount,
  }) async {
    final payload = NotificationPayload(
      type: 'batch_completed',
      route: '/jobs',
    );

    await showLocalNotification(
      title: 'Batch Processing Completed',
      body: '$successCount of $totalJobs files processed successfully${failureCount > 0 ? ', $failureCount failed' : ''}',
      channelId: 'job_completion',
      payload: payload.toJson(),
    );
  }

  /// Show progress notification
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'job_progress',
        'Job Progress',
        channelDescription: 'Shows progress of ongoing jobs',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        ongoing: true,
        autoCancel: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
      );

      debugPrint('✅ [NOTIFICATION] Progress notification shown: $progress/$maxProgress');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to show progress notification: $e');
    }
  }

  /// Update progress notification
  Future<void> updateProgressNotification({
    required int id,
    required int progress,
    required int maxProgress,
  }) async {
    await showProgressNotification(
      id: id,
      title: 'Processing...',
      body: '${(progress / maxProgress * 100).toInt()}% complete',
      progress: progress,
      maxProgress: maxProgress,
    );
  }

  /// Cancel progress notification
  Future<void> cancelProgressNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🔔 [NOTIFICATION] All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    debugPrint('🔔 [NOTIFICATION] Notification $id cancelled');
  }
}
