import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MachineQrScanner extends StatefulWidget {
  const MachineQrScanner({super.key});

  @override
  State<MachineQrScanner> createState() => _MachineQrScannerState();
}

class _MachineQrScannerState extends State<MachineQrScanner> {
  bool _scanned = false;

  void _handleScan(BarcodeCapture capture) {
    if (_scanned) return;

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;

      if (value == null || value.trim().isEmpty) {
        continue;
      }

      final raw = value.trim();
      String? machineCode;

      // Support machine QR codes that encode a JSON payload, e.g.
      // {"type":"trash2cash_machine","machineCode":"TCM001","macAddress":"..."}
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map &&
            decoded['type'] == 'trash2cash_machine' &&
            decoded['machineCode'] != null) {
          machineCode = decoded['machineCode'].toString();
        }
      } catch (_) {
        // Not JSON — fall back to treating the raw value as the code itself.
        machineCode = raw;
      }

      // Only accept Trash2Cash machine codes.
      if (machineCode == null ||
          !RegExp(r'^TCM\d+$', caseSensitive: false)
              .hasMatch(machineCode)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Trash2Cash machine QR code.'),
          ),
        );
        return;
      }

      _scanned = true;

      Navigator.pop(
        context,
        machineCode.toUpperCase(),
      );

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Machine QR'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleScan,
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              children: const [
                Text(
                  'Scan the QR code on the vending machine',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}