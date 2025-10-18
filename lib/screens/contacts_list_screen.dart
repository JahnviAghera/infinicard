import 'package:flutter/material.dart';
import 'package:infinicard/models/contact_model.dart';
import 'package:infinicard/screens/contact_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  String _filterBy = 'All';
  final List<String> _filterOptions = ['All', 'Company', 'Tag'];

  @override
  void initState() {
    super.initState();
    _loadDemoContacts();
    _filteredContacts = _allContacts;
    _searchController.addListener(_filterContacts);
  }

  void _loadDemoContacts() {
    _allContacts = [
      Contact(
        id: '1',
        name: 'Alice Johnson',
        title: 'Software Engineer',
        company: 'Tech Corp',
        email: 'alice@techcorp.com',
        phone: '+1 555 0101',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        tags: ['Developer', 'Tech'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Contact(
        id: '2',
        name: 'Bob Smith',
        title: 'Product Manager',
        company: 'StartupXYZ',
        email: 'bob@startupxyz.com',
        phone: '+1 555 0102',
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
        tags: ['Manager', 'Product'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Contact(
        id: '3',
        name: 'Carol Davis',
        title: 'Designer',
        company: 'Creative Agency',
        email: 'carol@creative.com',
        phone: '+1 555 0103',
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
        tags: ['Designer', 'Creative'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
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
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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
              child: _filteredContacts.isEmpty
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
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        return _buildContactCard(contact);
                      },
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
