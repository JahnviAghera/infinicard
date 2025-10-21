import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:infinicard/models/card_model.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  /// Generate vCard 3.0 format contact data
  String generateVCard(BusinessCard card) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    // Full name
    buffer.writeln('FN:${_escapeVCard(card.name)}');

    // Name components (Last;First;Middle;Prefix;Suffix)
    final nameParts = card.name.split(' ');
    if (nameParts.length >= 2) {
      buffer.writeln(
        'N:${_escapeVCard(nameParts.last)};${_escapeVCard(nameParts.first)};;;',
      );
    } else {
      buffer.writeln('N:${_escapeVCard(card.name)};;;;');
    }

    // Organization and title
    if (card.company.isNotEmpty) {
      buffer.writeln('ORG:${_escapeVCard(card.company)}');
    }
    if (card.title.isNotEmpty) {
      buffer.writeln('TITLE:${_escapeVCard(card.title)}');
    }

    // Contact details
    if (card.email.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=INTERNET:${_escapeVCard(card.email)}');
    }
    if (card.phone.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:${_escapeVCard(card.phone)}');
    }
    if (card.website.isNotEmpty) {
      buffer.writeln('URL:${_escapeVCard(card.website)}');
    }

    // Social links
    if (card.linkedIn.isNotEmpty) {
      buffer.writeln('URL;TYPE=LinkedIn:${_escapeVCard(card.linkedIn)}');
    }
    if (card.github.isNotEmpty) {
      buffer.writeln('URL;TYPE=GitHub:${_escapeVCard(card.github)}');
    }

    // Metadata
    buffer.writeln('NOTE:Shared via Infinicard');
    buffer.writeln('REV:${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('END:VCARD');

    return buffer.toString();
  }

  /// Escape special characters for vCard format
  String _escapeVCard(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }

  /// Generate human-readable text for sharing
  String generateReadableText(BusinessCard card) {
    final buffer = StringBuffer();

    buffer.writeln('📇 Digital Business Card');
    buffer.writeln('');
    buffer.writeln('👤 ${card.name}');

    if (card.title.isNotEmpty) {
      buffer.writeln('💼 ${card.title}');
    }
    if (card.company.isNotEmpty) {
      buffer.writeln('🏢 ${card.company}');
    }

    buffer.writeln('');
    buffer.writeln('Contact Information:');

    if (card.email.isNotEmpty) {
      buffer.writeln('📧 ${card.email}');
    }
    if (card.phone.isNotEmpty) {
      buffer.writeln('📱 ${card.phone}');
    }
    if (card.website.isNotEmpty) {
      buffer.writeln('🌐 ${card.website}');
    }

    // Social links
    final socialLinks = <String>[];
    if (card.linkedIn.isNotEmpty) {
      socialLinks.add('LinkedIn: ${card.linkedIn}');
    }
    if (card.github.isNotEmpty) {
      socialLinks.add('GitHub: ${card.github}');
    }

    if (socialLinks.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Social Links:');
      for (final link in socialLinks) {
        buffer.writeln('🔗 $link');
      }
    }

    buffer.writeln('');
    buffer.writeln('───────────────────');
    buffer.writeln('Shared via Infinicard 📱');

    return buffer.toString();
  }

  /// Generate shareable web link for the card
  /// This link works as both a deep link (if app installed) and web link (to download app)
  String generateShareLink(BusinessCard card) {
    // Using a web URL that supports universal/app links
    // When app is installed: Opens directly in app
    // When app is not installed: Opens web page with app download option
    return 'https://infinicard.app/c/${card.id}';
  }

  /// Generate text with shareable link
  String generateTextWithLink(BusinessCard card) {
    final buffer = StringBuffer();

    buffer.writeln('📇 ${card.name}');
    if (card.title.isNotEmpty) {
      buffer.writeln('${card.title}');
    }
    if (card.company.isNotEmpty) {
      buffer.writeln('🏢 ${card.company}');
    }

    if (card.email.isNotEmpty) {
      buffer.writeln('📧 ${card.email}');
    }
    if (card.phone.isNotEmpty) {
      buffer.writeln('📱 ${card.phone}');
    }

    buffer.writeln('');
    buffer.writeln('💳 View my digital business card:');
    buffer.writeln(generateShareLink(card));
    buffer.writeln('');
    buffer.writeln('(Opens in Infinicard app if installed, or get the app)');

    return buffer.toString();
  }

  /// Share card as text via system share sheet
  Future<void> shareAsText(
    BusinessCard card, {
    Rect? sharePositionOrigin,
    bool useLink = true, // Use web link by default
  }) async {
    try {
      final text = useLink
          ? generateTextWithLink(card)
          : generateReadableText(card);
      await Share.share(
        text,
        subject: '${card.name} - Business Card',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing as text: $e');
      rethrow;
    }
  }

  /// Share via email with contact data
  Future<void> shareViaEmail(
    BusinessCard card, {
    String? recipientEmail,
  }) async {
    try {
      final subject = Uri.encodeComponent('Business Card - ${card.name}');
      final textWithLink = generateTextWithLink(card);

      final body = Uri.encodeComponent(textWithLink);

      final emailUrl =
          'mailto:${recipientEmail ?? ''}?subject=$subject&body=$body';
      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to share sheet
        await shareAsText(card);
      }
    } catch (e) {
      debugPrint('Error sharing via email: $e');
      // Fallback to text share
      await shareAsText(card);
    }
  }

  /// Share via SMS
  Future<void> shareViaSMS(BusinessCard card, {String? phoneNumber}) async {
    try {
      final text = Uri.encodeComponent(generateTextWithLink(card));
      final smsUrl =
          'sms:${phoneNumber ?? ''}${Platform.isIOS ? '&' : '?'}body=$text';
      final uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to share sheet
        await shareAsText(card);
      }
    } catch (e) {
      debugPrint('Error sharing via SMS: $e');
      await shareAsText(card);
    }
  }

  /// Share via WhatsApp
  Future<void> shareViaWhatsApp(
    BusinessCard card, {
    String? phoneNumber,
  }) async {
    try {
      final text = Uri.encodeComponent(generateTextWithLink(card));
      final whatsappUrl = phoneNumber != null && phoneNumber.isNotEmpty
          ? 'https://wa.me/$phoneNumber?text=$text'
          : 'https://wa.me/?text=$text';

      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to share sheet
        await shareAsText(card);
      }
    } catch (e) {
      debugPrint('Error sharing via WhatsApp: $e');
      await shareAsText(card);
    }
  }

  /// Export as vCard file
  Future<String> exportAsVCardFile(BusinessCard card) async {
    try {
      final vcard = generateVCard(card);
      final directory = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(card.name)}.vcf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(vcard);
      return file.path;
    } catch (e) {
      debugPrint('Error exporting vCard file: $e');
      rethrow;
    }
  }

  /// Share vCard file
  Future<void> shareVCardFile(
    BusinessCard card, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final filePath = await exportAsVCardFile(card);
      final xFile = XFile(filePath, mimeType: 'text/vcard');

      await Share.shareXFiles(
        [xFile],
        subject: '${card.name} - Contact Card',
        text: 'Business card for ${card.name}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing vCard file: $e');
      rethrow;
    }
  }

  /// Save and open vCard file (for importing contact)
  Future<void> saveAndOpenVCard(BusinessCard card) async {
    try {
      final filePath = await exportAsVCardFile(card);
      final uri = Uri.file(filePath);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to share sheet
        await shareVCardFile(card);
      }
    } catch (e) {
      debugPrint('Error opening vCard file: $e');
      rethrow;
    }
  }

  /// Generate QR code data
  String generateQRData(BusinessCard card, {bool useVCard = true}) {
    if (useVCard) {
      return generateVCard(card);
    } else {
      // Simple text format
      return generateReadableText(card);
    }
  }

  /// Generate QR code as image
  Future<Uint8List> generateQRCodeImage(
    BusinessCard card, {
    double size = 512,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) async {
    try {
      final qrData = generateQRData(card);

      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        color: foregroundColor,
        emptyColor: backgroundColor,
        gapless: true,
      );

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      qrPainter.paint(canvas, Size(size, size));

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR code image: $e');
      rethrow;
    }
  }

  /// Share QR code as image
  Future<void> shareQRCode(
    BusinessCard card, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final qrImageBytes = await generateQRCodeImage(card);
      final directory = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(card.name)}_qr.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(qrImageBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        subject: '${card.name} - QR Code',
        text: 'Scan this QR code to add ${card.name} to your contacts',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      rethrow;
    }
  }

  /// Copy contact data to clipboard
  Future<void> copyToClipboard(
    BusinessCard card, {
    bool asVCard = false,
  }) async {
    try {
      final text = asVCard ? generateVCard(card) : generateReadableText(card);
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      rethrow;
    }
  }

  /// Sanitize filename
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim()
        .toLowerCase();
  }

  /// Show comprehensive share options bottom sheet
  Future<void> showShareOptions(BuildContext context, BusinessCard card) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareOptionsSheet(card: card),
    );
  }
}

/// Share options bottom sheet widget
class ShareOptionsSheet extends StatelessWidget {
  final BusinessCard card;

  const ShareOptionsSheet({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = Color(card.themeColor);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, cardColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Card',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      card.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Share',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),

          // Share options grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickAction(
                context,
                icon: Icons.share,
                label: 'Share',
                color: Colors.blue,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await SharingService().shareAsText(card);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sharing: $e')),
                      );
                    }
                  }
                },
              ),
              _buildQuickAction(
                context,
                icon: Icons.email,
                label: 'Email',
                color: Colors.orange,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await SharingService().shareViaEmail(card);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening email: $e')),
                      );
                    }
                  }
                },
              ),
              _buildQuickAction(
                context,
                icon: Icons.message,
                label: 'SMS',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await SharingService().shareViaSMS(card);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening SMS: $e')),
                      );
                    }
                  }
                },
              ),
              _buildQuickAction(
                context,
                icon: Icons.chat,
                label: 'WhatsApp',
                color: Colors.teal,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await SharingService().shareViaWhatsApp(card);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening WhatsApp: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Advanced options
          Text(
            'Export Options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),

          _ShareOptionTile(
            icon: Icons.qr_code,
            title: 'QR Code',
            subtitle: 'Generate QR code for scanning',
            color: cardColor,
            onTap: () async {
              Navigator.pop(context);
              try {
                await SharingService().shareQRCode(card);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error generating QR code: $e')),
                  );
                }
              }
            },
          ),

          _ShareOptionTile(
            icon: Icons.contact_page,
            title: 'vCard File',
            subtitle: 'Export as .vcf contact file',
            color: cardColor,
            onTap: () async {
              Navigator.pop(context);
              try {
                await SharingService().shareVCardFile(card);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exporting vCard: $e')),
                  );
                }
              }
            },
          ),

          _ShareOptionTile(
            icon: Icons.copy,
            title: 'Copy to Clipboard',
            subtitle: 'Copy contact information',
            color: cardColor,
            onTap: () async {
              Navigator.pop(context);
              try {
                await SharingService().copyToClipboard(card);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: cardColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error copying: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
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
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.iconTheme.color?.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
