import 'package:flutter/material.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/screens/create_edit_card_screen.dart';
import 'package:infinicard/screens/sharing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final Map<String, GlobalKey<_FlipCardWidgetState>> _flipCardKeys = {};
  List<BusinessCard> _cards = [];
  List<BusinessCard> _filteredCards = [];
  List<String> _customOrder = []; // Store custom card order by ID
  bool _isGridView = false;
  String _sortBy = 'Date';
  int _currentPage = 0;
  bool _isReorderMode = false; // Toggle reorder mode

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_filterCards);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        // Reset flip state on all cards when page changes
        for (var key in _flipCardKeys.values) {
          key.currentState?.resetFlip();
        }
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCards);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Initialize data with proper order
  Future<void> _initialize() async {
    await _loadCustomOrder(); // Load saved card order first
    await _loadCachedCards(); // Load offline cache
    await _fetchCards(); // Then fetch from API (if available)
  }

  // Load custom card order from SharedPreferences
  Future<void> _loadCustomOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderData = prefs.getString('cards_custom_order');
      if (orderData != null) {
        final List<dynamic> orderList = jsonDecode(orderData);
        setState(() {
          _customOrder = orderList.map((e) => e.toString()).toList();
          if (_customOrder.isNotEmpty) {
            _sortBy = 'Custom'; // Automatically set to Custom if order exists
          }
        });
        print('Custom order loaded: ${_customOrder.length} cards');
      }
    } catch (e) {
      print('Error loading custom order: $e');
    }
  }

  // Save custom card order to SharedPreferences
  Future<void> _saveCustomOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cards_custom_order', jsonEncode(_customOrder));
      print('Custom order saved: ${_customOrder.length} cards');
    } catch (e) {
      print('Error saving custom order: $e');
    }
  }

  // Load cards from local cache for offline support
  Future<void> _loadCachedCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_cards');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        setState(() {
          _cards = jsonList
              .map(
                (json) => BusinessCard.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          _filteredCards = List.from(_cards);
          _sortCards(); // Apply custom order if exists
        });
      }
    } catch (e) {
      print('Error loading cached cards: $e');
    }
  }

  // Save cards to local cache
  Future<void> _saveCardsToCache(List<Map<String, dynamic>> cardsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_cards', jsonEncode(cardsData));
    } catch (e) {
      print('Error saving cards to cache: $e');
    }
  }

  // Basic fetch implementation (placeholder - extend to call ApiService if available)
  Future<void> _fetchCards() async {
    try {
      final api = ApiService();
      final result = await api.getCards();

      if (result['success'] == true && result['data'] is List) {
        final List<dynamic> dataList = result['data'];
        setState(() {
          _cards = dataList
              .map((m) => BusinessCard.fromJson(m as Map<String, dynamic>))
              .toList();
          _filteredCards = List.from(_cards);
        });

        // Cache fetched cards
        try {
          final cardsData = _cards.map((c) => c.toJson()).toList();
          await _saveCardsToCache(cardsData.cast<Map<String, dynamic>>());
        } catch (_) {}
      } else {
        // If API returned no data or failed, ensure sorting/filtering still applied
        print('No cards returned from API or failed: ${result['message']}');
      }
    } catch (e) {
      print('Error fetching cards from API: $e');
    } finally {
      _sortCards();
    }
  }

  // Filter cards by search query
  void _filterCards() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCards = List.from(_cards);
      } else {
        _filteredCards = _cards.where((c) {
          final name = c.name.toLowerCase();
          final title = c.title.toLowerCase();
          final company = c.company.toLowerCase();
          return name.contains(query) ||
              title.contains(query) ||
              company.contains(query);
        }).toList();
      }
      _currentPage = 0;
      _pageController.jumpToPage(0);
    });
  }

  // Sort cards according to _sortBy and _customOrder
  void _sortCards() {
    setState(() {
      if (_sortBy == 'Custom' && _customOrder.isNotEmpty) {
        final map = {for (var c in _cards) c.id: c};
        final ordered = <BusinessCard>[];
        for (var id in _customOrder) {
          if (map.containsKey(id)) {
            ordered.add(map[id]!);
            map.remove(id);
          }
        }
        // append any remaining cards not in custom order
        ordered.addAll(map.values);
        _cards = ordered;
      } else if (_sortBy == 'Name') {
        _cards.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      } else if (_sortBy == 'Company') {
        _cards.sort(
          (a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()),
        );
      } else {
        // Default Date sort: if BusinessCard has createdAt, sort by it descending
        try {
          DateTime parseDate(dynamic value) {
            if (value == null) return DateTime(1970);
            if (value is DateTime) return value;
            if (value is String) {
              try {
                return DateTime.parse(value);
              } catch (_) {
                return DateTime(1970);
              }
            }
            return DateTime(1970);
          }

          _cards.sort((a, b) {
            final aDate = parseDate(a.createdAt);
            final bDate = parseDate(b.createdAt);
            return bDate.compareTo(aDate);
          });
        } catch (_) {
          // fallback: no-op
        }
      }

      // apply search filter
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        _filteredCards = List.from(_cards);
      } else {
        _filteredCards = _cards.where((c) {
          final name = c.name.toLowerCase();
          final title = c.title.toLowerCase();
          final company = c.company.toLowerCase();
          return name.contains(query) ||
              title.contains(query) ||
              company.contains(query);
        }).toList();
      }

      // ensure current page is within bounds
      if (_currentPage >= _filteredCards.length) {
        _currentPage = _filteredCards.isEmpty ? 0 : _filteredCards.length - 1;
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  // Reorder card (move from oldIndex to newIndex)
  void _reorderCard(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _filteredCards.length) return;
    if (newIndex < 0 || newIndex >= _filteredCards.length) return;

    setState(() {
      final card = _filteredCards.removeAt(oldIndex);
      _filteredCards.insert(newIndex, card);

      // Update the master list _cards to reflect new order:
      // Build a new order by taking ids from filtered list in order, then appending other cards
      final idsInFiltered = _filteredCards.map((c) => c.id).toSet();
      final newCardsOrder = <BusinessCard>[];
      newCardsOrder.addAll(_filteredCards);
      newCardsOrder.addAll(_cards.where((c) => !idsInFiltered.contains(c.id)));
      _cards = newCardsOrder;

      // Update custom order
      _customOrder = _cards.map((c) => c.id).toList();
      _saveCustomOrder();
    });
  }

  Future<void> _createCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditCardScreen()),
    );
    await _fetchCards();
  }

  Future<void> _editCard(BusinessCard card) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditCardScreen(card: card)),
    );
    await _fetchCards();
  }

  Future<void> _shareCard(BusinessCard card) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharingScreen(card: card)),
    );
  }

  Future<void> _deleteCard(BusinessCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _cards.removeWhere((c) => c.id == card.id);
        _filteredCards.removeWhere((c) => c.id == card.id);
        _customOrder.removeWhere((id) => id == card.id);
        _saveCustomOrder();
      });
      try {
        final cardsData = _cards.map((c) => c.toJson()).toList();
        await _saveCardsToCache(cardsData.cast<Map<String, dynamic>>());
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Cards',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchCards,
          ),
          IconButton(
            icon: Icon(
              _isReorderMode ? Icons.check : Icons.swap_vert,
              color: _isReorderMode ? Colors.green : Colors.black,
            ),
            tooltip: _isReorderMode ? 'Done' : 'Reorder',
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_carousel_outlined : Icons.grid_view,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            color: Colors.white,
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortCards();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Custom', child: Text('Custom Order')),
              const PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              const PopupMenuItem(
                value: 'Company',
                child: Text('Sort by Company'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search cards...',
                hintStyle: const TextStyle(color: Color(0xFF696969)),
                prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                filled: true,
                fillColor: const Color(0xFFF1F1F1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cards found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                  ? _buildGridView()
                  : _buildCarouselView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCard,
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return FlipCardWidget(
          card: card,
          onEdit: () => _editCard(card),
          onShare: () => _shareCard(card),
          onDelete: () => _deleteCard(card),
        );
      },
    );
  }

  Widget _buildCarouselView() {
    // Center the indicator, carousel and swipe hint vertically
    final size = MediaQuery.of(context).size;
    const baseHeight = 1752;
    final heightScale = size.height / baseHeight;
    final baseCardHeight = 500 * heightScale;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentPage + 1}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ' / ${_filteredCards.length}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
              ],
            ),
          ),

          // Reorder hint
          if (_isReorderMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Use arrows to reorder cards',
                    style: TextStyle(color: Colors.green[300], fontSize: 12),
                  ),
                ],
              ),
            ),

          // Carousel (fixed height so the column can be centered)
          SizedBox(
            height: baseCardHeight + 100,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _filteredCards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final card = _filteredCards[index];
                final isCurrentPage = index == _currentPage;

                // Get or create GlobalKey for this card
                if (!_flipCardKeys.containsKey(card.id)) {
                  _flipCardKeys[card.id] = GlobalKey<_FlipCardWidgetState>();
                }

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                    }
                    return Center(
                      child: SizedBox(
                        height:
                            Curves.easeInOut.transform(value) * baseCardHeight,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      children: [
                        FlipCardWidget(
                          key: _flipCardKeys[card.id],
                          card: card,
                          onEdit: () => _editCard(card),
                          onShare: () => _shareCard(card),
                          onDelete: () => _deleteCard(card),
                          isActive: isCurrentPage && !_isReorderMode,
                        ),
                        // Reorder controls
                        if (_isReorderMode && isCurrentPage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Move left
                                  if (index > 0)
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          size: 32,
                                        ),
                                        color: Colors.black,
                                        onPressed: () {
                                          _reorderCard(index, index - 1);
                                          _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                  // Move right
                                  if (index < _filteredCards.length - 1)
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 32,
                                        ),
                                        color: Colors.black,
                                        onPressed: () {
                                          _reorderCard(index, index + 1);
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Swipe hint
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Swipe to browse',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return _buildCardListItem(card);
      },
    );
  }

  Widget _buildCardListItem(BusinessCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(card.themeColor),
            Color(card.themeColor).withOpacity(0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(card.themeColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _shareCard(card),
        title: Text(
          card.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              card.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              card.company,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF1C1A1B),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
              onTap: () => Future.delayed(Duration.zero, () => _editCard(card)),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.share, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Share', style: TextStyle(color: Colors.white)),
                ],
              ),
              onTap: () =>
                  Future.delayed(Duration.zero, () => _shareCard(card)),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () =>
                  Future.delayed(Duration.zero, () => _deleteCard(card)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flip Card Widget with 3D animation
class FlipCardWidget extends StatefulWidget {
  final BusinessCard card;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final bool isActive;

  const FlipCardWidget({
    super.key,
    required this.card,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
    this.isActive = true,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Reset flip state to show front side
  void resetFlip() {
    if (!_isFront) {
      _controller.reverse();
      setState(() {
        _isFront = true;
      });
    }
  }

  void _flipCard() {
    // Only allow flipping if this card is active
    if (!widget.isActive) return;

    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isActive ? _flipCard : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159; // π radians = 180 degrees
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle);

          // Determine which side to show
          final showFront = angle < 3.14159 / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: showFront ? _buildFrontCard() : _buildBackCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    final opacity = widget.isActive ? 1.0 : 0.5;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(widget.card.themeColor).withOpacity(opacity),
            Color(widget.card.themeColor).withOpacity(0.7 * opacity),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(
              widget.card.themeColor,
            ).withOpacity(widget.isActive ? 0.4 : 0.2),
            blurRadius: widget.isActive ? 12 : 6,
            offset: Offset(0, widget.isActive ? 6 : 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          if (widget.card.title.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.work, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.card.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Company
          if (widget.card.company.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.business, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.card.company,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Tap to flip hint (only show when active)
          if (widget.isActive)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to flip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Transform(
      transform: Matrix4.identity()..rotateY(3.14159), // Flip the back side
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(widget.card.themeColor).withOpacity(0.9),
              Color(widget.card.themeColor).withOpacity(0.6),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(widget.card.themeColor).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact info
            if (widget.card.email.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.card.email,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (widget.card.phone.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.card.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (widget.card.website.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.card.website,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () {
                    _flipCard();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      widget.onEdit,
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    _flipCard();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      widget.onShare,
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: () {
                    _flipCard();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      widget.onDelete,
                    );
                  },
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tap to flip back hint
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flip, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to flip back',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red[300] : Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red[300] : Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
