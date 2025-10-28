import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:infinicard/screens/qr_import_screen.dart';

class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});

  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera([int cameraIndex = 0]) async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return;

      // Ensure index is within range
      final index = (cameraIndex < _cameras!.length) ? cameraIndex : 0;

      _controller = CameraController(
        _cameras![index],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.jpeg, // prevents video/audio pipeline creation
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization error: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _initializeCamera(cameraIndex),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile file = await _controller!.takePicture();

      // Dispose the camera controller to release hardware resources while
      // the OCR results screen is shown. We'll re-initialize when the user
      // returns to this screen.
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }

      // Simulate OCR processing delay (keep UX as before)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Push results screen and wait for result. When user returns,
      // re-initialize the camera.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OCRResultScreen(imagePath: file.path),
        ),
      );

      if (mounted) {
        await _initializeCamera();
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      // Attempt to recover camera state if it was disposed due to an error
      try {
        if (_controller == null) {
          await _initializeCamera();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _captureAndProcess,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          // Overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Scan Business Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_off, color: Colors.white),
                        onPressed: () {
                          // Toggle flash
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Card Frame
                Container(
                  width: 320,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(painter: CornerPainter()),
                ),
                const SizedBox(height: 16),
                Text(
                  'Position card within frame',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Bottom Controls
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    // gradient: LinearGradient(
                    //   colors: [
                    //     Colors.transparent,
                    //     Colors.black.withOpacity(0.7),
                    //   ],
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    // ),
                  ),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'Processing image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _captureAndProcess,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E7490),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0E7490,
                                  ).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          // Pick from gallery
                        },
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Choose from gallery',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Scan QR option to import a shared card directly
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QRImportScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Scan QR to import',
                          style: TextStyle(color: Colors.white),
                        ),
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

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // shift slightly left and up
    const double shiftLeft = -1.2;
    const double shiftUp = -1.2;
    canvas.translate(shiftLeft, shiftUp);

    final paint = Paint()
      ..color = const Color(0xFF0E7490)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Parameters
    final double strokeWidth = 4.0;
    paint.strokeWidth = strokeWidth;
    final double cornerRadius = 14.0; // match container
    final double lineLength = 28.0; // how far lines extend from the arc

    final double w = size.width + 2;
    final double h = size.height + 2;

    // Top-left arc and extender lines
    canvas.drawArc(
      Rect.fromLTWH(0, 0, cornerRadius * 2, cornerRadius * 2),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cornerRadius, 0),
      Offset(cornerRadius + lineLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, cornerRadius),
      Offset(0, cornerRadius + lineLength),
      paint,
    );

    // Top-right arc and extenders
    canvas.drawArc(
      Rect.fromLTWH(
        w - cornerRadius * 2,
        0,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(w - cornerRadius, 0),
      Offset(w - cornerRadius - lineLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(w, cornerRadius),
      Offset(w, cornerRadius + lineLength),
      paint,
    );

    // Bottom-right arc and extenders
    canvas.drawArc(
      Rect.fromLTWH(
        w - cornerRadius * 2,
        h - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      0,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(w - cornerRadius, h),
      Offset(w - cornerRadius - lineLength, h),
      paint,
    );
    canvas.drawLine(
      Offset(w, h - cornerRadius),
      Offset(w, h - cornerRadius - lineLength),
      paint,
    );

    // Bottom-left arc and extenders
    canvas.drawArc(
      Rect.fromLTWH(
        0,
        h - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cornerRadius, h),
      Offset(cornerRadius + lineLength, h),
      paint,
    );
    canvas.drawLine(
      Offset(0, h - cornerRadius),
      Offset(0, h - cornerRadius - lineLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class OCRResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, String>? initialData;

  const OCRResultScreen({super.key, required this.imagePath, this.initialData});

  @override
  State<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;

  bool _isDuplicateWarning = false;
  bool _isOcrRunning = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers from provided initialData if available.
    // If not provided, start with empty fields so user can edit / OCR can be applied.
    final data = widget.initialData ?? <String, String>{};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _titleController = TextEditingController(text: data['title'] ?? '');
    _companyController = TextEditingController(text: data['company'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _websiteController = TextEditingController(text: data['website'] ?? '');

    // If imagePath provided, run OCR to extract text and prefill fields
    if (widget.imagePath.isNotEmpty) {
      _runOcrAndParse();
    }

    // Simulate duplicate detection
    _checkForDuplicates();
  }

  Future<void> _runOcrAndParse() async {
    setState(() {
      _isOcrRunning = true;
    });
    try {
      // Try to load optional tesseract config from assets (not required):
      try {
        final confText = await rootBundle.loadString(
          'assets/tesseract_config.json',
        );
        if (confText.isNotEmpty) debugPrint('Loaded tesseract_config.json');
      } catch (e) {
        debugPrint('No tesseract config loaded from assets (this is okay): $e');
      }

      // Call extractText using the plugin's supported signature (imagePath).
      // The plugin may require platform tessdata files to be bundled (see error handling below).
      final raw = await TesseractOcr.extractText(widget.imagePath);
      debugPrint('OCR raw text: $raw');

      // Basic parsing heuristics
      final lines = raw
          .split(RegExp(r"\r?\n"))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      String name = '';
      String title = '';
      String company = '';
      String email = '';
      String phone = '';
      String website = '';

      final emailReg = RegExp(
        r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
        caseSensitive: false,
      );
      final phoneReg = RegExp(r"(\+?\d[\d\s\-()]{6,}\d)");
      final urlReg = RegExp(
        r"https?://[^\s]+|www\.[^\s]+",
        caseSensitive: false,
      );

      for (var line in lines) {
        if (email.isEmpty && emailReg.hasMatch(line)) {
          email = emailReg.firstMatch(line)!.group(0) ?? '';
        }
        if (phone.isEmpty && phoneReg.hasMatch(line)) {
          phone = phoneReg.firstMatch(line)!.group(0) ?? '';
        }
        if (website.isEmpty && urlReg.hasMatch(line)) {
          website = urlReg.firstMatch(line)!.group(0) ?? '';
        }
      }

      // Name: prefer first line that is not email/phone/url and is alphabetic
      for (var line in lines) {
        final low = line.toLowerCase();
        if (low.contains('@') ||
            phoneReg.hasMatch(line) ||
            urlReg.hasMatch(line)) {
          continue;
        }
        if (name.isEmpty && RegExp(r"[A-Za-z]{2,}").hasMatch(line)) {
          name = line;
          continue;
        }
        if (company.isEmpty && line.toLowerCase().contains('llc') ||
            line.toLowerCase().contains('inc') ||
            line.toLowerCase().contains('ltd')) {
          company = line;
        }
      }

      // Fallbacks
      if (name.isEmpty && lines.isNotEmpty) name = lines.first;

      // Populate controllers
      setState(() {
        _nameController.text = name;
        _titleController.text = title;
        _companyController.text = company;
        _emailController.text = email;
        _phoneController.text = phone;
        _websiteController.text = website.replaceAll(
          RegExp(r"^www\\."),
          'https://www.',
        );
      });
    } catch (e) {
      debugPrint('OCR error: $e');
      if (mounted) {
        final msg = e.toString();
        // Give a helpful error if tessdata / config not found
        if (msg.toLowerCase().contains('tessdata') ||
            msg.toLowerCase().contains('tessdata_config')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'OCR failed: tessdata not found. Place traineddata files in the app assets (android: android/app/src/main/assets/tessdata/eng.traineddata) or include tessdata in your build.',
              ),
              action: SnackBarAction(
                label: 'Help',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('tessdata not found'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'The Tesseract engine requires language traineddata files (for example eng.traineddata). Copy your .traineddata into Android assets under android/app/src/main/assets/tessdata/ and ensure pubspec or platform bundling includes them. For iOS, add tessdata files to the Runner bundle resources.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isOcrRunning = false);
    }
  }

  void _checkForDuplicates() {
    // Simulated duplicate detection - in real app, check against existing contacts
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isDuplicateWarning = false; // Set to true to show warning
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      // In a real app, save this contact to the database
      // final contact = Contact(...)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved successfully!')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('OCR Results'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Card scanned successfully! Review and edit the details below.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isDuplicateWarning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC107)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Color(0xFFFFC107)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A similar contact already exists. Review before saving.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Name *', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_titleController, 'Title', Icons.work),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _companyController,
                        'Company',
                        Icons.business,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email *', Icons.email),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone *', Icons.phone),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _websiteController,
                        'Website',
                        Icons.language,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF2B292A)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry Scan'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save Contact'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // OCR running overlay (hidden when not running)
          Positioned.fill(
            child: Visibility(
              visible: _isOcrRunning,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Card(
                      color: const Color(0xFF1C1A1B),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Running OCR...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        filled: true,
        fillColor: const Color(0xFF1C1A1B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B292A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B292A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
      validator: (value) {
        if (label.contains('*') && (value?.isEmpty ?? true)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
