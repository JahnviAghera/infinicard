import 'package:flutter/material.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/services/sharing_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SharingScreen extends StatefulWidget {
  final BusinessCard card;

  const SharingScreen({super.key, required this.card});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final SharingService _sharingService = SharingService();
  bool _showQR = true;
  bool _useOnlineShare = true; // Toggle between online share QR and vCard QR

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Share Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () =>
                _sharingService.showShareOptions(context, widget.card),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Card Preview or QR Code
            GestureDetector(
              onTap: () {
                setState(() {
                  _showQR = !_showQR;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showQR ? _buildQRView() : _buildCardPreview(),
              ),
            ),

            const SizedBox(height: 16),

            // Toggle hint and QR mode switch
            Column(
              children: [
                Text(
                  _showQR
                      ? (_useOnlineShare
                            ? 'Online Share QR'
                            : 'Vitaual Ifnicard')
                      : 'Tap to show QR code',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (_showQR) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _useOnlineShare = !_useOnlineShare;
                      });
                    },
                    icon: Icon(
                      _useOnlineShare ? Icons.contacts : Icons.cloud,
                      size: 16,
                      color: Colors.blue,
                    ),
                    label: Text(
                      _useOnlineShare
                          ? 'Switch to Vitaual Ifnicard'
                          : 'Switch to Online Share',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Export Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExportOptions(),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    final themeColor = Color(widget.card.themeColor);
    return Container(
      key: const ValueKey('card'),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, themeColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.card.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.card.title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          Text(
            widget.card.company,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.card.email.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.card.email,
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          if (widget.card.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.card.phone,
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ],
          if (widget.card.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.language, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.card.website,
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildQRView() {
    // Use online share URL or vCard data
    final qrData = _useOnlineShare
        ? 'infinicard://share/${widget.card.id}' // Deep link for app-to-app sharing
        : _sharingService.generateVCard(widget.card); // Traditional vCard
    return Container(
      key: const ValueKey('qr'),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          const SizedBox(height: 16),
          Text(
            widget.card.name,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.card.company,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _useOnlineShare
                  ? Colors.green.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _useOnlineShare ? Icons.cloud_done : Icons.contacts,
                  size: 14,
                  color: _useOnlineShare ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  _useOnlineShare
                      ? 'Scan with InfiniCard'
                      : 'Scan with Google Lense',
                  style: TextStyle(
                    color: _useOnlineShare ? Colors.green : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionChip(
          icon: Icons.email,
          label: 'Email',
          color: Colors.red,
          onTap: () => _sharingService.shareViaEmail(widget.card),
        ),
        _buildActionChip(
          icon: Icons.message,
          label: 'SMS',
          color: Colors.green,
          onTap: () => _sharingService.shareViaSMS(widget.card),
        ),
        _buildActionChip(
          icon: Icons.chat,
          label: 'WhatsApp',
          color: const Color(0xFF25D366),
          onTap: () => _sharingService.shareViaWhatsApp(widget.card),
        ),
        _buildActionChip(
          icon: Icons.content_copy,
          label: 'Copy',
          color: Colors.blue,
          onTap: () async {
            await _sharingService.copyToClipboard(widget.card);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        // _buildExportTile(
        //   icon: Icons.contact_page,
        //   title: 'Export as vCard',
        //   subtitle: 'Save as .vcf file',
        //   onTap: () => _sharingService.shareVCardFile(widget.card),
        // ),
        const SizedBox(height: 12),
        _buildExportTile(
          icon: Icons.qr_code,
          title: 'Export QR Code',
          subtitle: 'Save QR code as image',
          onTap: () => _sharingService.shareQRCode(widget.card),
        ),
        const SizedBox(height: 12),
        _buildExportTile(
          icon: Icons.text_snippet,
          title: 'Share as Text',
          subtitle: 'Share contact details',
          onTap: () => _sharingService.shareAsText(widget.card),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A1B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
