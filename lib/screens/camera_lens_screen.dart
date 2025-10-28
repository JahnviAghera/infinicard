import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:infinicard/screens/scan_card_screen.dart'; // for OCRResultScreen
import 'package:infinicard/screens/vcard_import_screen.dart';

class CameraLensScreen extends StatefulWidget {
  const CameraLensScreen({super.key});

  @override
  State<CameraLensScreen> createState() => _CameraLensScreenState();
}

class _CameraLensScreenState extends State<CameraLensScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Camera for OCR / capture
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;
  bool _isProcessing = false;

  // QR scanner
  final MobileScannerController _qrController = MobileScannerController();
  bool _isQrActive = false;
  bool _isScanningActive = false;
  String? _scannerError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Start OCR camera by default so the Lens opens ready to scan
    // (users expect the camera to start immediately).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index == 0) {
        _initCamera();
      }
    });
  }

  Future<void> _initCamera([int index = 0]) async {
    try {
      // Ensure camera permission is granted
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _cameraReady = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission is required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      final camIndex = index < _cameras!.length ? index : 0;
      _cameraController = CameraController(
        _cameras![camIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _cameraReady = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera init error: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _initCamera(index),
            ),
          ),
        );
      }
    }
  }

  void _onTabChanged() async {
    final idx = _tabController.index;
    // OCR tab index 0: ensure camera
    if (idx == 0) {
      // stop QR first to free the camera resource
      if (_isQrActive) {
        try {
          await _qrController.stop();
        } catch (e) {
          debugPrint('Error stopping QR controller: $e');
        }
        _isQrActive = false;
        setState(() {
          _isScanningActive = false;
          _scannerError = null;
        });
        // small delay to ensure resources are released
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!_cameraReady) await _initCamera();
    }

    // QR tab index 1: start QR scanner
    if (idx == 1) {
      _isQrActive = true;
      setState(() {
        _isScanningActive = true;
        _scannerError = null;
      });
      // If camera preview is running, dispose it first to free the hardware.
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.dispose();
        } catch (e) {
          debugPrint('Error disposing camera before QR start: $e');
        }
        _cameraController = null;
        _cameraReady = false;
        // small delay to ensure resources are released on some devices
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Ensure camera permission before starting scanner
      try {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          setState(() {
            _scannerError = 'Camera permission required';
            _isScanningActive = false;
          });
        } else {
          try {
            await _qrController.start();
          } catch (e) {
            debugPrint('QR start error: $e');
            setState(() {
              _scannerError = 'Scanner failed to start';
              _isScanningActive = false;
            });
          }
        }
      } catch (e) {
        debugPrint('QR permission/start error: $e');
        setState(() {
          _scannerError = 'Scanner failed to start';
          _isScanningActive = false;
        });
      }
    }

    // Gallery tab index 2: nothing heavy to init
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _cameraController?.dispose();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final XFile file = await _cameraController!.takePicture();
      // Navigate to OCR result screen
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OCRResultScreen(imagePath: file.path),
        ),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OCRResultScreen(imagePath: picked.path),
      ),
    );
  }

  void _handleQrRaw(String? raw) {
    if (raw == null) return;
    final trimmed = raw.trim();
    // raw vCard
    if (trimmed.toUpperCase().contains('BEGIN:VCARD')) {
      _qrController.stop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VCardImportScreen(vcardRaw: trimmed)),
      );
      return;
    }

    try {
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
        _qrController.stop();
        Navigator.of(context).pushNamed('/share/$cardId');
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lens'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'OCR'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR'),
            Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // OCR Tab
          _buildOcrTab(),
          // QR Tab
          _buildQrTab(),
          // Gallery Tab
          _buildGalleryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOcrTab() {
    if (!_cameraReady) {
      return Center(
        child: ElevatedButton(
          onPressed: () => _initCamera(),
          child: const Text('Start Camera for OCR'),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(child: CameraPreview(_cameraController!)),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Point camera at a business card',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _qrController,
          onDetect: (capture) {
            final barcode = capture.barcodes.isNotEmpty
                ? capture.barcodes.first
                : null;
            final value = barcode?.rawValue;
            if (value == null) return;
            setState(() {
              _isScanningActive = false;
            });
            _handleQrRaw(value);
          },
        ),
        // Scanning overlay
        if (_isScanningActive)
          const Align(alignment: Alignment.center, child: _ScanningOverlay()),
        // Error overlay with retry
        if (_scannerError != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _scannerError!,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _scannerError = null;
                      _isScanningActive = true;
                    });
                    try {
                      await _qrController.start();
                    } catch (e) {
                      setState(() => _scannerError = 'Failed to start scanner');
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
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
              'Point camera at a QR code',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _pickFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Pick image from gallery'),
      ),
    );
  }

  Widget _buildBottomActions() {
    final idx = _tabController.index;
    if (idx == 0) {
      // OCR capture
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isProcessing ? null : _capturePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (idx == 1) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () => _qrController.toggleTorch(),
              ),
              if (_scannerError != null)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _scannerError = null;
                      _isScanningActive = true;
                    });
                    try {
                      await _qrController.start();
                    } catch (e) {
                      setState(() => _scannerError = 'Failed to start scanner');
                    }
                  },
                  child: const Text('Retry Scanner'),
                ),
              TextButton.icon(
                onPressed: () async {
                  // allow manual pick of QR image from gallery
                  final XFile? picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null && mounted) {
                    // Try to detect vCard inside image? For now route to OCR preview
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OCRResultScreen(imagePath: picked.path),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.photo),
                label: const Text('From gallery'),
              ),
            ],
          ),
        ),
      );
    }

    // Gallery tab bottom area
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small scanning overlay widget
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 8),
          Text('Scanning...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
