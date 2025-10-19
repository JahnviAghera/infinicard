import 'package:infinicard/models/card_model.dart';

/// Utility class for generating vCard format from business card data
class VCardGenerator {
  /// Generate vCard 3.0 format string from a BusinessCard
  /// This format is widely supported by Google Lens, phones, and contact apps
  static String generateVCard(BusinessCard card) {
    final buffer = StringBuffer();

    // vCard header
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    // Full name (required)
    buffer.writeln('FN:${_escape(card.name)}');

    // Name components (structured)
    final nameParts = card.name.split(' ');
    if (nameParts.length >= 2) {
      buffer.writeln(
        'N:${_escape(nameParts.last)};${_escape(nameParts.first)};;;',
      );
    } else {
      buffer.writeln('N:${_escape(card.name)};;;;');
    }

    // Organization and title
    if (card.company.isNotEmpty) {
      buffer.writeln('ORG:${_escape(card.company)}');
    }
    if (card.title.isNotEmpty) {
      buffer.writeln('TITLE:${_escape(card.title)}');
    }

    // Contact information
    if (card.email.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=INTERNET,WORK:${_escape(card.email)}');
    }
    if (card.phone.isNotEmpty) {
      buffer.writeln('TEL;TYPE=WORK,VOICE:${_escape(card.phone)}');
    }

    // Website
    if (card.website.isNotEmpty) {
      buffer.writeln('URL:${_escape(card.website)}');
    }

    // Social media as URLs
    if (card.linkedIn.isNotEmpty) {
      buffer.writeln('URL;TYPE=LinkedIn:${_escape(card.linkedIn)}');
    }
    if (card.github.isNotEmpty) {
      buffer.writeln('URL;TYPE=GitHub:${_escape(card.github)}');
    }

    // vCard footer
    buffer.writeln('END:VCARD');

    return buffer.toString();
  }

  /// Generate online sharing URL (for API-based sharing)
  /// This creates a deep link or web URL to view the card online
  static String generateOnlineUrl(BusinessCard card) {
    // TODO: Replace with your actual domain/deep link
    // For now, using a placeholder format
    return 'https://infinicard.app/card/${card.id}';
  }

  /// Generate a minimal vCard for QR code (optimized for smaller QR)
  static String generateMinimalVCard(BusinessCard card) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:${_escape(card.name)}${_escape(card.company)}');
    if (card.email.isNotEmpty) {
      buffer.writeln('EMAIL:${_escape(card.email)}');
    }
    if (card.phone.isNotEmpty) {
      buffer.writeln('TEL:${_escape(card.phone)}');
    }
    if (card.company.isNotEmpty) {
      buffer.writeln('ORG:${_escape(card.company)}');
    }
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  /// Escape special characters in vCard fields
  static String _escape(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }
}
