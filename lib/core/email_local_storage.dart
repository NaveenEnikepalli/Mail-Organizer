import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'email_metadata.dart';

class EmailLocalStorage {
  static const String _boxName = 'email_metadata_box';
  late Box<Map<dynamic, dynamic>> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> saveEmails(List<EmailMetadata> emails) async {
    try {
      await _box.clear();
      for (var email in emails) {
        final jsonMap = email.toJson();
        final mutableMap = Map<dynamic, dynamic>.from(jsonMap);
        await _box.put(email.id, mutableMap);
      }
    } catch (e) {
      debugPrint('Error saving emails to local storage: $e');
    }
  }

  Future<List<EmailMetadata>> loadEmails() async {
    try {
      final emails = <EmailMetadata>[];
      for (var value in _box.values) {
        try {
          final jsonMap = Map<String, dynamic>.from(value);
          final email = EmailMetadata.fromJson(jsonMap);
          emails.add(email);
        } catch (e) {
          debugPrint('Error parsing email from local storage: $e');
        }
      }
      return emails;
    } catch (e) {
      debugPrint('Error loading emails from local storage: $e');
      return [];
    }
  }

  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }
}
