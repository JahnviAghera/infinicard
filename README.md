# 💳 Infinicard

**The Complete Digital Business Card & Networking Platform**

A comprehensive Flutter application for creating, sharing, and managing digital business cards while promoting sustainability and professional networking.

---

## 🌟 Features Overview

### 💳 Card Management
- **My Cards**: Manage multiple digital business cards
- **Create/Edit**: Full-featured card designer with 8 color themes
- **Preview/Share**: Animated flip cards with QR codes, share as PNG/PDF

### 👥 Networking & Contacts
- **Contacts**: Save and organize scanned contacts with notes & reminders
- **Discover**: AI-powered professional recommendations with location/field filters
- **Activity Log**: Track all networking activities with visual timeline

### 📷 Smart Features
- **OCR Scanner**: Capture business cards with camera and auto-extract info
- **NFC Support**: Tap-to-share capabilities (hardware dependent)
- **Integrations**: Sync with Google Contacts, Outlook; Import/Export CSV

### 🏆 Gamification
- **Rewards**: Earn points for sharing, connections, profile completion
- **Badges**: Unlock achievements (Networker, Early Bird, Card Master, etc.)
- **Leaderboard**: Compete with community on networking activities

### 🌱 Sustainability
- **Impact Dashboard**: Track paper saved, trees protected, CO2 reduced
- **Share Achievements**: Promote eco-friendly networking
- **Real-time Calculations**: See environmental impact grow

### 🏢 Enterprise
- **Team Management**: Add members, assign roles (Admin/Member)
- **Analytics**: Track cards created, active users, growth metrics
- **Admin Panel**: Comprehensive team overview and controls

### ⚙️ Settings & Security
- **Privacy Controls**: Public/Connections/Private visibility
- **2FA Support**: Two-factor authentication
- **Cloud Backup**: Firebase, AWS, or Azure integration
- **Dark Mode**: Built-in dark theme (customizable)

### 📱 Additional Screens
- **Notifications**: Real-time updates on connections, rewards, system alerts
- **Help & Support**: 6 FAQs, contact form, live chat access
- **About & Legal**: App info, terms of service, privacy policy

---

## 🎨 Design System

### Color Palette
```dart
Background:  0xFF0D0C0F  // Dark base
Cards:       0xFF1C1A1B  // Dark gray
Primary:     0xFF1E88E5  // Blue accent
Success:     0xFF4CAF50  // Green
Warning:     0xFFFFA726  // Orange
Error:       0xFFF44336  // Red
```

### UI Framework
- **Material Design 3** with `useMaterial3: true`
- **Responsive layouts** for all screen sizes
- **Custom animations** (flip cards, transitions)
- **Dark theme** optimized for OLED displays

---

## 📂 Project Structure

```
lib/
├── main.dart                          # Entry point, routing, bottom nav
├── theme.dart                         # Design system & color schemes
├── models/
│   ├── card_model.dart               # BusinessCard data model
│   └── contact_model.dart            # Contact data model
├── services/
│   └── sustainability_service.dart   # Environmental impact calculations
└── screens/
    ├── create_edit_card_screen.dart  # Card designer with live preview
    ├── card_preview_screen.dart      # Animated card viewer & sharing
    ├── my_cards_screen.dart          # Card collection management
    ├── contacts_list_screen.dart     # Saved contacts with filters
    ├── contact_detail_screen.dart    # Full contact info & actions
    ├── discover_screen.dart          # Professional networking hub
    ├── rewards_screen.dart           # Points, badges, leaderboard
    ├── sustainability_screen.dart    # Environmental impact dashboard
    ├── integrations_screen.dart      # Sync & import/export
    ├── enterprise_screen.dart        # Team management & analytics
    ├── settings_screen.dart          # App configuration
    ├── help_support_screen.dart      # FAQs & contact form
    ├── about_screen.dart             # App info & legal
    ├── notifications_screen.dart     # Notification center
    ├── activity_log_screen.dart      # Action history timeline
    └── scan_card_screen.dart         # OCR business card scanner
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Physical device recommended for camera features

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd infinicard

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

### Required Permissions
- **Camera**: For OCR card scanning
- **Storage**: For saving/loading cards
- **Internet**: For cloud sync and integrations

---

## 📱 Navigation Guide

### Bottom Navigation (3 tabs)
1. **Home** - Dashboard with quick access grid
2. **Scan** - OCR camera scanner
3. **Contacts** - Contact list

### Drawer Menu (Organized by category)
**Cards**
- My Cards, Create Card

**Network**
- Contacts, Discover, Activity Log

**Features**
- Rewards, Sustainability, Integrations, Enterprise

**Account**
- Settings, Help & Support, About

### Quick Access (Home Screen)
- My Cards, Discover, Rewards, Sustainability

---

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^latest              # OCR scanning
  url_launcher: ^latest        # Phone/email/SMS actions
  share_plus: ^latest          # Social sharing
  permission_handler: ^latest  # Runtime permissions
  # Add other dependencies from pubspec.yaml
```

---

## 📖 Documentation

For detailed feature documentation, see **[FEATURES.md](FEATURES.md)**

### Key Documents
- **FEATURES.md**: Complete screen-by-screen feature list
- **pubspec.yaml**: Dependencies and configuration
- **analysis_options.yaml**: Linting rules

---

## 🎯 Usage Examples

### Create Your First Card
1. Tap **Quick Access > My Cards**
2. Press the **+ FAB** button
3. Fill in your details
4. Choose a theme color
5. Preview and save

### Scan a Business Card
1. Tap **Scan** in bottom navigation
2. Align card in frame
3. Press capture button
4. Edit extracted data
5. Save to contacts

### Track Sustainability
1. Navigate to **Sustainability** (Home or Drawer)
2. View your environmental impact
3. Share achievements on social media

### Connect with Professionals
1. Open **Discover** screen
2. Filter by location and field
3. Browse recommendations
4. Tap **Connect** on profiles

---

## 🤝 Contributing

This is a private project. For collaboration inquiries, contact the maintainer.

---

## 📄 License

See LICENSE file for details.

---

## 📞 Support

- **In-App Help**: Settings > Help & Support
- **Email**: Available in Help screen
- **Version**: 1.0.0

---

## 🙏 Acknowledgments

- Built with **Flutter** & **Material Design 3**
- Uses **camera** package for OCR
- Inspired by sustainable networking principles

---

**Last Updated**: 2024  
**Platform**: Android & iOS  
**Framework**: Flutter 3.x
