
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/screens/create_edit_card_screen.dart';
import 'package:infinicard/services/sharing_service.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CombinedScanScreen extends StatefulWidget {
  const CombinedScanScreen({super.key});

  @override
  _CombinedScanScreenState createState() => _CombinedScanScreenState();
}

class _CombinedScanScreenState extends State<CombinedScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleQRCode(String code) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    // Deep link check
    if (code.startsWith('https://infinicard.app/c/') || code.startsWith('infinicard://share/')) {
      final cardId = code.split('/').last;
      // Navigate to card import screen (assuming you have one)
      // Navigator.push(context, MaterialPageRoute(builder: (context) => CardImportScreen(cardId: cardId)));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deep link detected for card ID: $cardId')));
      // For now, just showing a snackbar
      setState(() {
        _isProcessing = false;
      });
    }
    // VCard check
    else if (code.startsWith('BEGIN:VCARD')) {
      // Parse vCard and navigate to create/edit screen
      final card = _parseVCard(code);
      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditCardScreen(card: card)));
    } else {
      // Treat as plain text, potential for OCR-like data from QR
      _navigateToCreateEdit(code);
    }
  }

  BusinessCard _parseVCard(String vcard) {
    String name = '';
    String email = '';
    String phone = '';
    String company = '';
    String title = '';
    String website = '';

    final lines = vcard.split('\n');
    for (var line in lines) {
      if (line.startsWith('FN:')) {
        name = line.substring(3);
      } else if (line.startsWith('EMAIL')) {
        email = line.substring(line.indexOf(':') + 1);
      } else if (line.startsWith('TEL')) {
        phone = line.substring(line.indexOf(':') + 1);
      } else if (line.startsWith('ORG')) {
        company = line.substring(4);
      } else if (line.startsWith('TITLE')) {
        title = line.substring(6);
      } else if (line.startsWith('URL')) {
        website = line.substring(4);
      }
    }

    return BusinessCard(
      id: 'new_vcard_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      title: title,
      company: company,
      email: email,
      phone: phone,
      website: website,
      linkedIn: '',
      github: '',
      themeColor: Colors.blue.value,
    );
  }

  Future<void> _scanFromImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if(mounted) {
        setState(() {
          _isProcessing = true;
        });
      }
      try {
        final ocrText = await TesseractOcr.extractText(pickedFile.path);
        _navigateToCreateEdit(ocrText);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  void _navigateToCreateEdit(String text) {
    // Basic parsing of OCR text. This can be improved with more advanced regex.
    final lines = text.split('\n');
    String name = lines.isNotEmpty ? lines[0] : '';
    String email = '';
    String phone = '';

    final emailRegex = RegExp(r'[\w-.]+@([\w-]+\.)+[\w-]{2,4}');
    final phoneRegex = RegExp(r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-\s.]?\d{3}[-\s.]?\d{4}');

    for (var line in lines) {
      if (emailRegex.hasMatch(line) && email.isEmpty) {
        email = emailRegex.stringMatch(line) ?? '';
      }
      if (phoneRegex.hasMatch(line) && phone.isEmpty) {
        phone = phoneRegex.stringMatch(line) ?? '';
      }
    }

    final card = BusinessCard(
      id: 'new_ocr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      title: '',
      company: '',
      website: '',
      linkedIn: '',
      github: '',
      themeColor: Colors.green.value,
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditCardScreen(card: card, isOcr: true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Card or QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _scanFromImage,
            tooltip: 'Scan from image',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _handleQRCode(barcodes.first.rawValue ?? '');
              }
            },
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
