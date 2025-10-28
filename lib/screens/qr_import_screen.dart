import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:infinicard/screens/vcard_import_screen.dart';

class QRImportScreen extends StatefulWidget {
  const QRImportScreen({super.key});

  @override
  State<QRImportScreen> createState() => _QRImportScreenState();
}

class _QRImportScreenState extends State<QRImportScreen> {
  bool _isScanning = true;
  final MobileScannerController _controller = MobileScannerController();

  void _handleRawValue(String? raw) {
    if (raw == null) return;

    // Normalize and parse URI for infinicard deep link patterns
    try {
      // If the scanned payload is a URI/deep-link, parse it and forward to the share route
      // Otherwise, if it's a raw vCard (BEGIN:VCARD) open the vCard importer
      final trimmed = raw.trim();

      // Detect vCard payloads (BEGIN:VCARD)
      if (trimmed.toUpperCase().contains('BEGIN:VCARD')) {
        _controller.stop();
        Navigator.of(context).pop();
        Future.microtask(
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VCardImportScreen(vcardRaw: trimmed),
            ),
          ),
        );
        return;
      }

      final uri = Uri.parse(trimmed);
      String? cardId;

      if (uri.scheme == 'infinicard' && uri.host == 'share') {
        cardId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.scheme == 'https' && uri.host == 'infinicard.app') {
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
          cardId = uri.pathSegments[1];
        }
      }

      if (cardId != null && cardId.isNotEmpty) {
        // Stop scanner and navigate back to import route
        _controller.stop();
        Navigator.of(context).pop();
        // Use named route handled by main.dart to open CardImportScreen
        Future.microtask(
          () => Navigator.of(context).pushNamed('/share/$cardId'),
        );
      }
    } catch (e) {
      // Not a URI; ignore
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
        title: const Text('Scan QR to Import'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (!_isScanning) return;
              final barcode = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first
                  : null;
              final value = barcode?.rawValue;
              if (value == null) return;
              setState(() => _isScanning = false);
              _handleRawValue(value);
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Point camera at an InfiniCard QR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
