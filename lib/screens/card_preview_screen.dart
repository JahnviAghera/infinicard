import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/services/sharing_service.dart';

class CardPreviewScreen extends StatefulWidget {
  final BusinessCard card;

  const CardPreviewScreen({super.key, required this.card});

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showQR = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(widget.card.themeColor);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Card Preview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                SharingService().showShareOptions(context, widget.card),
            tooltip: 'Share Card',
          ),
          IconButton(
            icon: Icon(_showQR ? Icons.credit_card : Icons.qr_code),
            onPressed: () => setState(() => _showQR = !_showQR),
            tooltip: _showQR ? 'Show Card' : 'Show QR Code',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cardColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Preview'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Preview Tab
          _buildPreviewTab(cardColor),
          // Details Tab
          _buildDetailsTab(cardColor),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            SharingService().showShareOptions(context, widget.card),
        backgroundColor: cardColor,
        icon: const Icon(Icons.share),
        label: const Text('Share'),
      ),
    );
  }

  Widget _buildPreviewTab(Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_showQR) ...[
            _buildQRCodeCard(cardColor),
            const SizedBox(height: 24),
          ] else ...[
            _buildBusinessCard(cardColor),
            const SizedBox(height: 24),
          ],

          // Quick actions
          _buildQuickActions(cardColor),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.card.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.card.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                        ),
                      ),
                    ],
                    if (widget.card.company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.card.company,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Logo placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Contact Information
          if (widget.card.email.isNotEmpty)
            _buildContactRow(Icons.email, widget.card.email),
          if (widget.card.phone.isNotEmpty)
            _buildContactRow(Icons.phone, widget.card.phone),
          if (widget.card.website.isNotEmpty)
            _buildContactRow(Icons.language, widget.card.website),

          // Social Links
          if (widget.card.linkedIn.isNotEmpty ||
              widget.card.github.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.card.linkedIn.isNotEmpty)
                  _buildSocialIcon(Icons.work, widget.card.linkedIn),
                if (widget.card.linkedIn.isNotEmpty &&
                    widget.card.github.isNotEmpty)
                  const SizedBox(width: 12),
                if (widget.card.github.isNotEmpty)
                  _buildSocialIcon(Icons.code, widget.card.github),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildQRCodeCard(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan to Add Contact',
            style: TextStyle(
              color: cardColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardColor.withOpacity(0.2), width: 2),
            ),
            child: QrImageView(
              data: SharingService().generateQRData(widget.card),
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.card.name,
            style: TextStyle(
              color: cardColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.card.company.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.card.company,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.orange,
                onTap: () => SharingService().shareViaEmail(widget.card),
              ),
              _buildActionButton(
                icon: Icons.message,
                label: 'SMS',
                color: Colors.green,
                onTap: () => SharingService().shareViaSMS(widget.card),
              ),
              _buildActionButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: Colors.teal,
                onTap: () => SharingService().shareViaWhatsApp(widget.card),
              ),
              _buildActionButton(
                icon: Icons.copy,
                label: 'Copy',
                color: cardColor,
                onTap: () async {
                  await SharingService().copyToClipboard(widget.card);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard!'),
                        backgroundColor: cardColor,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          _buildDetailSection('Contact Information', [
            if (widget.card.email.isNotEmpty)
              _buildDetailRow('Email', widget.card.email, Icons.email),
            if (widget.card.phone.isNotEmpty)
              _buildDetailRow('Phone', widget.card.phone, Icons.phone),
            if (widget.card.website.isNotEmpty)
              _buildDetailRow('Website', widget.card.website, Icons.language),
          ], cardColor),
          const SizedBox(height: 24),

          // Professional Details
          _buildDetailSection('Professional Details', [
            _buildDetailRow('Name', widget.card.name, Icons.person),
            if (widget.card.title.isNotEmpty)
              _buildDetailRow('Title', widget.card.title, Icons.work),
            if (widget.card.company.isNotEmpty)
              _buildDetailRow('Company', widget.card.company, Icons.business),
          ], cardColor),

          // Social Links
          if (widget.card.linkedIn.isNotEmpty ||
              widget.card.github.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Social Links', [
              if (widget.card.linkedIn.isNotEmpty)
                _buildDetailRow(
                  'LinkedIn',
                  widget.card.linkedIn,
                  Icons.work,
                  isLink: true,
                ),
              if (widget.card.github.isNotEmpty)
                _buildDetailRow(
                  'GitHub',
                  widget.card.github,
                  Icons.code,
                  isLink: true,
                ),
            ], cardColor),
          ],

          // Metadata
          const SizedBox(height: 24),
          _buildDetailSection('Card Details', [
            _buildDetailRow(
              'Created',
              _formatDate(widget.card.createdAt),
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'Last Updated',
              _formatDate(widget.card.updatedAt),
              Icons.update,
            ),
          ], cardColor),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    List<Widget> children,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2B292A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                isLink
                    ? InkWell(
                        onTap: () async {
                          final uri = Uri.parse(value);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Color(widget.card.themeColor),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
