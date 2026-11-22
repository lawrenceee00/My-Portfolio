import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import './machine_qr_screen.dart';
import './machine_connected_screen.dart';
import './rewards_screen.dart';
import './user_points.dart';
import 'package:t2c/services/api_services.dart';
import './heartbeat_manager.dart';
import './notification_manager.dart';
import './notifications_screen.dart';
import './points_format.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  Map<String, dynamic> userData = {};

  bool _heartbeatStarted = false;
  bool _rewardReminderEnabled = false;
  bool _showRewardsBadge = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ──────────────────────────────────────────────────────────
  // COLORS
  // ──────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF1B6B3A);
  static const Color primaryLt = Color(0xFF2E9E5B);
  static const Color accent = Color(0xFF00C96B);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF0E2018);
  static const Color textMid = Color(0xFF4A6557);
  static const Color textLight = Color(0xFF8FAE9C);
  static const Color cardBorder = Color(0xFFDDEDE4);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      userData = args;
    }

    if (!_heartbeatStarted && _userId != 0) {
      _heartbeatStarted = true;
      HeartbeatManager.start(_userId);
      NotificationManager.start(_userId);
    }
  }

  @override
  void dispose() {
    HeartbeatManager.stop();
    NotificationManager.stop();
    _fadeController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // USER INFORMATION
  // ──────────────────────────────────────────────────────────

  String get _firstName =>
      (userData['first_name'] ?? userData['username'] ?? 'User').toString();

  String get _lastName => (userData['lastname'] ?? '').toString();

  String get _username => (userData['username'] ?? '').toString();

  String get _email => (userData['email'] ?? '').toString();

  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0] : '';
    final l = _lastName.isNotEmpty ? _lastName[0] : '';

    final initials = (f + l).toUpperCase();

    return initials.isEmpty ? 'U' : initials;
  }

  int get _userId =>
      int.tryParse('${userData['id'] ?? userData['userID'] ?? ''}') ?? 0;

  // ──────────────────────────────────────────────────────────
  // PAGE TITLES
  // ──────────────────────────────────────────────────────────

  final List<String> _pageTitles = [
    'Dashboard',
    'Rewards',
    'Scan QR',
    'Redeemed Rewards',
    'My Profile',
  ];

  // ──────────────────────────────────────────────────────────
  // NAVIGATION
  // ──────────────────────────────────────────────────────────

  void _onNavTap(int i) {
    HapticFeedback.selectionClick();

    _fadeController.reset();

    setState(() {
      _selectedIndex = i;
    });

    _fadeController.forward();
  }

  // ──────────────────────────────────────────────────────────
  // SNACKBAR
  // ──────────────────────────────────────────────────────────

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // LOGOUT
  // ──────────────────────────────────────────────────────────

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Log out?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: textMid, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textMid)),
          ),
          ElevatedButton(
            onPressed: () {
              HeartbeatManager.stop();
              NotificationManager.stop();

              ApiService.logout(_userId);

              Navigator.pop(context);

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        firstName: _firstName,
        initials: _initials,
        userId: _userId,
        onLogout: _confirmLogout,
        onNav: _onNavTap,
        onSnack: _snack,
      ),

      _RewardsTab(
        onSnack: _snack,
        userId: _userId,
        reminderEnabled: _rewardReminderEnabled,
        onReminderChanged: (v) {
          setState(() {
            _rewardReminderEnabled = v;
          });
        },
        onBadgeChanged: (v) {
          if (v != _showRewardsBadge) {
            setState(() {
              _showRewardsBadge = v;
            });
          }
        },
      ),

      // ──────────────────────────────────────────────────────
      // QR MACHINE CONNECTION
      // ──────────────────────────────────────────────────────
      _QrTab(userId: _userId),

      _RedeemTab(onSnack: _snack, userId: _userId),

      _ProfileTab(
        firstName: _firstName,
        lastName: _lastName,
        username: _username,
        email: _email,
        initials: _initials,
        onLogout: _confirmLogout,
        onSnack: _snack,
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      body: FadeTransition(opacity: _fadeAnim, child: pages[_selectedIndex]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION
  // ──────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      {
        'icon': Icons.home_outlined,
        'active': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'icon': Icons.card_giftcard_outlined,
        'active': Icons.card_giftcard_rounded,
        'label': 'Rewards',
      },
      {
        'icon': Icons.qr_code_scanner,
        'active': Icons.qr_code_scanner,
        'label': '',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'active': Icons.receipt_long_rounded,
        'label': 'Redeemed',
      },
      {
        'icon': Icons.person_outline,
        'active': Icons.person_rounded,
        'label': 'Profile',
      },
    ];

    return SizedBox(
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: cardBorder, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: List.generate(items.length, (i) {
                    if (i == 2) {
                      return const Expanded(child: SizedBox());
                    }

                    final active = _selectedIndex == i;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onNavTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? accent.withOpacity(0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      active
                                          ? items[i]['active'] as IconData
                                          : items[i]['icon'] as IconData,
                                      color: active ? primary : textLight,
                                      size: 22,
                                    ),

                                    if (i == 1 && _showRewardsBadge)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: active ? primary : textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // ───────────────────────────────────────────────────
          // CENTER QR BUTTON
          // ───────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _onNavTap(2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E88E5).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED COLORS
// ══════════════════════════════════════════════════════════════

const _primary = Color(0xFF1B6B3A);
const _primaryLt = Color(0xFF2E9E5B);
const _accent = Color(0xFF00C96B);
const _surface = Color(0xFFFFFFFF);
const _bg = Color(0xFFF4F8F5);
const _textDark = Color(0xFF0E2018);
const _textMid = Color(0xFF4A6557);
const _textLight = Color(0xFF8FAE9C);
const _border = Color(0xFFDDEDE4);

// ══════════════════════════════════════════════════════════════
// SHARED CARD
// ══════════════════════════════════════════════════════════════

Widget _card({required Widget child, EdgeInsets? padding, Color? color}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color ?? _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

// ══════════════════════════════════════════════════════════════
// SECTION TITLE
// ══════════════════════════════════════════════════════════════

Widget _sectionTitle(String t) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _textDark,
        letterSpacing: .1,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// APP BAR
// ══════════════════════════════════════════════════════════════

SliverAppBar _appBar({required String title, List<Widget>? actions}) {
  return SliverAppBar(
    backgroundColor: _surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    floating: true,
    snap: true,
    pinned: false,
    title: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryLt, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.recycling, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: .1,
          ),
        ),
      ],
    ),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, color: _border),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// PILL BADGE
// ══════════════════════════════════════════════════════════════

Widget _pillBadge(IconData icon, String label, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: fg, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// REDEMPTION STATUS BADGE
// ══════════════════════════════════════════════════════════════
//
// Shared by _RewardsTab ("My Redemption Status") and _RedeemTab (the full
// Redeemed Rewards history), so the same pending / awaiting to claim /
// completed / cancelled pill always looks identical wherever it shows up.

Widget _statusBadge(String status) {
  final normalized = status.toLowerCase().trim();

  Color bg;
  Color fg;
  IconData icon;

  switch (normalized) {
    case 'completed':
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      break;
    case 'awaiting to claim':
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
      icon = Icons.inventory_2_rounded;
      break;
    case 'cancelled':
      bg = const Color(0xFFECEFF1);
      fg = const Color(0xFF546E7A);
      icon = Icons.cancel_rounded;
      break;
    case 'pending':
    default:
      bg = const Color(0xFFF3E5F5);
      fg = const Color(0xFF6A1B9A);
      icon = Icons.hourglass_top_rounded;
      break;
  }

  final label = normalized.isEmpty
      ? 'Pending'
      : normalized[0].toUpperCase() + normalized.substring(1);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// CANCEL REDEMPTION (shared by Rewards tab and Redeemed tab)
// ══════════════════════════════════════════════════════════════
//
// Only "pending" redemptions can be cancelled. Once the status moves to
// "awaiting to claim" or "completed" the reward has already been prepared
// or handed out, so the cancel button is hidden.


bool _canCancel(String status) {
  final normalized = status.toLowerCase().trim();

  return normalized == 'pending' ||
      normalized == 'awaiting to claim';
}

bool _isCancelled(String status) {
  return status.toLowerCase().trim() == 'cancelled';
}


/// Asks for confirmation, calls the API, shows a snackbar.
/// Returns true if the redemption was cancelled (so the caller can refresh
/// points, rewards stock and the redemption list).

Future<bool> _cancelRedemption(
  BuildContext context, {
  required int userId,
  required RedemptionRecord record,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Cancel redemption?'),
      content: Text(
        'Cancel "${record.rewardName}"? '
        '${record.pointsUsed} pts will be returned to your balance.',
        style: const TextStyle(
          color: _textMid,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Keep it',
            style: TextStyle(color: _textMid),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel redemption'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    return false;
  }

  final messenger = ScaffoldMessenger.of(context);

  void showMessage(String message, {bool error = false}) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  try {
    final result = await ApiService.cancelRedemption(
      userId: userId,
      redemptionId: record.id,
    );

    if (!context.mounted) return false;

    showMessage(
      result.message,
      error: !result.success,
    );

    return result.success;
  } catch (e) {
    if (context.mounted) {
      showMessage(
        'Unable to cancel redemption: $e',
        error: true,
      );
    }
    return false;
  }
}


// ══════════════════════════════════════════════════════════════
// TAB 3 — QR MACHINE CONNECTION
// ══════════════════════════════════════════════════════════════

class _QrTab extends StatefulWidget {
  final int userId;

  const _QrTab({required this.userId});

  @override
  State<_QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<_QrTab> {
  bool _connecting = false;

  bool _scannerOpened = false;

  @override
  void initState() {
    super.initState();

    // Automatically open the scanner when
    // the QR tab is selected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanAndConnect();
    });
  }

  Future<void> _scanAndConnect() async {
    if (!mounted) return;

    if (_scannerOpened) {
      return;
    }

    _scannerOpened = true;

    // Make sure a valid logged-in user exists.
    if (widget.userId <= 0) {
      _scannerOpened = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to identify your account. Please log in again.',
          ),
        ),
      );

      return;
    }

    // ────────────────────────────────────────────────────────
    // OPEN MACHINE QR SCANNER
    // ────────────────────────────────────────────────────────

    final String? machineCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const MachineQrScanner()),
    );

    _scannerOpened = false;

    if (!mounted || machineCode == null || machineCode.trim().isEmpty) {
      return;
    }

    final cleanMachineCode = machineCode.trim();

    setState(() {
      _connecting = true;
    });

    // ────────────────────────────────────────────────────────
    // SHOW CONNECTING DIALOG
    // ────────────────────────────────────────────────────────

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 20),
              Expanded(child: Text('Connecting to Trash2Cash machine...')),
            ],
          ),
        );
      },
    );

    try {
      // ──────────────────────────────────────────────────────
      // CALL PHP API
      // ──────────────────────────────────────────────────────

      final result = await ApiService.connectToMachine(
        userId: widget.userId,
        machineCode: cleanMachineCode,
      );

      if (!mounted) return;

      // Close loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _connecting = false;
      });

      // ──────────────────────────────────────────────────────
      // SUCCESS
      // ──────────────────────────────────────────────────────

      if (result['success'] == true) {
        final sessionID = int.tryParse('${result['sessionID'] ?? 0}') ?? 0;

        final machineName =
            result['machineName']?.toString() ?? 'Trash2Cash Machine 001';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MachineConnectedScreen(
              machineCode: cleanMachineCode,
              machineName: machineName,
              sessionID: sessionID,
            ),
          ),
        );

        return;
      }

      // ──────────────────────────────────────────────────────
      // API RETURNED ERROR
      // ──────────────────────────────────────────────────────

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Unable to connect to vending machine.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _connecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        title: const Text(
          'Connect to Machine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _connecting
              ? const CircularProgressIndicator(color: _primary)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 58,
                        color: _primary,
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Connect to a Trash2Cash Machine',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Scan the QR code displayed on the vending machine to connect your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textMid,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _scanAndConnect,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(
                          'Scan Machine QR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GENERIC QR SCANNER
// ══════════════════════════════════════════════════════════════

class QrScannerScreen extends StatefulWidget {
  final void Function(String code) onScanned;

  const QrScannerScreen({super.key, required this.onScanned});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _handled = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;

    final barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final String? value = barcodes.first.rawValue;

    if (value == null || value.trim().isEmpty) {
      return;
    }

    _handled = true;

    final code = value.trim();

    widget.onScanned(code);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(code);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () {
              _controller.toggleTorch();
            },
          ),

          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              _controller.switchCamera();
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Scan the QR code displayed on the Trash2Cash vending machine.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — HOME
// ══════════════════════════════════════════════════════════════
//
// NOTE: converted from StatelessWidget to StatefulWidget so it can
// fetch and display the signed-in user's real points balance (via
// ApiService.getUserPoints), instead of the previous hardcoded "0".

class _HomeTab extends StatefulWidget {
  final String firstName;
  final String initials;
  final int userId;

  final VoidCallback onLogout;
  final void Function(int) onNav;
  final void Function(String) onSnack;

  const _HomeTab({
    required this.firstName,
    required this.initials,
    required this.userId,
    required this.onLogout,
    required this.onNav,
    required this.onSnack,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  UserPoints? _points;
  bool _pointsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    if (mounted) {
      setState(() {
        _pointsLoading = true;
      });
    }

    try {
      final response = await ApiService.getUserPoints(widget.userId);

      if (!mounted) return;

      setState(() {
        _points = response.success ? response.data as UserPoints : null;
        _pointsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _points = null;
        _pointsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // .toDouble() works whether UserPoints.total is an int or a double.
    final double total = (_points?.total ?? 0).toDouble();

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadPoints,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _appBar(
            title: 'Trash2Cash',
            actions: [
              // ──────────────────────────────────────────────
              // NOTIFICATION BELL
              // ──────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ValueListenableBuilder<int>(
                    valueListenable: NotificationManager.unreadCount,
                    builder: (context, count, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: _primary,
                              size: 18,
                            ),
                          ),

                          if (count > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              GestureDetector(
                onTap: widget.onLogout,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryLt, _primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeBanner(total),

                const SizedBox(height: 22),

                _sectionTitle('Your Stats'),

                _buildStatsGrid(total),

                const SizedBox(height: 22),

                _sectionTitle('Recycle Point Guide'),

                _buildPriceGuide(),

                const SizedBox(height: 22),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(double total) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.firstName}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Ready to make a difference today?',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _pointsLoading
                            ? 'Loading your points...'
                            : '${formatPoints(total)} points — keep going!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double total) {
    final stats = [
      {
        'icon': Icons.monetization_on_outlined,
        'label': 'Earnings',
        'value': '₱0',
        'unit': 'total',
        'color': const Color(0xFF6A1B9A),
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Points',
        'value': _pointsLoading ? '...' : formatPoints(total),
        'unit': 'pts',
        'color': const Color(0xFFE65100),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: stats.map((s) {
        final c = s['color'] as Color;

        return _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38.5,
                height: 40,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s['icon'] as IconData, color: c, size: 22),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c,
                    ),
                  ),
                  Text(
                    '${s['unit']} ${s['label']}',
                    style: const TextStyle(fontSize: 11, color: _textLight),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceGuide() {
    final items = [
      {
        'type': 'Plastic Bottles',
        'price': '0.50 pts',
        'icon': Icons.water_outlined,
        'color': const Color(0xFF0277BD),
      },
      {
        'type': 'Aluminum Cans',
        'price': '0.25 pts',
        'icon': Icons.delete_outline,
        'color': const Color(0xFF607D8B),
      },
      {
        'type': 'Unidentified Items',
        'price': '0 pts',
        'icon': Icons.cancel_outlined,
        'color': const Color.fromARGB(255, 184, 4, 4),
      },
    ];

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: items.map((it) {
          final last = items.last == it;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (it['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        it['icon'] as IconData,
                        color: it['color'] as Color,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        it['type'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        it['price'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!last) Divider(height: 1, color: _border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return _card(
      child: Column(
        children: [
          const SizedBox(height: 8),

          Icon(icon, size: 44, color: _border),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _textLight),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 4 — REDEEMED REWARDS
// ══════════════════════════════════════════════════════════════

class _RedeemTab extends StatefulWidget {
  final void Function(String) onSnack;
  final int userId;

  const _RedeemTab({required this.onSnack, required this.userId});

  @override
  State<_RedeemTab> createState() => _RedeemTabState();
}

class _RedeemTabState extends State<_RedeemTab> {
  late Future<List<RedemptionRecord>> _future;

  @override
  void initState() {
    super.initState();

    _future = ApiService.getRedemptions(widget.userId);
  }

  Future<void> _refresh() async {
    final future = ApiService.getRedemptions(widget.userId);

    setState(() {
      _future = future;
    });

    await future.catchError((_) => <RedemptionRecord>[]);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;

    final ampm = d.hour >= 12 ? 'PM' : 'AM';

    final minute = d.minute.toString().padLeft(2, '0');

    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _appBar(title: 'Redeemed Rewards'),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FutureBuilder<List<RedemptionRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _card(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            Icon(
                              Icons.wifi_off_rounded,
                              size: 40,
                              color: _border,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Couldn't load your redemptions",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textMid,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${snapshot.error}'.replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textLight,
                              ),
                            ),

                            const SizedBox(height: 14),

                            TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Try again'),
                              style: TextButton.styleFrom(
                                foregroundColor: _primary,
                              ),
                            ),

                            const SizedBox(height: 4),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return _card(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            Icon(
                              Icons.receipt_long_outlined,
                              size: 44,
                              color: _border,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'No redemptions yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textMid,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'Rewards you redeem will show up here.',
                              style: TextStyle(fontSize: 12, color: _textLight),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }

                    return _card(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        children: List.generate(items.length, (i) {
                          final r = items[i];

                          final isLast = i == items.length - 1;

                          final imgUrl = ApiService.rewardImageUrl(r.image);

                          final cancelled = _isCancelled(r.status);

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: imgUrl.isNotEmpty
                                            ? Image.network(
                                                imgUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: _primary
                                                          .withOpacity(0.08),
                                                      child: const Icon(
                                                        Icons
                                                            .card_giftcard_outlined,
                                                        color: _primary,
                                                        size: 20,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: _primary.withOpacity(
                                                  0.08,
                                                ),
                                                child: const Icon(
                                                  Icons.card_giftcard_outlined,
                                                  color: _primary,
                                                  size: 20,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.rewardName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _formatDate(r.redeemedAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _textLight,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // Status pill + Cancel button
                                          // (cancel only shows for pending).
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              _statusBadge(r.status),

                                              if (_canCancel(r.status))
                                                OutlinedButton(
                                                  onPressed: () async {
                                                    final ok =
                                                        await _cancelRedemption(
                                                          context,
                                                          userId: widget.userId,
                                                          record: r,
                                                        );

                                                    if (ok && mounted) {
                                                      await _refresh();
                                                    }
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red.shade600,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red.shade200,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                        ),
                                                    minimumSize: const Size(
                                                      0,
                                                      26,
                                                    ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Cancelled redemptions show the refund
                                    // (+pts) instead of a deduction (-pts).
                                    Text(
                                      cancelled
                                          ? '+${r.pointsUsed} pts'
                                          : '-${r.pointsUsed} pts',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: cancelled
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF6A1B9A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!isLast) Divider(height: 1, color: _border),
                            ],
                          );
                        }),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — REWARDS
// ══════════════════════════════════════════════════════════════

class _RewardsTab extends StatefulWidget {
  final void Function(String) onSnack;
  final int userId;
  final bool reminderEnabled;
  final void Function(bool) onReminderChanged;
  final void Function(bool) onBadgeChanged;

  const _RewardsTab({
    required this.onSnack,
    required this.userId,
    required this.reminderEnabled,
    required this.onReminderChanged,
    required this.onBadgeChanged,
  });

  @override
  State<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<_RewardsTab> {
  late Future<List<Reward>> _rewardsFuture;

  // The user's own redemption history, so "My Redemption Status" can
  // show pending / awaiting-to-claim / completed pills right on this page
  // instead of only in the separate Redeemed Rewards tab.
  late Future<List<RedemptionRecord>> _myRedemptionsFuture;

  UserPoints? _points;

  bool _pointsLoading = true;

  late bool _reminderEnabled = widget.reminderEnabled;

  List<Reward> _lastRewards = [];

  Timer? _rewardRefreshTimer;

  static const Duration _autoRefreshInterval = Duration(seconds: 10);

  static const List<Color> _palette = [
    Color(0xFF0277BD),
    Color(0xFF6A1B9A),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6D4C41),
    _primary,
  ];

  void _recomputeBadge() {
    final double total = (_points?.total ?? 0).toDouble();

    // Tolerance compare: exact == on doubles is unreliable once the
    // balance has decimals (e.g. 0.1 + 0.2).
    final hasExactMatch =
        _reminderEnabled &&
        _lastRewards.any((r) => (r.pointsRequired - total).abs() < 0.001);

    widget.onBadgeChanged(hasExactMatch);
  }

  @override
  void initState() {
    super.initState();

    _rewardsFuture = ApiService.fetchRewards();

    _rewardsFuture.then((list) {
      if (!mounted) return;

      _lastRewards = list;

      _recomputeBadge();
    });

    _myRedemptionsFuture = ApiService.getRedemptions(widget.userId);

    _loadPoints();

    _startAutomaticRewardRefresh();
  }

  void _startAutomaticRewardRefresh() {
    _rewardRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      _autoRefreshRewards();
    });
  }

  Future<void> _redeem(Reward r) async {
    final double total = (_points?.total ?? 0).toDouble();

    if (total < r.pointsRequired) {
      widget.onSnack('Need ${r.pointsRequired} pts to redeem "${r.name}".');

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Redeem reward?'),
        content: Text(
          'Redeem "${r.name}" for ${r.pointsRequired} points?',
          style: const TextStyle(color: _textMid, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await ApiService.redeemReward(
      userId: widget.userId,
      rewardId: r.id,
    );

    if (!mounted) return;

    widget.onSnack(response.message);

    if (response.success) {
      await _refresh();
    }
  }

  Future<void> _autoRefreshRewards() async {
    try {
      final rewards = await ApiService.fetchRewards();

      if (!mounted) return;

      setState(() {
        _rewardsFuture = Future.value(rewards);
      });

      _lastRewards = rewards;

      _recomputeBadge();
    } catch (_) {}
  }

  Future<void> _loadPoints() async {
    if (mounted) {
      setState(() {
        _pointsLoading = true;
      });
    }

    try {
      final response = await ApiService.getUserPoints(widget.userId);

      if (!mounted) return;

      setState(() {
        _points = response.success ? response.data as UserPoints : null;

        _pointsLoading = false;
      });

      _recomputeBadge();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _points = null;
        _pointsLoading = false;
      });

      _recomputeBadge();
    }
  }

  Future<void> _refresh() async {
    final future = ApiService.fetchRewards();

    setState(() {
      _rewardsFuture = future;
      _myRedemptionsFuture = ApiService.getRedemptions(widget.userId);
    });

    final results = await Future.wait<dynamic>([
      future.catchError((_) => <Reward>[]),
      _loadPoints(),
    ]);

    final rewards = results[0];

    if (rewards is List<Reward>) {
      _lastRewards = rewards;
    }

    _recomputeBadge();
  }

  @override
  void dispose() {
    _rewardRefreshTimer?.cancel();

    _rewardRefreshTimer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double total = (_points?.total ?? 0).toDouble();

    final double weekly = (_points?.weekly ?? 0).toDouble();

    return RefreshIndicator(
      color: _primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _appBar(title: 'Rewards'),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Points Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _pointsLoading
                                    ? const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        formatPoints(total),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),

                                const SizedBox(width: 6),

                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'pts',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                _pillBadge(
                                  Icons.trending_up_rounded,
                                  _pointsLoading
                                      ? '...'
                                      : '${weekly >= 0 ? '+' : ''}${formatPoints(weekly)} this week',
                                  Colors.white.withOpacity(0.2),
                                  Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ────────────────────────────────────────────
                // MY REDEMPTION STATUS
                // ────────────────────────────────────────────
                // Shows the user's own redemptions with a status pill
                // (pending / awaiting to claim / completed / cancelled)
                // right here on the Rewards page. Pending redemptions also
                // get a Cancel button that refunds the points.
                FutureBuilder<List<RedemptionRecord>>(
                  future: _myRedemptionsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting ||
                        items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final shown = items.length > 3
                        ? items.sublist(0, 3)
                        : items;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('My Redemption Status'),

                        _card(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Column(
                            children: List.generate(shown.length, (i) {
                              final r = shown[i];

                              final isLast = i == shown.length - 1;

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            r.rewardName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _statusBadge(r.status),

                                        if (_canCancel(r.status)) ...[
                                          const SizedBox(width: 4),
                                          TextButton(
                                            onPressed: () async {
                                              final ok =
                                                  await _cancelRedemption(
                                                    context,
                                                    userId: widget.userId,
                                                    record: r,
                                                  );

                                              if (ok && mounted) {
                                                await _refresh();
                                                await _loadPoints(); // <--- ADDED THIS LINE
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.red.shade600,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              minimumSize: const Size(0, 28),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(height: 1, color: _border),
                                ],
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 22),
                      ],
                    );
                  },
                ),

                _sectionTitle('Redeem Rewards'),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _reminderEnabled,
                        activeColor: _primary,
                        onChanged: (v) {
                          final enabled = v ?? false;

                          setState(() {
                            _reminderEnabled = enabled;
                          });

                          widget.onReminderChanged(enabled);

                          _recomputeBadge();
                        },
                      ),

                      const Expanded(
                        child: Text(
                          "Remind me when my points exactly match a reward's cost",
                          style: TextStyle(fontSize: 12.5, color: _textMid),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                FutureBuilder<List<Reward>>(
                  future: _rewardsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _card(
                        child: Column(
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 40,
                              color: _border,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Couldn't load rewards",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textMid,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }

                    final rewards = snapshot.data ?? [];

                    if (rewards.isEmpty) {
                      return _card(
                        child: const Column(
                          children: [
                            Icon(
                              Icons.card_giftcard_outlined,
                              size: 44,
                              color: _border,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No rewards available yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textMid,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Check back soon for new rewards.',
                              style: TextStyle(fontSize: 12, color: _textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      itemCount: rewards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, i) {
                        final r = rewards[i];

                        final color = _palette[i % _palette.length];

                        final imgUrl = ApiService.rewardImageUrl(r.image);

                        return GestureDetector(
                          onTap: () {
                            widget.onSnack(
                              'Need ${r.pointsRequired} pts to redeem "${r.name}"',
                            );
                          },
                          child: _card(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.6,
                                    child: imgUrl.isNotEmpty
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) {
                                                  return Container(
                                                    color: color.withOpacity(
                                                      0.1,
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .card_giftcard_outlined,
                                                      color: color,
                                                      size: 28,
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            color: color.withOpacity(0.1),
                                            child: Icon(
                                              Icons.card_giftcard_outlined,
                                              color: color,
                                              size: 28,
                                            ),
                                          ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _textDark,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.stars_rounded,
                                            size: 13,
                                            color: Color(0xFF6A1B9A),
                                          ),

                                          const SizedBox(width: 3),

                                          Text(
                                            '${r.pointsRequired} pts',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6A1B9A),
                                            ),
                                          ),

                                          const Spacer(),

                                          Text(
                                            'Qty ${r.quantity}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _textLight,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed:
                                              (total >= r.pointsRequired &&
                                                  r.quantity > 0)
                                              ? () => _redeem(r)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primary,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: _border,
                                            disabledForegroundColor: _textLight,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            r.quantity <= 0
                                                ? 'Out of stock'
                                                : 'Redeem',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 5 — PROFILE
// ══════════════════════════════════════════════════════════════

class _ProfileTab extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String initials;

  final VoidCallback onLogout;
  final void Function(String) onSnack;

  const _ProfileTab({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.initials,
    required this.onLogout,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'section': 'Account'},
      {
        'icon': Icons.person_outline,
        'label': 'Edit Profile',
        'color': _primary,
      },
      {
        'icon': Icons.lock_outline,
        'label': 'Change Password',
        'color': _primary,
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notification Settings',
        'color': _primary,
      },
      {'section': 'Activity'},
      {
        'icon': Icons.history_outlined,
        'label': 'Submission History',
        'color': _primary,
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Rewards History',
        'color': _primary,
      },
      {
        'icon': Icons.leaderboard_outlined,
        'label': 'My Rankings',
        'color': _primary,
      },
      {'section': 'Support'},
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Help & FAQ',
        'color': _primary,
      },
      {
        'icon': Icons.policy_outlined,
        'label': 'Privacy Policy',
        'color': _primary,
      },
      {
        'icon': Icons.info_outline_rounded,
        'label': 'About Trash2Cash',
        'color': _primary,
      },
    ];

    return CustomScrollView(
      slivers: [
        _appBar(title: 'My Profile'),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryLt, _primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$firstName ${lastName}'.trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),

                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        style: const TextStyle(fontSize: 14, color: _primary),
                      ),
                    ],

                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: _textLight),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _pillBadge(
                          Icons.stars_rounded,
                          '0 pts',
                          _primary.withOpacity(0.08),
                          _primary,
                        ),

                        const SizedBox(width: 8),

                        _pillBadge(
                          Icons.recycling,
                          '0 kg',
                          _accent.withOpacity(0.12),
                          _primary,
                        ),

                        const SizedBox(width: 8),

                        _pillBadge(
                          Icons.emoji_events_outlined,
                          'Rank —',
                          Colors.amber.withOpacity(0.1),
                          Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _card(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _statCol('0', 'Submissions'),
                    _vDivider(),
                    _statCol('₱0', 'Earned'),
                    _vDivider(),
                    _statCol('0', 'Rewards\nRedeemed'),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              ...menuItems.map((item) {
                if (item.containsKey('section')) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      item['section'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textLight,
                        letterSpacing: .6,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: ListTile(
                    onTap: () => onSnack('${item['label']} — coming soon!'),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: _primary,
                        size: 19,
                      ),
                    ),
                    title: Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: _textLight,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Log out',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Trash2Cash v1.0.0',
                  style: TextStyle(fontSize: 11, color: _textLight),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _statCol(String val, String lbl) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            lbl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _textLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(height: 36, width: 1, color: _border);
  }
}