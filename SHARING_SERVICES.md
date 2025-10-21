# Infinicard Sharing Services

Comprehensive sharing functionality for business cards with multiple export and sharing options.

## Features

### 📤 Share Methods

#### 1. **Text Sharing**
Share card information as formatted text via system share sheet.
```dart
await SharingService().shareAsText(card);
```

#### 2. **Email Sharing**
Opens email client with pre-filled contact data and vCard format.
```dart
await SharingService().shareViaEmail(card, recipientEmail: 'contact@example.com');
```

#### 3. **SMS Sharing**
Opens SMS app with formatted contact information.
```dart
await SharingService().shareViaSMS(card, phoneNumber: '+1234567890');
```

#### 4. **WhatsApp Sharing**
Opens WhatsApp with formatted message.
```dart
await SharingService().shareViaWhatsApp(card, phoneNumber: '+1234567890');
```

### 📋 Export Options

#### 1. **vCard Export**
Export contact as standard .vcf file compatible with all contact apps.
```dart
// Export file
final filePath = await SharingService().exportAsVCardFile(card);

// Share vCard file
await SharingService().shareVCardFile(card);
```

#### 2. **QR Code Generation**
Generate QR codes containing vCard data for easy scanning.
```dart
// Generate QR code image
final qrImageBytes = await SharingService().generateQRCodeImage(
  card,
  size: 512,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
);

// Share QR code
await SharingService().shareQRCode(card);
```

#### 3. **Clipboard Copy**
Copy contact information to clipboard.
```dart
// Copy as readable text
await SharingService().copyToClipboard(card, asVCard: false);

// Copy as vCard format
await SharingService().copyToClipboard(card, asVCard: true);
```

### 🎨 Share Options UI

Show comprehensive share options bottom sheet with all sharing methods:
```dart
await SharingService().showShareOptions(context, card);
```

## vCard Format

The service generates standard vCard 3.0 format files that include:
- ✅ Full name (FN and N fields)
- ✅ Organization (ORG)
- ✅ Job title (TITLE)
- ✅ Email address (EMAIL)
- ✅ Phone number (TEL)
- ✅ Website (URL)
- ✅ Social links (LinkedIn, GitHub)
- ✅ Metadata (REV timestamp)

### vCard Example
```vcard
BEGIN:VCARD
VERSION:3.0
FN:John Doe
N:Doe;John;;;
ORG:TechCorp Solutions
TITLE:Senior Software Engineer
EMAIL;TYPE=INTERNET:john@techcorp.com
TEL;TYPE=CELL:+1-555-0123
URL:https://techcorp.com
URL;TYPE=LinkedIn:https://linkedin.com/in/johndoe
URL;TYPE=GitHub:https://github.com/johndoe
NOTE:Shared via Infinicard
REV:2025-10-19T10:30:00.000Z
END:VCARD
```

## QR Code Format

QR codes contain vCard data with:
- Error correction level: High (H) - 30% recovery
- Version: Auto-detect based on data size
- Format: PNG image
- Default size: 512x512 pixels
- Customizable colors

## Usage Examples

### Complete Sharing Flow

```dart
import 'package:infinicard/services/sharing_service.dart';
import 'package:infinicard/models/card_model.dart';

// Create or get business card
final card = BusinessCard(...);

// Show all sharing options
await SharingService().showShareOptions(context, card);

// Or use specific sharing method
await SharingService().shareViaEmail(card);
await SharingService().shareQRCode(card);
await SharingService().shareVCardFile(card);
```

### Custom QR Code

```dart
final qrImage = await SharingService().generateQRCodeImage(
  card,
  size: 1024, // Larger size for printing
  backgroundColor: Colors.white,
  foregroundColor: Color(card.themeColor), // Use card's theme color
);

// Save or display the image
```

### Copy to Clipboard with Feedback

```dart
try {
  await SharingService().copyToClipboard(card);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Copied to clipboard!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## Platform Compatibility

| Feature | iOS | Android | Web | Desktop |
|---------|-----|---------|-----|---------|
| Text Share | ✅ | ✅ | ✅ | ✅ |
| Email | ✅ | ✅ | ✅ | ✅ |
| SMS | ✅ | ✅ | ❌ | ❌ |
| WhatsApp | ✅ | ✅ | ✅ | ✅ |
| vCard Export | ✅ | ✅ | ✅ | ✅ |
| QR Code | ✅ | ✅ | ✅ | ✅ |
| Clipboard | ✅ | ✅ | ✅ | ✅ |

## Dependencies

```yaml
dependencies:
  share_plus: ^12.0.0       # System share sheet
  url_launcher: ^6.2.1      # Open URLs and apps
  qr_flutter: ^4.0.0        # QR code generation
  path_provider: ^2.1.4     # File system access
```

## Error Handling

All sharing methods include proper error handling with fallbacks:

```dart
try {
  await SharingService().shareViaWhatsApp(card);
} catch (e) {
  // Automatically falls back to system share sheet
  // if WhatsApp is not installed
}
```

## Customization

### Share Position (iPad/Tablet)

```dart
final box = context.findRenderObject() as RenderBox?;
final sharePositionOrigin = box!.localToGlobal(Offset.zero) & box.size;

await SharingService().shareAsText(
  card,
  sharePositionOrigin: sharePositionOrigin,
);
```

### Custom QR Code Data

```dart
// Use vCard format (default)
final qrData = SharingService().generateQRData(card, useVCard: true);

// Use readable text format
final qrData = SharingService().generateQRData(card, useVCard: false);
```

## UI Components

### ShareOptionsSheet
Full-featured bottom sheet with all sharing options:
- Quick share buttons (Share, Email, SMS, WhatsApp)
- Export options (QR Code, vCard File, Clipboard)
- Beautiful Material Design 3 UI
- Themed with card colors
- Error handling with snackbar feedback

### CardPreviewScreen
Enhanced preview screen with:
- Toggle between card view and QR code view
- Tabbed interface (Preview / Details)
- Quick action buttons
- Floating action button for main share
- Integrated sharing service

## Best Practices

1. **Always check platform compatibility** before using platform-specific features
2. **Provide fallbacks** for sharing methods that may not be available
3. **Show user feedback** (snackbars) after actions
4. **Handle errors gracefully** with try-catch blocks
5. **Test on multiple platforms** to ensure compatibility

## Future Enhancements

- [ ] NFC sharing support
- [ ] AirDrop integration (iOS)
- [ ] Nearby Share (Android)
- [ ] Custom templates for different formats
- [ ] Batch sharing for multiple cards
- [ ] QR code scanning to import cards
- [ ] Social media direct sharing (LinkedIn, Twitter)
- [ ] Analytics for share tracking

## Support

For issues or feature requests, please contact the development team or open an issue in the repository.

---

**Version:** 1.0.0  
**Last Updated:** October 19, 2025
