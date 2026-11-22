import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:t2c/services/api_services.dart';
import './points_format.dart';

class MachineConnectedScreen extends StatefulWidget {
  final String machineCode;
  final String machineName;
  final int sessionID;

  const MachineConnectedScreen({
    super.key,
    required this.machineCode,
    required this.machineName,
    required this.sessionID,
  });

  @override
  State<MachineConnectedScreen> createState() => _MachineConnectedScreenState();
}

class _MachineConnectedScreenState extends State<MachineConnectedScreen> {
  static const int _inactivityLimit = 120; // seconds, pisonet-style timeout

  // AssetSource paths are relative to the "assets/" folder declared in
  // pubspec.yaml (the "assets/" prefix is added automatically), so this
  // maps to assets/T2C.MP3 at the project root. Case must match the
  // real filename exactly — Android/iOS are case-sensitive.
  static const String _connectSoundAsset = 'T2C.MP3';

  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _fetching = false;
  bool _ending = false;

  String _status = 'ready';
  double _points = 0.0;
  int _items = 0;
  String _lastItem = 'None';

  int _secondsRemaining = _inactivityLimit;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasPlayedConnectSound = false;

  @override
  void initState() {
    super.initState();

    _getMachineStatus();
    _startPolling();
    _startCountdown();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _getMachineStatus();
    });
  }

  // Pisonet-style inactivity countdown: ticks down every second.
  // Any accepted deposit resets it back to the full limit. If it hits 0
  // with no activity, the session ends automatically.
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        _endSession(auto: true);
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  void _resetCountdown() {
    _secondsRemaining = _inactivityLimit;
  }

  // Plays the pisonet-style "connected / ready" chime, once per session.
  Future<void> _playConnectSound() async {
    if (_hasPlayedConnectSound) return;
    _hasPlayedConnectSound = true;

    try {
      await _audioPlayer.play(AssetSource(_connectSoundAsset));
    } catch (_) {
      // Sound is a nice-to-have; never let audio failures affect the flow.
    }
  }

  Future<void> _getMachineStatus() async {
    // Skip this tick if the previous request is still running.
    if (_fetching) return;
    _fetching = true;

    try {
      final response = await ApiService.getMachineStatus(widget.sessionID);

      // The screen may already be gone when the response comes back.
      if (!mounted) return;

      // A transient failure just skips this tick; the next poll retries.
      // FIX: log the reason so a parsing/API problem is no longer invisible.
      if (!response.success || response.data is! MachineStatus) {
        debugPrint('Machine status poll failed: ${response.message}');
        return;
      }

      final s = response.data as MachineStatus;

      // FIX: the machine can report 'depositing' while an item is being
      // processed. Treat it the same as 'ready' so the numbers still update.
      final bool acceptingData = s.status == 'ready' || s.status == 'depositing';

      // Detect new deposit activity (more items accepted than before)
      // so we know whether to reset the inactivity countdown.
      final bool hasNewActivity = acceptingData && s.itemsAccepted > _items;

      // First time the machine reports 'ready' -> it just connected.
      final bool justConnected =
          s.status == 'ready' && !_hasPlayedConnectSound;

      setState(() {
        _status = s.status;

        // Only take the deposit data while the machine is ready/depositing.
        if (acceptingData) {
          _points = s.pointsEarned.toDouble();
          _items = s.itemsAccepted;
          _lastItem = s.lastItem;
        }

        if (hasNewActivity) {
          _resetCountdown();
        }
      });

      if (justConnected) {
        _playConnectSound();
      }

      // Session ended server-side: stop polling and the countdown.
      if (s.status == 'disconnected' || s.status == 'completed') {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _endSession({bool auto = false}) async {
    if (_ending) return;
    setState(() => _ending = true);

    // Stop polling/countdown so a late response can't overwrite the screen.
    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    final response = await ApiService.endSession(widget.sessionID);
    if (!mounted) return;

    if (response.success) {
      Navigator.pop(context);
    } else {
      // Failed: resume polling/countdown and let the user try again.
      setState(() => _ending = false);
      if (!auto) _resetCountdown();
      _startPolling();
      _startCountdown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _status == 'ready' || _status == 'depositing';

    // PopScope catches BOTH the AppBar back arrow and the phone's
    // back button / back gesture. canPop: false blocks the normal pop,
    // then we end the session ourselves (which pops on success).
    // Requires Flutter 3.22+. On older versions use:
    //   onPopInvoked: (didPop) { if (didPop) return; _endSession(); }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _endSession();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trash2Cash Machine'),
          backgroundColor: const Color(0xFF1B6B3A),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Icon(
                ready ? Icons.check_circle : Icons.warning,
                size: 80,
                color: ready ? Colors.green : Colors.orange,
              ),

              const SizedBox(height: 15),

              Text(
                ready ? 'MACHINE READY' : _status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.machineName,
                style: const TextStyle(fontSize: 17, color: Colors.grey),
              ),

              Text(
                widget.machineCode,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Pisonet-style countdown indicator
              _CountdownBanner(secondsRemaining: _secondsRemaining),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'You can now deposit:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.local_drink,
                                size: 45,
                                color: Colors.blue,
                              ),
                              SizedBox(height: 5),
                              Text('PET Bottle'),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(
                                Icons.recycling,
                                size: 45,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 5),
                              Text('Aluminum Can'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Items',
                      value: '$_items',
                      icon: Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Points',
                      value: formatPoints(_points),
                      icon: Icons.stars,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                'Last accepted: $_lastItem',
                style: const TextStyle(fontSize: 15),
              ),

              const Spacer(),

              if (_ending)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ending session...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final int secondsRemaining;

  const _CountdownBanner({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final bool urgent = secondsRemaining <= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: urgent ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: urgent ? Colors.red : const Color(0xFF1B6B3A),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: urgent ? Colors.red : const Color(0xFF1B6B3A),
          ),
          const SizedBox(width: 10),
          Text(
            'Session ends in $secondsRemaining s',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: urgent ? Colors.red : const Color(0xFF1B6B3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1B6B3A), size: 30),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}