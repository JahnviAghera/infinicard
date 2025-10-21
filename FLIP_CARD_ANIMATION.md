# Flip Card Animation Feature

Beautiful 3D flip card animation for business card previews in the grid view.

## Overview

The flip card animation provides an intuitive and engaging way to interact with business cards in the My Cards screen. Cards can be flipped with a tap gesture to reveal additional information and action buttons on the back.

## Features

### 🎴 Front Side (Default View)
- **Card Preview**
  - Name with bold typography
  - Job title with icon
  - Company name with icon
  - Person avatar icon
  - "Tap to flip" hint at the bottom

### 🔄 Back Side (Flipped View)
- **Contact Information**
  - Email address with icon
  - Phone number with icon
  - Website URL with icon
  
- **Action Buttons**
  - Edit button - Opens edit screen
  - Share button - Opens share options
  - Delete button - Shows delete confirmation (red color)
  
- **"Tap to flip back" hint** at the bottom

## Animation Details

### Technical Specifications
- **Duration:** 600ms
- **Curve:** easeInOut for smooth transition
- **Rotation:** 180° (π radians) Y-axis rotation
- **Perspective:** 0.001 for 3D depth effect
- **Transform:** Matrix4 with rotateY transformation

### User Experience
1. **Tap anywhere on card** - Triggers flip animation
2. **Smooth 3D rotation** - Card rotates around center
3. **Auto-flip on actions** - Automatically flips back before executing action
4. **300ms delay** - Gives visual feedback before action execution

## Implementation

### FlipCardWidget Class
A stateful widget with SingleTickerProviderStateMixin for animation control.

```dart
FlipCardWidget(
  card: businessCard,
  onEdit: () => editCard(),
  onShare: () => shareCard(),
  onDelete: () => deleteCard(),
)
```

### Animation Controller
```dart
AnimationController(
  duration: const Duration(milliseconds: 600),
  vsync: this,
)
```

### Transform Matrix
```dart
final transform = Matrix4.identity()
  ..setEntry(3, 2, 0.001)  // Perspective
  ..rotateY(angle);         // Y-axis rotation
```

## Visual Design

### Front Card Styling
- Gradient background (card theme color)
- Rounded corners (16px radius)
- Shadow with theme color tint
- White text with varying opacity levels
- Icon-text combinations for better readability

### Back Card Styling
- Reverse gradient direction for distinction
- Same shadow and corner styling for consistency
- Compact contact information layout
- Three-column action button layout
- Visual hierarchy with icons and labels

### Color Scheme
- Primary: Card's theme color
- Text: White with opacity variations
- Icons: White70 for subtle appearance
- Delete action: Red300 for warning
- Hint backgrounds: White with 20% opacity

## Grid View Integration

The flip card is automatically integrated into the grid view:

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (context, index) {
    return FlipCardWidget(
      card: filteredCards[index],
      onEdit: () => _editCard(card),
      onShare: () => _shareCard(card),
      onDelete: () => _deleteCard(card),
    );
  },
)
```

## User Flow

### Viewing Contact Details
1. User sees card in grid view (front side)
2. User taps anywhere on the card
3. Card flips with smooth 3D animation (600ms)
4. Back side reveals contact info and actions

### Performing Actions
1. User taps action button (Edit/Share/Delete)
2. Card automatically flips back to front
3. 300ms delay for visual feedback
4. Action is executed (navigate to screen or show dialog)

### Returning to Front
1. User taps anywhere on back of card
2. Card flips back to front side
3. Returns to default preview state

## Performance Considerations

- **Efficient Animation:** Uses AnimationController for hardware-accelerated transforms
- **Single Ticker:** One ticker per card for optimal performance
- **Proper Disposal:** Controller disposed in dispose() method
- **Conditional Rendering:** Only shows relevant information (checks if fields are empty)
- **Optimized Transforms:** Matrix4 transforms use GPU acceleration

## Accessibility

- Clear visual hints ("Tap to flip")
- Icon + text labels for all actions
- Color-coded delete action (red) for safety
- Sufficient touch targets (minimum 44x44)
- High contrast white text on gradient backgrounds

## Future Enhancements

- [ ] Haptic feedback on flip
- [ ] Sound effects option
- [ ] Double-tap to execute default action
- [ ] Long-press for quick menu
- [ ] Customizable flip direction (vertical/horizontal)
- [ ] Flip animation speed settings
- [ ] Auto-flip back after timeout
- [ ] Gesture-based flip (swipe left/right)

## Browser/Platform Compatibility

| Platform | Support | Notes |
|----------|---------|-------|
| Android | ✅ Full | Native 3D transforms |
| iOS | ✅ Full | Native 3D transforms |
| Web | ✅ Full | CSS3 transforms |
| Desktop | ✅ Full | OpenGL transforms |

## Customization

### Animation Duration
```dart
AnimationController(
  duration: const Duration(milliseconds: 800), // Slower flip
  vsync: this,
)
```

### Curve Type
```dart
CurvedAnimation(
  parent: _controller,
  curve: Curves.elasticOut, // Bouncy effect
)
```

### Perspective Depth
```dart
..setEntry(3, 2, 0.002) // More pronounced 3D effect
```

## Testing

### Manual Testing Checklist
- [ ] Tap card to flip - animation smooth?
- [ ] Tap back to return - animation smooth?
- [ ] Edit button - flips back then navigates?
- [ ] Share button - flips back then shares?
- [ ] Delete button - flips back then confirms?
- [ ] Multiple rapid taps - no glitches?
- [ ] Cards with missing info - layout correct?
- [ ] Different theme colors - shadows correct?

### Performance Testing
- [ ] Grid with 50+ cards - smooth scrolling?
- [ ] Multiple simultaneous flips - no lag?
- [ ] Memory usage - no leaks?
- [ ] Battery impact - acceptable?

---

**Version:** 1.0.0  
**Last Updated:** October 19, 2025  
**Author:** Infinicard Development Team
