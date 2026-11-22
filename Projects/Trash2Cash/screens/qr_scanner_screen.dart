import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
 
class QrScannerScreen extends StatefulWidget {
  /// Called with the raw decoded QR value (e.g. the resident's userID).
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
 
  bool _handled = false; // prevents firing onScanned multiple times per scan
 
  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;
 
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
 
    final String? value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
 
    _handled = true;
    widget.onScanned(value);
 
    // Pop the scanner screen and return the scanned value too,
    // in case the caller prefers Navigator.pop result over the callback.
    if (mounted) Navigator.of(context).pop(value);
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
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
          ),
          // Simple viewfinder overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
/// Example usage from another screen:
///
/// final scannedUserId = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => QrScannerScreen(
///       onScanned: (code) {
///         // e.g. send `code` to your PHP backend to identify the resident:
///         // POST https://yourserver/api/identify.php  { "qr_code": code }
///       },
///     ),
///   ),
/// );
///
/// if (scannedUserId != null) {
///   // handle the result, e.g. show resident info / points
/// }
 