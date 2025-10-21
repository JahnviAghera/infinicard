# Card Reordering and Sharing Screen Features

## Overview
This document describes the card reordering functionality and the new sharing screen that replaces the card preview screen.

## Card Reordering

### Features Implemented

1. **Reorder Mode Toggle**
   - Added reorder button (swap_vert icon) in the app bar
   - Button turns green when reorder mode is active
   - Click the checkmark to exit reorder mode

2. **Custom Order Persistence**
   - Card order is saved to `SharedPreferences` under key `cards_custom_order`
   - Order is automatically loaded on app start
   - Order persists across app sessions

3. **Reorder Controls**
   - When in reorder mode, the active card shows left/right arrow buttons
   - Left arrow moves card one position to the left
   - Right arrow moves card one position to the right
   - Semi-transparent overlay shows when in reorder mode

4. **Sort Menu Enhancement**
   - Added "Custom Order" option to the sort menu
   - Sort automatically switches to "Custom" when cards are reordered
   - Other sort options (Date, Name, Company) still available

### How to Use

1. Tap the **reorder button** (swap icon) in the top-right corner
2. Reorder mode activates - flip animation is disabled
3. Use the **left/right arrow buttons** on the current card to move it
4. The page will automatically transition as you reorder
5. Tap the **checkmark** to exit reorder mode
6. Your order is automatically saved!

### Technical Details

- **State Management**: Uses `_customOrder` list to track card IDs in order
- **Persistence**: `SharedPreferences` stores order as JSON array of IDs
- **Methods**:
  - `_loadCustomOrder()`: Loads saved order on startup
  - `_saveCustomOrder()`: Saves order after each reorder action
  - `_reorderCard(oldIndex, newIndex)`: Handles reordering logic
  - `_sortCards()`: Applies custom order when sort mode is "Custom"

## New Sharing Screen

### Features Implemented

1. **Card/QR Toggle View**
   - Tap the card/QR to switch between views
   - Smooth animated transition
   - Card shows with gradient based on theme color
   - QR code displays with contact name and company

2. **Quick Share Actions**
   - **Email**: Opens email client with vCard attached
   - **SMS**: Opens SMS with contact details
   - **WhatsApp**: Shares via WhatsApp
   - **Copy**: Copies contact details to clipboard with confirmation

3. **Export Options**
   - **Export as vCard**: Save as .vcf file for importing to contacts
   - **Export QR Code**: Save QR code as PNG image
   - **Share as Text**: Share contact details as plain text

4. **Professional UI**
   - Dark theme matching app design
   - Color-coded action buttons
   - Clear section headers
   - Smooth animations

### Screen Sections

#### Header
- Back button for navigation
- Title: "Share Contact"
- Three-dot menu for additional options

#### Card Preview / QR Code
- Toggle between card and QR views by tapping
- Card shows all contact information with gradient background
- QR code is high-quality with error correction

#### Quick Share (Chips)
- Email (Red) - `_sharingService.shareViaEmail()`
- SMS (Green) - `_sharingService.shareViaSMS()`
- WhatsApp (WhatsApp Green) - `_sharingService.shareViaWhatsApp()`
- Copy (Blue) - `_sharingService.copyToClipboard()`

#### Export Options (Tiles)
- vCard Export - Full contact file
- QR Code Export - PNG image
- Text Export - Formatted text

### Navigation Updates

Replaced `CardPreviewScreen` with `SharingScreen` in:
- `my_cards_screen.dart` - When tapping share on a card
- `create_edit_card_screen.dart` - When previewing a new/edited card

### Technical Details

**File**: `lib/screens/sharing_screen.dart`

**Key Components**:
- `_showQR`: Boolean state for card/QR toggle
- `_buildCardPreview()`: Renders business card with gradient
- `_buildQRView()`: Renders QR code with vCard data
- `_buildQuickActions()`: Creates action chip buttons
- `_buildExportOptions()`: Creates export option tiles
- `AnimatedSwitcher`: Smooth transitions between views

**Integration**:
- Uses `SharingService` singleton for all sharing operations
- Follows Material Design 3 patterns
- Consistent with app's dark theme

## User Benefits

1. **Organize Cards Your Way**: Arrange cards in the order that makes sense to you
2. **Persistent Order**: Your arrangement is saved automatically
3. **Easy Sharing**: Multiple ways to share contacts
4. **Professional QR Codes**: Quick sharing with QR code scanning
5. **Export Options**: Save contacts in multiple formats
6. **Intuitive UI**: Clear visual feedback and smooth animations

## Future Enhancements

Potential improvements:
- Drag-and-drop reordering (instead of arrow buttons)
- Batch reordering
- Multiple custom sort profiles
- Share analytics
- Customizable QR code designs
- Social media sharing integrations
