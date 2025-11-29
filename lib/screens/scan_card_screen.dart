import 'package:flutter/material.dart';

/// Minimal ScanCardScreen and OCRResultScreen implementations to satisfy
/// references from other screens. These provide basic UI and should be
/// extended with real scanning/OCR features as needed.

class ScanCardScreen extends StatelessWidget {
  const ScanCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Card'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.qr_code_scanner, size: 84, color: Colors.grey),
            SizedBox(height: 12),
            Text('Scanner placeholder', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class OCRResultScreen extends StatelessWidget {
  final String imagePath;

  const OCRResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image: $imagePath', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Recognized text will appear here.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'OCR output placeholder. Integrate OCR processing to show real results.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
