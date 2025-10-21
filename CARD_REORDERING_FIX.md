# Card Reordering Bug Fix

## Issue
Card reordering wasn't being saved/persisted properly. When the app was restarted or cards were refreshed from the API, the custom order was lost.

## Root Causes Identified

### 1. Timing Issue
The `_loadCustomOrder()` function was called asynchronously in `initState()`, but `_loadCachedCards()` and `_fetchCards()` were also called immediately without waiting for the custom order to load first.

```dart
// OLD CODE - Race condition
void initState() {
  super.initState();
  _loadCustomOrder();  // Async, doesn't wait
  _loadCachedCards();  // Runs immediately
  _fetchCards();       // Runs immediately
}
```

### 2. Missing Order Application
When cards were loaded from cache or fetched from API, the custom order wasn't being applied:

```dart
// OLD CODE - Order not applied
setState(() {
  _cards = cardsData.map((json) => BusinessCard.fromJson(json)).toList();
  _filteredCards = _cards;  // Missing _sortCards()
});
```

### 3. Sort Mode Not Persisted
When custom order was loaded, the sort mode wasn't automatically set to "Custom", so the order wouldn't be applied even if it existed.

## Fixes Applied

### 1. Sequential Initialization
Created an `_initialize()` method that loads data in the correct order:

```dart
@override
void initState() {
  super.initState();
  _initialize();  // Now calls everything in sequence
  _searchController.addListener(_filterCards);
  _pageController.addListener(...);
}

Future<void> _initialize() async {
  await _loadCustomOrder();     // 1. Load saved order first
  await _loadCachedCards();     // 2. Load cached cards
  await _fetchCards();          // 3. Fetch from API
}
```

### 2. Apply Order After Loading
Added `_sortCards()` call after loading cards:

```dart
setState(() {
  _cards = cardsData.map((json) => BusinessCard.fromJson(json)).toList();
  _filteredCards = _cards;
  _sortCards();  // ✅ Now applies custom order if exists
});
```

This applies to both:
- Loading from cache (`_loadCachedCards()`)
- Fetching from API (`_fetchCards()`)

### 3. Auto-Set Sort Mode
When custom order is loaded, automatically set the sort mode to "Custom":

```dart
Future<void> _loadCustomOrder() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final orderData = prefs.getString('cards_custom_order');
    if (orderData != null) {
      final List<dynamic> orderList = jsonDecode(orderData);
      setState(() {
        _customOrder = orderList.map((e) => e.toString()).toList();
        if (_customOrder.isNotEmpty) {
          _sortBy = 'Custom';  // ✅ Auto-set to Custom
        }
      });
      print('Custom order loaded: ${_customOrder.length} cards');
    }
  } catch (e) {
    print('Error loading custom order: $e');
  }
}
```

### 4. Added Debug Logging
Added debug prints to track saving and loading:

```dart
// In _saveCustomOrder()
print('Custom order saved: ${_customOrder.length} cards');

// In _loadCustomOrder()
print('Custom order loaded: ${_customOrder.length} cards');
```

## How It Works Now

### Reordering Flow
1. User enters reorder mode
2. User taps left/right arrows to move cards
3. `_reorderCard()` is called:
   - Updates `_filteredCards` array
   - Creates new `_customOrder` from card IDs
   - Sets `_sortBy = 'Custom'`
   - Calls `_saveCustomOrder()` ✅
4. Order is saved to SharedPreferences

### Loading Flow
1. App starts
2. `_initialize()` is called
3. **Step 1**: `_loadCustomOrder()` loads saved order
   - Reads from SharedPreferences
   - Sets `_customOrder` array
   - Sets `_sortBy = 'Custom'` if order exists ✅
4. **Step 2**: `_loadCachedCards()` loads cached cards
   - Reads cards from cache
   - Calls `_sortCards()` to apply custom order ✅
5. **Step 3**: `_fetchCards()` fetches from API
   - Gets latest cards from server
   - Calls `_sortCards()` to apply custom order ✅

### Sorting Logic
The `_sortCards()` method now properly handles custom order:

```dart
void _sortCards() {
  if (_sortBy == 'Custom' && _customOrder.isNotEmpty) {
    // Apply custom order
    _filteredCards.sort((a, b) {
      final aIndex = _customOrder.indexOf(a.id);
      final bIndex = _customOrder.indexOf(b.id);
      // Cards not in custom order go to the end
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
  } else if (_sortBy == 'Date') {
    _filteredCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  } else if (_sortBy == 'Name') {
    _filteredCards.sort((a, b) => a.name.compareTo(b.name));
  } else if (_sortBy == 'Company') {
    _filteredCards.sort((a, b) => a.company.compareTo(b.company));
  }
}
```

## Testing

### Verify Fix
1. **Reorder cards**:
   - Tap reorder button (swap icon)
   - Move cards using arrows
   - Tap checkmark to exit
   - Check console: "Custom order saved: X cards"

2. **Restart app**:
   - Close app completely
   - Reopen app
   - Check console: "Custom order loaded: X cards"
   - Cards should be in custom order ✅

3. **Refresh from API**:
   - Tap refresh button
   - Cards should maintain custom order ✅

4. **Switch sort modes**:
   - Change to "Sort by Name"
   - Cards sort alphabetically
   - Change back to "Custom Order"
   - Cards return to custom order ✅

### Debug Console Output
You should see:
```
Custom order loaded: 5 cards
Custom order saved: 5 cards
```

## Edge Cases Handled

1. **New Cards Added**: New cards appear at the end of custom order
2. **Cards Deleted**: Custom order automatically updates
3. **No Custom Order**: Falls back to default "Date" sort
4. **Empty Custom Order**: Gracefully handles empty arrays
5. **Sort Mode Change**: Custom order preserved even when using other sorts

## Files Modified

- `lib/screens/my_cards_screen.dart`
  - Added `_initialize()` method
  - Updated `initState()`
  - Updated `_loadCustomOrder()` to auto-set sort mode
  - Updated `_saveCustomOrder()` with debug logging
  - Updated `_loadCachedCards()` to apply order
  - Updated `_fetchCards()` to apply order

## Summary

The card reordering feature now works correctly with:
- ✅ Proper initialization order
- ✅ Persistent storage in SharedPreferences
- ✅ Automatic application after loading cards
- ✅ Survives app restarts
- ✅ Survives API refreshes
- ✅ Debug logging for troubleshooting
- ✅ Proper sort mode management
