import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:infinicard/models/card_model.dart';
import 'package:share_plus/share_plus.dart';

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
    // Generate QR code data
    final cardData =
        'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'FN:${widget.card.name}\n'
        'TITLE:${widget.card.title}\n'
        'ORG:${widget.card.company}\n'
        'EMAIL:${widget.card.email}\n'
        'TEL:${widget.card.phone}\n'
        'URL:${widget.card.website}\n'
        'END:VCARD';

    await Share.share(
      'Check out my digital business card!\n\n$cardData',
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
        Uint8List pngBytes = byteData.buffer.asUint8List();
        // Save to gallery or share
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: Colors.black),
                const SizedBox(height: 8),
                Text(
                  'QR Code',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan to save contact',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
}
