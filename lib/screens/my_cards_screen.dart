import 'package:flutter/material.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/screens/create_edit_card_screen.dart';
import 'package:infinicard/screens/card_preview_screen.dart';
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
  List<BusinessCard> _cards = [];
  List<BusinessCard> _filteredCards = [];
  bool _isGridView = true;
  String _sortBy = 'Date';

  @override
  void initState() {
    super.initState();
    _loadCachedCards(); // Load offline cache first
    _fetchCards(); // Then fetch from API
    _searchController.addListener(_filterCards);
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
          _filteredCards = _cards;
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

  Future<void> _fetchCards() async {
    try {
      final response = await ApiService().getCards();
      if (response['success'] == true && response['data'] != null) {
        final dynamic rawData = response['data'];

        // Handle both List and other possible types
        if (rawData is List) {
          final List<Map<String, dynamic>> cardsData = rawData
              .map((e) => e as Map<String, dynamic>)
              .toList();

          // Save to cache for offline use
          await _saveCardsToCache(cardsData);

          setState(() {
            _cards = cardsData
                .map((json) => BusinessCard.fromJson(json))
                .toList();
            _filteredCards = _cards;
          });
        }
      }
    } catch (e) {
      // If API fails, cached data is already loaded from _loadCachedCards
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using offline data. Network error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCards() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCards = _cards.where((card) {
        return card.name.toLowerCase().contains(query) ||
            card.company.toLowerCase().contains(query) ||
            card.title.toLowerCase().contains(query);
      }).toList();
      _sortCards();
    });
  }

  void _sortCards() {
    if (_sortBy == 'Date') {
      _filteredCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Name') {
      _filteredCards.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Company') {
      _filteredCards.sort((a, b) => a.company.compareTo(b.company));
    }
  }

  void _createCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEditCardScreen()),
    );
    if (result != null && result is BusinessCard) {
      // Refresh cards from backend
      await _fetchCards();
    }
  }

  void _editCard(BusinessCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEditCardScreen(card: card)),
    );
    if (result != null && result is BusinessCard) {
      // Refresh cards from backend
      await _fetchCards();
    }
  }

  void _shareCard(BusinessCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CardPreviewScreen(card: card)),
    );
  }

  void _deleteCard(BusinessCard card) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A1B),
        title: const Text('Delete Card', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${card.name}\'s card?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteCard(card.id);
                await _fetchCards();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Card deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete card: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Cards',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            onPressed: _fetchCards,
                          ),
                          IconButton(
                            icon: Icon(
                              _isGridView ? Icons.list : Icons.grid_view,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.sort, color: Colors.white),
                            color: const Color(0xFF1C1A1B),
                            onSelected: (value) {
                              setState(() {
                                _sortBy = value;
                                _sortCards();
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Date',
                                child: Text(
                                  'Sort by Date',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'Name',
                                child: Text(
                                  'Sort by Name',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'Company',
                                child: Text(
                                  'Sort by Company',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFF1C1A1B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cards
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
                  : _buildListView(),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return _buildCardGridItem(card);
      },
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

  Widget _buildCardGridItem(BusinessCard card) {
    return GestureDetector(
      onTap: () => _shareCard(card),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(card.themeColor),
              Color(card.themeColor).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.company,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () => _editCard(card),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: () => _shareCard(card),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => _deleteCard(card),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
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
