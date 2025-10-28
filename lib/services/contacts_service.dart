import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsService {
  static const String _prefsKey = 'app_contacts';

  static final ContactsService _instance = ContactsService._internal();
  factory ContactsService() => _instance;
  ContactsService._internal();

  Future<List<Map<String, String>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(contacts));
  }

  Future<void> addContact(Map<String, String> contact) async {
    final contacts = await getContacts();
    // simple duplicate check by phone or email
    final exists = contacts.any((c) {
      final a = c['phone'] ?? '';
      final b = c['email'] ?? '';
      return (a.isNotEmpty && a == (contact['phone'] ?? '')) ||
          (b.isNotEmpty && b == (contact['email'] ?? ''));
    });
    if (!exists) {
      contacts.add(contact);
      await saveContacts(contacts);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
