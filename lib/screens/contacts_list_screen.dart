import 'package:flutter/material.dart';
import 'package:infinicard/models/contact_model.dart';
import 'package:infinicard/screens/contact_detail_screen.dart';
import 'package:infinicard/services/api_service.dart';
import 'package:infinicard/services/contact_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ContactStorageService _storageService = ContactStorageService();

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  String _filterBy = 'All';
  final List<String> _filterOptions = ['All', 'Company', 'Tag'];

  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOfflineMode = false;
    });

    // First, try to load from cache immediately for faster display
    final cachedContacts = await _storageService.loadContacts();
    if (cachedContacts.isNotEmpty && mounted) {
      setState(() {
        _allContacts = cachedContacts;
        _filteredContacts = cachedContacts;
      });
    }

    // Then try to fetch from network
    try {
      // Check internet connectivity
      final hasConnection = await _checkInternetConnection();

      if (!hasConnection) {
        // No internet, use cache only
        if (cachedContacts.isEmpty && mounted) {
          setState(() {
            _errorMessage = 'No internet connection. Please try again later.';
            _isLoading = false;
            _isOfflineMode = true;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
            _isOfflineMode = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📴 Offline mode - Showing cached contacts'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        return;
      }

      final result = await _apiService.getCards();

      if (result['success'] == true) {
        final cardsData = result['data'];

        // Handle the case where data might not be a List
        List<dynamic> cardsList;
        if (cardsData is List) {
          cardsList = cardsData;
        } else if (cardsData is Map && cardsData.containsKey('cards')) {
          cardsList = cardsData['cards'] as List;
        } else {
          throw Exception('Unexpected data format from API');
        }

        final contacts = cardsList.map((card) {
          return Contact(
            id: card['id']?.toString() ?? '',
            name: card['full_name']?.toString() ?? 'Unknown',
            title: card['job_title']?.toString() ?? '',
            company: card['company_name']?.toString() ?? '',
            email: card['email']?.toString() ?? '',
            phone: card['phone']?.toString() ?? '',
            website: card['website']?.toString() ?? '',
            address: card['address']?.toString() ?? '',
            notes: card['notes']?.toString() ?? '',
            avatarUrl: null,
            tags: card['tags'] != null
                ? (card['tags'] as List)
                      .map((tag) => tag['name'].toString())
                      .toList()
                : [],
            createdAt: card['created_at'] != null
                ? DateTime.tryParse(card['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            isFavorite: card['is_favorite'] == true,
          );
        }).toList();

        // Save to cache
        await _storageService.saveContacts(contacts);

        if (mounted) {
          setState(() {
            _allContacts = contacts;
            _filteredContacts = contacts;
            _isLoading = false;
            _isOfflineMode = false;
          });
        }
      } else {
        // API returned error, try to use cache
        if (cachedContacts.isEmpty && mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load contacts';
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ ${result['message'] ?? 'API error'} - Showing cached data',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading contacts: $e');

      // Network error, use cache if available
      if (cachedContacts.isEmpty && mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e);
          _isLoading = false;
          _isOfflineMode = true;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfflineMode = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📴 Network error - Showing cached contacts'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Parse error message to be user-friendly
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('FormatException') || errorStr.contains('DOCTYPE')) {
      return 'Server error: Invalid response format. Please check if the backend is running correctly.';
    } else if (errorStr.contains('SocketException') ||
        errorStr.contains('ClientException')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Connection timeout. Please try again.';
    } else {
      return 'Network error: ${errorStr.split(':').first}';
    }
  }

  /// Check if device has internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final matchesSearch =
            contact.name.toLowerCase().contains(query) ||
            contact.company.toLowerCase().contains(query) ||
            contact.email.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  void _openContactDetail(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contacts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isOfflineMode)
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_off,
                                  color: Colors.orange[400],
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Offline Mode',
                                  style: TextStyle(
                                    color: Colors.orange[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _isLoading ? null : _loadContacts,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
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
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((option) {
                        final isSelected = _filterBy == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _filterBy = option;
                                _filterContacts();
                              });
                            },
                            backgroundColor: const Color(0xFF1C1A1B),
                            selectedColor: const Color(0xFF1E88E5),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[400],
                            ),
                            checkmarkColor: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E88E5),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadContacts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No contacts found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan a business card to get started',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF1E88E5),
                      backgroundColor: const Color(0xFF1C1A1B),
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactCard(contact);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: InkWell(
        onTap: () => _openContactDetail(contact),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: contact.avatarUrl != null
                    ? NetworkImage(contact.avatarUrl!)
                    : null,
                backgroundColor: const Color(0xFF2B292A),
                child: contact.avatarUrl == null
                    ? Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (contact.title.isNotEmpty)
                      Text(
                        contact.title,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    if (contact.company.isNotEmpty)
                      Text(
                        contact.company,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    // Quick Action Buttons
                    Row(
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.phone,
                          color: Colors.green,
                          onTap: () => _makeCall(contact.phone),
                          tooltip: 'Call',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          icon: Icons.message,
                          color: Colors.blue,
                          onTap: () => _sendMessage(contact.phone),
                          tooltip: 'Message',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          icon: Icons.email,
                          color: Colors.orange,
                          onTap: () => _sendEmail(contact.email),
                          tooltip: 'Email',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone calls on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'sms', path: cleanPhone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot send messages on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Hello from Infinicard',
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
