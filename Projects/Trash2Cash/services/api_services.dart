import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:t2c/screens/rewards_screen.dart';
import 'package:t2c/screens/user_points.dart';

// ============================================
// ApiService — handles all HTTP calls to PHP
// ============================================

// Simple model for a past redemption, returned by getredemptions.php
class RedemptionRecord {
  final int id;
  final String rewardName;
  final int pointsUsed;
  final DateTime redeemedAt;
  final String image;
  final String status;

  RedemptionRecord({
    required this.id,
    required this.rewardName,
    required this.pointsUsed,
    required this.redeemedAt,
    required this.image,
    required this.status,
  });

  factory RedemptionRecord.fromJson(Map<String, dynamic> json) {
    return RedemptionRecord(
      id: json['id'] as int,
      rewardName: json['rewardName'] as String? ?? '',
      pointsUsed: json['pointsUsed'] as int? ?? 0,
      redeemedAt:
          DateTime.tryParse(json['redeemedAt'] as String? ?? '') ??
          DateTime.now(),
      image: json['image'] as String? ?? '',
      // Matches the `redemptions.status` enum: pending | awaiting to claim | completed
      status: (json['status'] as String?)?.trim().isNotEmpty == true
          ? json['status'] as String
          : 'pending',
    );
  }
}

// Simple model for the live state of a machine session, returned by
// get_machine_status.php and consumed by MachineConnectedScreen's polling.
class MachineStatus {
  final String status;
  final double pointsEarned;
  final int itemsAccepted;
  final String lastItem;

  MachineStatus({
    required this.status,
    required this.pointsEarned,
    required this.itemsAccepted,
    required this.lastItem,
  });

  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  // Points are fractional (0.50 / 0.25), so they must NOT go through toInt().
  // Also handles MySQL decimals that PHP sends as strings, e.g. "0.50".
  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  factory MachineStatus.fromJson(Map<String, dynamic> json) {
    return MachineStatus(
      status: json['status']?.toString() ?? 'ready',
      pointsEarned: _toDouble(json['pointsEarned']),
      itemsAccepted: _toInt(json['itemsAccepted']),
      lastItem: json['lastItem']?.toString() ?? 'None',
    );
  }
}

// Simple model for a notification row, generated server-side by the
// `trg_redemption_status_change` MySQL trigger whenever an admin changes a
// redemption's status. Returned by get_notifications.php.
class AppNotification {
  final int id;
  final int? redemptionId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.redemptionId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      redemptionId: json['redemptionId'] == null
          ? null
          : (json['redemptionId'] is int
                ? json['redemptionId'] as int
                : int.tryParse('${json['redemptionId']}')),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.149.200.62/trash2cash/php';

  static Future<ApiResponse> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$path');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return ApiResponse(
        success: data['success'] == true,
        message: data['message'] ?? 'Unknown error',
        data: data['user'],
      );
    } finally {
      client.close(force: true);
    }
  }

  // FIX: _postJson always pulls out the "user" key, which doesn't exist in
  // getuserpoints.php's or getrewards.php's response shape. This raw
  // variant returns the whole decoded map instead, so those endpoints can
  // pull out whatever key they actually use ("points", "rewards", etc.).
  static Future<ApiResponse> _postJsonRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$path');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return ApiResponse(
        success: data['success'] == true,
        message: data['message'] ?? 'Unknown error',
        data: data,
      );
    } finally {
      client.close(force: true);
    }
  }

  // ---------- REGISTER ----------
  static Future<ApiResponse> register({
    required String username,
    required String firstname,
    required String lastname,
    String? middlename,
    String? gender,
    String? contact,
    String? address,
    required String email,
    required String password,
  }) async {
    try {
      return await _postJson('register.php', {
        'username': username,
        'firstname': firstname,
        'lastname': lastname,
        'middlename': middlename,
        'gender': gender,
        'contact': contact,
        'address': address,
        'email': email,
        'password': password,
      });
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // ---------- LOGIN ----------
  static Future<ApiResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      return await _postJson('userlogin.php', {
        'username': username,
        'password': password,
      });
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // ---------- REGISTER + AUTO LOGIN ----------
  // NEW: registers the user, then immediately logs them in with the same
  // credentials so the app can skip the login screen. On success, `data`
  // holds the same user map that login() returns (including id / userID).
  static Future<ApiResponse> registerAndLogin({
    required String username,
    required String firstname,
    required String lastname,
    String? middlename,
    String? gender,
    String? contact,
    String? address,
    required String email,
    required String password,
  }) async {
    final reg = await register(
      username: username,
      firstname: firstname,
      lastname: lastname,
      middlename: middlename,
      gender: gender,
      contact: contact,
      address: address,
      email: email,
      password: password,
    );

    if (!reg.success) return reg;

    // Registration worked -> log in right away.
    final loginResult = await login(username: username, password: password);

    if (!loginResult.success) {
      // Account was created but auto-login failed; the UI can fall back
      // to the normal login screen.
      return ApiResponse(
        success: false,
        message: 'Account created. Please log in.',
      );
    }

    return loginResult;
  }

  // ---------- REDEEM REWARD ----------
  static Future<ApiResponse> redeemReward({
    required int userId,
    required int rewardId,
  }) async {
    try {
      return await _postJsonRaw('redeem.php', {
        'userId': userId,
        'rewardId': rewardId,
      });
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // ---------- CANCEL REDEMPTION ----------
  static Future<ApiResponse> cancelRedemption({
    required int userId,
    required int redemptionId,
  }) async {
    try {
      return await _postJsonRaw('cancel_redemption.php', {
        'user_id': userId,
        'redemption_id': redemptionId,
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unable to cancel redemption: $e',
      );
    }
  }

  // ---------- GET REDEMPTION HISTORY ----------
  static Future<List<RedemptionRecord>> getRedemptions(int userId) async {
    final response = await _postJsonRaw('getredemptions.php', {
      'userId': userId,
    });
    if (!response.success) {
      throw Exception(response.message);
    }
    final List<dynamic> list =
        (response.data as Map<String, dynamic>)['redemptions'] ?? [];
    return list
        .map((r) => RedemptionRecord.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ---------- NOTIFICATIONS ----------
  // Polled by NotificationManager. Returns both the list (for the
  // notifications screen) and an unread count (for the dashboard bell
  // badge) in one round trip.
  static Future<ApiResponse> getNotifications(int userId) async {
    try {
      final response = await _postJsonRaw('get_notifications.php', {
        'userId': userId,
      });
      if (!response.success) return response;

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> list = data['notifications'] ?? [];
      final notifications = list
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList();

      final unread = data['unreadCount'] is int
          ? data['unreadCount'] as int
          : int.tryParse('${data['unreadCount']}') ?? 0;

      return ApiResponse(
        success: true,
        message: response.message,
        data: {'notifications': notifications, 'unreadCount': unread},
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // Marks the given notification ids as read, or ALL of the user's
  // notifications if notificationIds is omitted.
  static Future<void> markNotificationsRead(
    int userId, {
    List<int>? notificationIds,
  }) async {
    try {
      await _postJsonRaw('mark_notifications_read.php', {
        'userId': userId,
        if (notificationIds != null) 'notificationIds': notificationIds,
      });
    } catch (_) {
      // Non-critical — silently ignore, same as heartbeat/logout failures.
    }
  }

  // ---------- HEARTBEAT ----------
  static Future<void> sendHeartbeat(int userId) async {
    try {
      await _postJson('heartbeat.php', {'userId': userId});
    } catch (_) {
      // Silently ignore — a missed heartbeat isn't worth surfacing to the user.
    }
  }

  static Future<void> logout(int userId) async {
    try {
      await _postJson('logout.php', {'userId': userId});
    } catch (_) {
      // Don't block the local logout flow if this fails — the user is
      // leaving the app regardless, and heartbeats have already stopped.
    }
  }

  // ---------- GET USER POINTS ----------
  static Future<ApiResponse> getUserPoints(int userId) async {
    try {
      final response = await _postJsonRaw('getuserpoints.php', {
        'userId': userId,
      });
      if (!response.success) return response;

      final pointsJson =
          (response.data as Map<String, dynamic>)['points']
              as Map<String, dynamic>?;
      if (pointsJson == null) {
        return ApiResponse(
          success: false,
          message: 'Malformed response from server.',
        );
      }

      return ApiResponse(
        success: true,
        message: response.message,
        data: UserPoints.fromJson(pointsJson),
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // ---------- GET REWARDS ----------
  // baseUrl already ends in "/php", so the endpoint is
  // "$baseUrl/getrewards.php", not "$baseUrl/php/...".
  static Uri get _rewardsEndpoint => Uri.parse('$baseUrl/getrewards.php');

  static Future<List<Reward>> fetchRewards() async {
    final response = await http
        .get(_rewardsEndpoint)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode}).');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load rewards.');
    }

    final List<dynamic> rewardsJson = data['rewards'] ?? [];
    return rewardsJson
        .map((r) => Reward.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // getrewards.php returns a relative path like "uploads/rewards/xxx.jpg"
  // relative to the *app root* (trash2cash), not to the /php folder, so
  // strip the trailing "/php" off baseUrl before appending it.
  static String rewardImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final root = baseUrl.endsWith('/php')
        ? baseUrl.substring(0, baseUrl.length - '/php'.length)
        : baseUrl;
    return '$root/${path.startsWith('/') ? path.substring(1) : path}';
  }

  // ---------- CONNECT TO MACHINE ----------
  static Future<Map<String, dynamic>> connectToMachine({
    required int userId,
    required String machineCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/connect_machine.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {'userID': userId.toString(), 'machineCode': machineCode},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server returned status ${response.statusCode}.',
        };
      }

      final data = jsonDecode(response.body);

      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ---------- GET MACHINE STATUS ----------
  // Polled by MachineConnectedScreen every 2s so the UI reflects each
  // deposit (points/items/lastItem) as it happens, without the app needing
  // to talk to the ESP8266/vending hardware directly.
  static Future<ApiResponse> getMachineStatus(int sessionID) async {
    try {
      final response = await _postJsonRaw('get_machine_status.php', {
        'sessionID': sessionID,
      });
      if (!response.success) return response;

      final data = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        message: response.message,
        data: MachineStatus.fromJson(data),
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }

  // ---------- END MACHINE SESSION ----------
  // Sets machine_sessions.status to 'disconnected' via end_session.php.
  static Future<ApiResponse> endSession(int sessionID) async {
    try {
      return await _postJsonRaw('end_session.php', {'sessionID': sessionID});
    } catch (_) {
      return ApiResponse(
        success: false,
        message:
            'Cannot connect to server. Check your internet or server address.',
      );
    }
  }
}

// Simple response wrapper
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});
}