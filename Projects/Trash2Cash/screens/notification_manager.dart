import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:t2c/services/api_services.dart';

/// Polls the backend for new redemption-status notifications and:
///  - shows a native device notification for anything new since it started
///  - exposes [unreadCount] and [notifications] so UI (the dashboard's bell
///    icon, the notifications screen) can react to them live via
///    ValueListenableBuilder — the same pattern HeartbeatManager already
///    uses for its Timer.periodic polling.
///
/// The "notification" itself is generated server-side by a MySQL trigger on
/// the `redemptions` table (see notifications_and_trigger.sql) whenever the
/// admin changes a redemption's status. This manager just surfaces it,
/// since there's no FCM/push server wired up.
class NotificationManager {
  NotificationManager._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const Duration _pollInterval = Duration(seconds: 15);

  static Timer? _timer;
  static int _userId = 0;
  static bool _pluginInitialized = false;
  static bool _firstPoll = true;
  static int _lastSeenId = 0;

  /// Live unread count — watched by the dashboard's bell icon badge.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Live list of the most recent notifications — watched by the
  /// notifications screen so it doesn't need its own separate poll.
  static final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  static Future<void> _ensurePluginInitialized() async {
    if (_pluginInitialized) return;
    _pluginInitialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);

    // Android 13+ and iOS both require an explicit runtime permission
    // request before a notification will actually show.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Starts polling for [userId]. Safe to call every time the dashboard
  /// mounts — it no-ops if already running for the same user.
  static Future<void> start(int userId) async {
    if (userId <= 0 || _userId == userId && _timer != null) return;

    await _ensurePluginInitialized();

    _userId = userId;
    _firstPoll = true;
    _lastSeenId = 0;

    _timer?.cancel();
    unawaited(_poll()); // fire once immediately, don't block start()
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _userId = 0;
    _firstPoll = true;
    _lastSeenId = 0;
    unreadCount.value = 0;
    notifications.value = [];
  }

  static Future<void> _poll() async {
    if (_userId <= 0) return;

    try {
      final response = await ApiService.getNotifications(_userId);
      if (!response.success) return;

      final data = response.data as Map<String, dynamic>;
      final list = data['notifications'] as List<AppNotification>;
      final unread = data['unreadCount'] as int;

      notifications.value = list;
      unreadCount.value = unread;

      final maxId = list.isEmpty
          ? 0
          : list.map((n) => n.id).reduce((a, b) => a > b ? a : b);

      if (_firstPoll) {
        // Don't spam the user with a device notification for every
        // historical row the very first time the app polls after
        // login/launch — just establish the baseline.
        _firstPoll = false;
        _lastSeenId = maxId;
        return;
      }

      final freshOnes = list.where((n) => n.id > _lastSeenId).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      for (final n in freshOnes) {
        await _showLocalNotification(n);
      }

      if (maxId > _lastSeenId) {
        _lastSeenId = maxId;
      }
    } catch (_) {
      // A missed poll isn't worth surfacing to the user.
    }
  }

  static Future<void> _showLocalNotification(AppNotification n) async {
    const androidDetails = AndroidNotificationDetails(
      'redemption_status_channel',
      'Redemption Status Updates',
      channelDescription:
          'Notifies you when the status of a reward redemption changes.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(n.id, n.title, n.message, details);
  }
}
