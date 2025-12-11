import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'deadline_detector.dart';

class DeadlineStore {
  static final DeadlineStore _instance = DeadlineStore._internal();

  factory DeadlineStore() {
    return _instance;
  }

  DeadlineStore._internal();

  static const String _boxName = 'deadline_box';
  Box<Map>? _box;
  bool _isInitialized = false;

  /// Initialize the Hive box
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<Map>(_boxName);
      } else {
        _box = Hive.box<Map>(_boxName);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing DeadlineStore: $e');
    }
  }

  /// Save deadline metadata for a message
  Future<void> saveDeadlineMetadata(
    String messageId,
    DeadlineDetectionResult detection,
  ) async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return;

      final payload = detection.toMap();
      await _box!.put('deadline_$messageId', payload);
    } catch (e) {
      debugPrint('Error saving deadline metadata for $messageId: $e');
    }
  }

  /// Load deadline metadata for a message
  Future<Map<String, dynamic>?> loadDeadlineMetadata(String messageId) async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return null;

      final data = _box!.get('deadline_$messageId');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading deadline metadata for $messageId: $e');
      return null;
    }
  }

  /// Get all message IDs that have deadline metadata
  Future<List<String>> loadAllMessageIdsWithDeadlines() async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return [];

      final result = <String>[];
      for (final key in _box!.keys) {
        if (key is String && key.startsWith('deadline_')) {
          final data = _box!.get(key);
          if (data != null) {
            final hasDeadline = (data['hasDeadline'] as bool?) ?? false;
            if (hasDeadline) {
              result.add(key.replaceFirst('deadline_', ''));
            }
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error loading message IDs with deadlines: $e');
      return [];
    }
  }

  /// Save a reminder as dismissed
  Future<void> saveReminderDismissed(String messageId, bool dismissed) async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return;

      final key = 'reminder_dismissed_$messageId';
      if (dismissed) {
        await _box!.put(key, {'dismissed': true});
      } else {
        await _box!.delete(key);
      }
    } catch (e) {
      debugPrint('Error saving reminder dismissal for $messageId: $e');
    }
  }

  /// Check if a reminder is dismissed
  Future<bool> isReminderDismissed(String messageId) async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return false;

      final key = 'reminder_dismissed_$messageId';
      final data = _box!.get(key);
      return data != null;
    } catch (e) {
      debugPrint('Error checking reminder dismissal for $messageId: $e');
      return false;
    }
  }

  /// Load all dismissed reminder IDs
  Future<List<String>> loadAllDismissedReminders() async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return [];

      final result = <String>[];
      for (final key in _box!.keys) {
        if (key is String && key.startsWith('reminder_dismissed_')) {
          result.add(key.replaceFirst('reminder_dismissed_', ''));
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error loading dismissed reminders: $e');
      return [];
    }
  }

  /// Clear all deadline data (for testing)
  Future<void> clear() async {
    try {
      if (_box == null) {
        await init();
      }
      if (_box == null) return;
      await _box!.clear();
    } catch (e) {
      debugPrint('Error clearing deadline store: $e');
    }
  }
}
