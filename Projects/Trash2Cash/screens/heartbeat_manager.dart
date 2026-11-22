import 'dart:async';
import 'package:t2c/services/api_services.dart';

/// Keeps `last_activity` fresh on the server while a user is logged in.
/// Call HeartbeatManager.start(userId) right after a successful login,
/// and HeartbeatManager.stop() on logout / app termination.
class HeartbeatManager {
  static Timer? _timer;

  static void start(int userId) {
    // Avoid stacking multiple timers if start() is accidentally called twice.
    stop();

    // Fire one immediately so the user shows Active right away...
    ApiService.sendHeartbeat(userId);

    // ...then repeat well under the 5-minute ACTIVE_THRESHOLD_MINUTES
    // window defined in users.php, so a slow tick never flips someone
    // to Inactive by mistake.
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      ApiService.sendHeartbeat(userId);
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}