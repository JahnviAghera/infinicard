# Web Link Sharing Guide

## Overview
This feature enables universal link sharing where users can share a web link (https://infinicard.app/c/{cardId}) that:
- **Opens directly in the app** if InfiniCard is installed
- **Redirects to app download page** if app is not installed

## How It Works

### Link Format
All shared links use the format:
```
https://infinicard.app/c/{cardId}
```

Example: `https://infinicard.app/c/abc123xyz`

### User Experience

#### When App is Installed
1. User receives link (via SMS, Email, WhatsApp, etc.)
2. User taps the link
3. **App opens automatically** (App Link/Universal Link)
4. Card import screen loads with card details
5. User can save to contacts with one tap

#### When App is NOT Installed
1. User receives link
2. User taps the link
3. **Web browser opens** to landing page
4. Landing page shows:
   - Card preview (basic info)
   - App download buttons (Play Store/App Store)
   - Option to view card online
5. User installs app
6. After installation, link opens in app

## Implementation Details

### 1. Updated Sharing Methods

All text-based sharing now includes web links:

**Share as Text:**
```dart
📇 John Doe
Software Engineer
🏢 TechCorp Inc.
📧 john@example.com
📱 +1234567890

💳 View my digital business card:
https://infinicard.app/c/abc123xyz

(Opens in Infinicard app if installed, or get the app)
```

**Email Sharing:**
- Subject: "Business Card - {Name}"
- Body: Contains link and contact info

**SMS Sharing:**
- Contains link and basic contact info

**WhatsApp Sharing:**
- Contains link and contact info

### 2. Link Generation

```dart
String generateShareLink(BusinessCard card) {
  return 'https://infinicard.app/c/${card.id}';
}
```

### 3. Deep Link Handling

**Android (AndroidManifest.xml):**
```xml
<!-- App Links for https URLs -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="https" 
        android:host="infinicard.app" 
        android:pathPrefix="/c" />
</intent-filter>
```

**iOS (Info.plist):**
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:infinicard.app</string>
</array>
```

**Flutter (main.dart):**
```dart
void _handleDeepLink(String link) {
  final uri = Uri.parse(link);
  
  // Handle https://infinicard.app/c/ID
  if (uri.scheme == 'https' && uri.host == 'infinicard.app') {
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
      final cardId = uri.pathSegments[1];
      Navigator.of(context).pushNamed('/share/$cardId');
    }
  }
}
```

## Web Landing Page Setup

### Option 1: Static Hosting (Recommended for MVP)

Host a simple HTML page at `https://infinicard.app/c/[cardId]`

**Example Landing Page** (`web/card-landing.html`):

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>InfiniCard - Digital Business Card</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
        }
        .logo {
            font-size: 48px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .card-preview {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 15px;
            padding: 30px;
            color: white;
            margin-bottom: 30px;
            text-align: left;
        }
        .card-name {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .card-title { opacity: 0.9; margin-bottom: 3px; }
        .card-company { opacity: 0.8; font-size: 14px; }
        .download-buttons {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
        }
        .btn {
            flex: 1;
            padding: 15px;
            border-radius: 10px;
            text-decoration: none;
            font-weight: bold;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: transform 0.2s;
        }
        .btn:hover { transform: translateY(-2px); }
        .btn-android {
            background: #3DDC84;
            color: white;
        }
        .btn-ios {
            background: #000;
            color: white;
        }
        .info {
            color: #666;
            font-size: 14px;
            line-height: 1.6;
        }
        .loading {
            display: none;
            color: #667eea;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📇</div>
        <h1>InfiniCard</h1>
        <p class="subtitle">Digital Business Card</p>
        
        <div id="card-preview" class="card-preview">
            <div class="card-name" id="card-name">Loading...</div>
            <div class="card-title" id="card-title"></div>
            <div class="card-company" id="card-company"></div>
        </div>
        
        <div class="download-buttons">
            <a href="https://play.google.com/store/apps/details?id=com.example.infinicard" 
               class="btn btn-android">
                📱 Android
            </a>
            <a href="https://apps.apple.com/app/infinicard/id123456789" 
               class="btn btn-ios">
                🍎 iOS
            </a>
        </div>
        
        <p class="info">
            Get the InfiniCard app to save this contact to your phone with one tap!
        </p>
        
        <p class="loading" id="loading">
            Checking if app is installed...
        </p>
    </div>

    <script>
        // Extract card ID from URL
        const pathParts = window.location.pathname.split('/');
        const cardId = pathParts[pathParts.length - 1];
        
        // Try to open in app first
        setTimeout(() => {
            // Attempt deep link
            const deepLink = `infinicard://share/${cardId}`;
            window.location.href = deepLink;
            
            // If app opens, user will leave the page
            // If not, they'll stay here and see download options
            document.getElementById('loading').style.display = 'block';
            
            // After 2 seconds, assume app isn't installed
            setTimeout(() => {
                document.getElementById('loading').style.display = 'none';
            }, 2000);
        }, 500);
        
        // Fetch card details from API
        fetch(`https://your-api-url.com/api/cards/public/${cardId}`)
            .then(res => res.json())
            .then(data => {
                if (data.success && data.data) {
                    const card = data.data;
                    document.getElementById('card-name').textContent = card.name;
                    document.getElementById('card-title').textContent = card.title;
                    document.getElementById('card-company').textContent = card.company;
                }
            })
            .catch(err => {
                console.error('Error loading card:', err);
            });
    </script>
</body>
</html>
```

### Option 2: Dynamic Server-Side Rendering

Use a backend (Node.js, Python, PHP) to:
1. Fetch card data from API
2. Render HTML with actual card data
3. Generate meta tags for social sharing
4. Handle iOS/Android universal link verification

**Example with Express.js:**

```javascript
app.get('/c/:cardId', async (req, res) => {
  const { cardId } = req.params;
  
  try {
    const card = await fetchCardFromDB(cardId);
    
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>${card.name} - InfiniCard</title>
        <meta property="og:title" content="${card.name}">
        <meta property="og:description" content="${card.title} at ${card.company}">
        <!-- ... more meta tags ... -->
      </head>
      <body>
        <!-- Landing page HTML with actual card data -->
      </body>
      </html>
    `);
  } catch (error) {
    res.status(404).send('Card not found');
  }
});
```

## iOS Universal Links Setup

### 1. Host Association File

Host this file at: `https://infinicard.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.example.infinicard",
        "paths": ["/c/*"]
      }
    ]
  }
}
```

**Important:**
- File must be served with HTTPS
- No `.json` extension
- Content-Type: `application/json`
- Must be accessible without authentication

### 2. Add Associated Domains

In Xcode:
1. Select your target
2. Go to "Signing & Capabilities"
3. Add "Associated Domains" capability
4. Add domain: `applinks:infinicard.app`

## Android App Links Setup

### 1. Host Association File

Host this file at: `https://infinicard.app/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.infinicard",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT_HERE"
    ]
  }
}]
```

**Get SHA256 Fingerprint:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2. Already Configured in AndroidManifest.xml

The `android:autoVerify="true"` attribute enables automatic verification.

## Testing

### Test Web Links

1. **Generate Share Link:**
   - Open app → My Cards → Select card → Share
   - Choose Email/SMS/WhatsApp
   - Verify link format: `https://infinicard.app/c/{cardId}`

2. **Test with App Installed:**
   - Send link to yourself
   - Tap link
   - Should open in app automatically
   - Card import screen should load

3. **Test without App:**
   - Uninstall app
   - Tap same link
   - Should open in browser
   - Landing page should show

4. **Test Universal Link (iOS):**
   ```bash
   # In Safari, paste URL and tap
   https://infinicard.app/c/test-card-id
   ```

5. **Test App Link (Android):**
   ```bash
   adb shell am start -a android.intent.action.VIEW -d "https://infinicard.app/c/test-card-id"
   ```

### Verify Association Files

**iOS:**
```bash
curl https://infinicard.app/.well-known/apple-app-site-association
```

**Android:**
```bash
curl https://infinicard.app/.well-known/assetlinks.json
```

## Deployment Checklist

- [ ] Backend public card API implemented
- [ ] Web hosting configured (infinicard.app)
- [ ] Landing page deployed
- [ ] Association files hosted (iOS/Android)
- [ ] HTTPS enabled
- [ ] Domain verified
- [ ] App store links updated
- [ ] Test on multiple devices
- [ ] Test with/without app installed

## Benefits

1. **Universal Compatibility**: Works on any device with any messaging app
2. **Smart Routing**: Opens in app if installed, web if not
3. **Easy Sharing**: Just share a link, no QR code needed
4. **Professional**: Clean https:// URLs look trustworthy
5. **Tracking**: Web server can track link clicks (analytics)
6. **SEO Friendly**: Cards can be indexed by search engines
7. **Social Sharing**: Rich previews in WhatsApp, FB, Twitter

## Troubleshooting

### Links Open in Browser Instead of App

**iOS:**
- Verify `.well-known/apple-app-site-association` is accessible
- Check associated domains in Xcode
- Ensure HTTPS is working
- Try long-pressing link → "Open in InfiniCard"

**Android:**
- Verify `.well-known/assetlinks.json` is accessible
- Check SHA256 fingerprint matches
- Clear app defaults: Settings → Apps → InfiniCard → Open by default → Clear
- Rebuild app

### Association File Not Working

- Verify Content-Type is `application/json`
- No redirects on the URL
- File accessible without auth
- Valid JSON format
- Correct domain spelling

## Future Enhancements

- [ ] Custom short URLs (infinicard.app/johndoe)
- [ ] Link expiration dates
- [ ] Password-protected links
- [ ] Link analytics dashboard
- [ ] Custom landing page themes
- [ ] Multiple cards per link
- [ ] Contact form on landing page
- [ ] QR code on landing page
