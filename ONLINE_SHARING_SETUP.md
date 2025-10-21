# Online Sharing Configuration

## Overview
This feature enables app-to-app sharing where scanning a QR code automatically opens the card in the InfiniCard app and allows saving it to contacts.

## Features Implemented

### 1. Public Card API Endpoint
- **Method**: `getPublicCard(String id)`
- **Endpoint**: `GET /api/cards/public/:id`
- **Authentication**: None required (public access)
- **Purpose**: Allows anyone with a card ID to view the card details

### 2. Card Import Screen
- **File**: `lib/screens/card_import_screen.dart`
- Fetches card from public API
- Displays card preview with gradient theme
- **Save to Contacts** button - exports as vCard and opens in contacts app
- Quick actions: Call, Email, Website, Copy
- Error handling and retry functionality

### 3. Sharing Screen Enhancements
- **File**: `lib/screens/sharing_screen.dart`
- Toggle between two QR code types:
  - **Online Share QR**: Contains deep link `infinicard://share/{cardId}`
  - **vCard QR**: Contains traditional vCard data
- Switch button to toggle between modes
- Visual indicators showing QR type
- Instructions: "Scan with InfiniCard" vs "Scan with any device"

### 4. Deep Link Routing
- **File**: `lib/main.dart`
- Added `onGenerateRoute` handler
- Handles URLs like `/share/{cardId}`
- Automatically routes to `CardImportScreen`

## Android Configuration

To enable deep linking on Android, update your `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Existing intent filters -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Deep link intent filter for infinicard:// URLs -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="infinicard" android:host="share" />
    </intent-filter>
    
    <!-- App Links for https URLs (optional but recommended) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="infinicard.app" android:pathPrefix="/share" />
    </intent-filter>
</activity>
```

**Location**: `android/app/src/main/AndroidManifest.xml`

## iOS Configuration

Update your `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.infinicard.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>infinicard</string>
        </array>
    </dict>
</array>

<!-- Universal Links (optional) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:infinicard.app</string>
</array>
```

**Location**: `ios/Runner/Info.plist`

## Backend Requirements

### Public Card Endpoint
Your backend needs to implement this endpoint:

```javascript
// Express.js example
router.get('/cards/public/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Fetch card from database
    const card = await Card.findById(id);
    
    if (!card) {
      return res.status(404).json({
        success: false,
        message: 'Card not found'
      });
    }
    
    // Return card data (excluding sensitive info)
    res.json({
      success: true,
      data: {
        id: card.id,
        name: card.name,
        title: card.title,
        company: card.company,
        email: card.email,
        phone: card.phone,
        website: card.website,
        linkedIn: card.linkedIn,
        github: card.github,
        themeColor: card.themeColor,
        createdAt: card.createdAt,
        updatedAt: card.updatedAt
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});
```

## User Flow

### Sharing a Card
1. User opens their card in the app
2. Taps **Share** button
3. QR code is displayed (Online Share mode by default)
4. Other person scans QR with InfiniCard app

### Receiving a Card
1. User scans QR code with InfiniCard app (or any QR scanner)
2. Deep link `infinicard://share/{cardId}` opens the app
3. **Card Import Screen** loads automatically
4. Card details fetched from public API
5. User sees card preview with all contact info
6. User taps **Save to Contacts**
7. vCard file is generated and opened
8. Native contacts app opens with pre-filled data
9. User confirms to save contact

## QR Code Types

### Online Share QR (Default)
- **Data**: `infinicard://share/{cardId}`
- **Use Case**: App-to-app sharing
- **Benefits**:
  - Always shows latest card data (fetched from server)
  - Works even if card is updated after sharing
  - Requires InfiniCard app to scan
  - Analytics possible (track shares)

### vCard QR
- **Data**: Complete vCard 3.0 format
- **Use Case**: Universal sharing
- **Benefits**:
  - Works with any QR scanner
  - No app required
  - Works offline
  - Standard format

## Features

### Card Import Screen
- ✅ Loading state while fetching card
- ✅ Error handling with retry
- ✅ Card preview with gradient theme
- ✅ **Save to Contacts** button (green, prominent)
- ✅ Quick actions: Call, Email, Website, Copy
- ✅ Responsive design
- ✅ Dark theme matching app design

### Auto-Save Flow
1. Generate vCard file
2. Save to temporary directory
3. Open file with native intent
4. System contacts app handles import
5. User confirms save

## Testing

### Test Online Share
1. Open app on Device A
2. Go to My Cards → Select a card → Share
3. Ensure "Online Share QR" is selected
4. Scan QR with Device B (InfiniCard app)
5. Verify card loads automatically
6. Test "Save to Contacts"

### Test Deep Links
```bash
# Android ADB test
adb shell am start -W -a android.intent.action.VIEW -d "infinicard://share/CARD_ID_HERE" com.your.package

# iOS test
xcrun simctl openurl booted "infinicard://share/CARD_ID_HERE"
```

## Security Considerations

1. **Rate Limiting**: Backend should rate-limit the public card endpoint
2. **Data Sanitization**: Only expose necessary fields (no user IDs, etc.)
3. **Privacy**: Users should be able to disable public sharing
4. **Validation**: Validate card IDs to prevent injection attacks

## Future Enhancements

- [ ] Analytics dashboard (track share counts)
- [ ] Privacy settings (enable/disable public sharing)
- [ ] Custom short URLs (infinicard.app/c/ABC123)
- [ ] Share history tracking
- [ ] Social media integration
- [ ] NFC sharing support
- [ ] Batch import (scan multiple cards)
- [ ] Contact deduplication
- [ ] Custom QR code designs
- [ ] Expiring share links

## Troubleshooting

### Deep Links Not Working
1. Verify AndroidManifest.xml/Info.plist configuration
2. Rebuild app after manifest changes
3. Test with ADB/xcrun commands
4. Check app is set as default for the scheme

### Cards Not Loading
1. Check API endpoint is accessible
2. Verify card ID format
3. Check network connectivity
4. Review backend logs

### Save to Contacts Fails
1. Check file permissions
2. Verify vCard format is valid
3. Check if contacts permission is granted
4. Try manual vCard export
