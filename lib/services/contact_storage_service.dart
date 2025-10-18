import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:infinicard/models/contact_model.dart';

/// Service for storing and retrieving contacts from local CSV file
/// Used for offline access and faster loading
class ContactStorageService {
  static const String _fileName = 'contacts_cache.csv';

  // Singleton pattern
  static final ContactStorageService _instance =
      ContactStorageService._internal();
  factory ContactStorageService() => _instance;
  ContactStorageService._internal();

  /// Get the path to the CSV file
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the CSV file
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  /// Save contacts to CSV file
  Future<bool> saveContacts(List<Contact> contacts) async {
    try {
      final file = await _localFile;

      // Create CSV data
      List<List<dynamic>> rows = [];

      // Add header row
      rows.add([
        'id',
        'name',
        'title',
        'company',
        'email',
        'phone',
        'website',
        'linkedIn',
        'github',
        'avatarUrl',
        'notes',
        'address',
        'isFavorite',
        'reminderDate',
        'tags',
        'createdAt',
      ]);

      // Add contact data rows
      for (var contact in contacts) {
        rows.add([
          contact.id,
          contact.name,
          contact.title,
          contact.company,
          contact.email,
          contact.phone,
          contact.website,
          contact.linkedIn,
          contact.github,
          contact.avatarUrl ?? '',
          contact.notes,
          contact.address,
          contact.isFavorite.toString(),
          contact.reminderDate?.toIso8601String() ?? '',
          contact.tags.join('|'), // Use pipe separator for tags
          contact.createdAt.toIso8601String(),
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Write to file
      await file.writeAsString(csv);

      print('✅ Saved ${contacts.length} contacts to CSV cache');
      return true;
    } catch (e) {
      print('❌ Error saving contacts to CSV: $e');
      return false;
    }
  }

  /// Load contacts from CSV file
  Future<List<Contact>> loadContacts() async {
    try {
      final file = await _localFile;

      // Check if file exists
      if (!await file.exists()) {
        print('ℹ️ No CSV cache file found');
        return [];
      }

      // Read file content
      final contents = await file.readAsString();

      // Parse CSV
      List<List<dynamic>> csvData = const CsvToListConverter().convert(
        contents,
      );

      // Skip header row
      if (csvData.isEmpty || csvData.length < 2) {
        print('ℹ️ CSV cache is empty');
        return [];
      }

      List<Contact> contacts = [];

      // Parse each row (skip header at index 0)
      for (int i = 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];

          // Ensure row has enough columns
          if (row.length < 16) continue;

          contacts.add(
            Contact(
              id: row[0].toString(),
              name: row[1].toString(),
              title: row[2].toString(),
              company: row[3].toString(),
              email: row[4].toString(),
              phone: row[5].toString(),
              website: row[6].toString(),
              linkedIn: row[7].toString(),
              github: row[8].toString(),
              avatarUrl: row[9].toString().isEmpty ? null : row[9].toString(),
              notes: row[10].toString(),
              address: row[11].toString(),
              isFavorite: row[12].toString().toLowerCase() == 'true',
              reminderDate: row[13].toString().isEmpty
                  ? null
                  : DateTime.tryParse(row[13].toString()),
              tags: row[14].toString().isEmpty
                  ? []
                  : row[14].toString().split('|'),
              createdAt: DateTime.parse(row[15].toString()),
            ),
          );
        } catch (e) {
          print('⚠️ Error parsing contact row $i: $e');
          continue;
        }
      }

      print('✅ Loaded ${contacts.length} contacts from CSV cache');
      return contacts;
    } catch (e) {
      print('❌ Error loading contacts from CSV: $e');
      return [];
    }
  }

  /// Clear the CSV cache
  Future<bool> clearCache() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
        print('✅ CSV cache cleared');
      }
      return true;
    } catch (e) {
      print('❌ Error clearing CSV cache: $e');
      return false;
    }
  }

  /// Check if cache exists
  Future<bool> cacheExists() async {
    try {
      final file = await _localFile;
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get cache file size in bytes
  Future<int> getCacheSize() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get last modified time of cache
  Future<DateTime?> getLastModified() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return await file.lastModified();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
