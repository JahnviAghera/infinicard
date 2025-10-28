import 'package:flutter/material.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/services/sharing_service.dart';
import 'package:infinicard/services/api_service.dart';
import 'package:infinicard/models/contact_model.dart';
import 'package:infinicard/services/contact_storage_service.dart';

class VCardImportScreen extends StatefulWidget {
  final String vcardRaw;

  const VCardImportScreen({super.key, required this.vcardRaw});

  @override
  State<VCardImportScreen> createState() => _VCardImportScreenState();
}

class _VCardImportScreenState extends State<VCardImportScreen> {
  late BusinessCard _cardPreview;
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _parseVCard();
  }

  void _parseVCard() {
    final lines = widget.vcardRaw.split(RegExp(r"\r?\n"));
    String name = '';
    String title = '';
    String company = '';
    String email = '';
    String phone = '';
    String website = '';

    for (final raw in lines) {
      final line = raw.trim();
      if (line.toUpperCase().startsWith('FN:')) {
        name = line.substring(3).trim();
      } else if (line.toUpperCase().startsWith('TITLE:')) {
        title = line.substring(6).trim();
      } else if (line.toUpperCase().startsWith('ORG:')) {
        company = line.substring(4).trim();
      } else if (line.toUpperCase().startsWith('EMAIL')) {
        // EMAIL or EMAIL;TYPE=INTERNET:foo@bar
        final parts = line.split(':');
        if (parts.length >= 2) email = parts.sublist(1).join(':').trim();
      } else if (line.toUpperCase().startsWith('TEL')) {
        final parts = line.split(':');
        if (parts.length >= 2) phone = parts.sublist(1).join(':').trim();
      } else if (line.toUpperCase().startsWith('URL:')) {
        website = line.substring(4).trim();
      }
    }

    _cardPreview = BusinessCard(
      id: '',
      name: name.isNotEmpty ? name : 'Imported Contact',
      title: title,
      company: company,
      email: email,
      phone: phone,
      website: website,
      linkedIn: '',
      github: '',
      themeColor: 0xFF1E88E5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveToContacts() async {
    try {
      await SharingService().saveAndOpenVCard(_cardPreview);

      // Also save into the app's contacts cache so it appears in Contacts screen
      try {
        final storage = ContactStorageService();
        final existing = await storage.loadContacts();
        final id = 'vcard_${DateTime.now().millisecondsSinceEpoch}';
        final newContact = Contact(
          id: id,
          name: _cardPreview.name,
          title: _cardPreview.title,
          company: _cardPreview.company,
          email: _cardPreview.email,
          phone: _cardPreview.phone,
          website: _cardPreview.website,
          linkedIn: '',
          github: '',
          avatarUrl: null,
          notes: 'Imported from vCard scan',
          address: '',
          isFavorite: false,
          reminderDate: null,
          tags: [],
          createdAt: DateTime.now(),
        );
        existing.insert(0, newContact);
        await storage.saveContacts(existing);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to app contacts')),
          );
        }
      } catch (e) {
        debugPrint('Error saving vCard to app contacts: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving contact: $e')));
      }
    }
  }

  Future<void> _importToInfinicard() async {
    setState(() => _isImporting = true);
    try {
      final api = ApiService();
      final res = await api.createCard(
        fullName: _cardPreview.name,
        jobTitle: _cardPreview.title.isNotEmpty ? _cardPreview.title : null,
        companyName: _cardPreview.company.isNotEmpty
            ? _cardPreview.company
            : null,
        email: _cardPreview.email.isNotEmpty ? _cardPreview.email : null,
        phone: _cardPreview.phone.isNotEmpty ? _cardPreview.phone : null,
        website: _cardPreview.website.isNotEmpty ? _cardPreview.website : null,
      );

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imported into Infinicard')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).pushNamed('/my-cards');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Import failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import vCard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardPreview.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_cardPreview.title.isNotEmpty)
                    Text(
                      _cardPreview.title,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (_cardPreview.company.isNotEmpty)
                    Text(
                      _cardPreview.company,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  if (_cardPreview.email.isNotEmpty)
                    Text('Email: ${_cardPreview.email}'),
                  if (_cardPreview.phone.isNotEmpty)
                    Text('Phone: ${_cardPreview.phone}'),
                  if (_cardPreview.website.isNotEmpty)
                    Text('Website: ${_cardPreview.website}'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isImporting ? null : _saveToContacts,
                          child: const Text('Save to Contacts'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isImporting ? null : _importToInfinicard,
                          child: _isImporting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Import to Infinicard'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
