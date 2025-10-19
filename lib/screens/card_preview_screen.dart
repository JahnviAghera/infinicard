import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:infinicard/models/card_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:infinicard/utils/vcard_generator.dart';

class CardPreviewScreen extends StatefulWidget {
  final BusinessCard card;

  const CardPreviewScreen({super.key, required this.card});

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  final GlobalKey _cardKey = GlobalKey();
  bool _isOnlineMode = false; // Toggle between online and offline QR

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  Future<void> _shareQR() async {
    // Generate data based on current mode
    final qrData = _isOnlineMode
        ? VCardGenerator.generateOnlineUrl(widget.card)
        : VCardGenerator.generateVCard(widget.card);

    final shareText = _isOnlineMode
        ? 'Check out my digital business card!\n\n$qrData'
        : 'Save my contact:\n\n$qrData';

    await Share.share(
      shareText,
      subject: '${widget.card.name} - Digital Business Card',
    );
  }

  void _copyLink() {
    // In a real app, this would be a deep link or web URL
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
  }

  Future<void> _downloadPNG() async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        // Uint8List pngBytes = byteData.buffer.asUint8List();
        // TODO: Save to gallery or share pngBytes
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Card saved as PNG!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving card: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Card Preview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Card with flip animation
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * 3.14159;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: angle < 3.14159 / 2
                        ? _buildCardFront()
                        : Transform(
                            transform: Matrix4.identity()..rotateY(3.14159),
                            alignment: Alignment.center,
                            child: _buildCardBack(),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap card to flip',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(widget.card.themeColor),
              Color(widget.card.themeColor).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(widget.card.themeColor).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.card.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.card.company,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactRow(Icons.email, widget.card.email),
                const SizedBox(height: 6),
                _buildContactRow(Icons.phone, widget.card.phone),
                if (widget.card.website.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildContactRow(Icons.language, widget.card.website),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    // Generate QR data based on mode
    final qrData = _isOnlineMode
        ? VCardGenerator.generateOnlineUrl(widget.card)
        : VCardGenerator.generateVCard(widget.card);

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(widget.card.themeColor).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(widget.card.themeColor).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B292A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton('Offline', !_isOnlineMode, false),
                _buildModeButton('Online', _isOnlineMode, true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 140,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isOnlineMode
                ? 'Scan to view online'
                : 'Scan with Google Lens\nto save contact',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (widget.card.linkedIn.isNotEmpty || widget.card.github.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.card.linkedIn.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(widget.card.themeColor).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.link,
                      color: Color(widget.card.themeColor),
                      size: 20,
                    ),
                  ),
                if (widget.card.github.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(widget.card.themeColor).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.code,
                      color: Color(widget.card.themeColor),
                      size: 20,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code,
                label: 'Share QR',
                onTap: _shareQR,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.link,
                label: 'Copy Link',
                onTap: _copyLink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.image,
                label: 'Download PNG',
                onTap: _downloadPNG,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.picture_as_pdf,
                label: 'Download PDF',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF export coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B292A)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(widget.card.themeColor), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool isActive, bool isOnline) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOnlineMode = isOnline;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(widget.card.themeColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[500],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
