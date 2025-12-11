import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PriorityStore {
  static const String _boxName = 'priority_box';
  static const String _domainBoxName = 'domain_priority_box';

  static final PriorityStore _instance = PriorityStore._internal();

  Box<Map<dynamic, dynamic>>? _box;
  Box<Map<dynamic, dynamic>>? _domainBox;
  bool _isInitialized = false;

  factory PriorityStore() {
    return _instance;
  }

  PriorityStore._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<Map>(_boxName);
      } else {
        _box = Hive.box<Map>(_boxName);
      }

      if (!Hive.isBoxOpen(_domainBoxName)) {
        _domainBox = await Hive.openBox<Map>(_domainBoxName);
      } else {
        _domainBox = Hive.box<Map>(_domainBoxName);
      }

      _isInitialized = true;
      debugPrint('PriorityStore initialized successfully');
    } catch (e) {
      debugPrint('Error initializing priority store: $e');
      rethrow;
    }
  }

  String _extractDomain(String email) {
    try {
      if (email.contains('@')) {
        return email.split('@')[1].split('>')[0].toLowerCase();
      }
      return email.toLowerCase();
    } catch (e) {
      return email.toLowerCase();
    }
  }

  Future<void> savePriority(
    String messageId,
    int score,
    String label, {
    bool manualOverride = false,
    String? manualLabel,
  }) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final data = <String, dynamic>{
        'messageId': messageId,
        'score': score,
        'label': label,
        'manualOverride': manualOverride,
        'manualLabel': manualLabel,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box!.put(messageId, data);
    } catch (e) {
      debugPrint('Error saving priority for $messageId: $e');
    }
  }

  /// Save domain-level priority override (all emails from this domain get this priority)
  Future<void> saveDomainPriority(String emailAddress, String label) async {
    if (_domainBox == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    if (emailAddress.isEmpty) {
      debugPrint('Error: emailAddress cannot be empty');
      return;
    }
    try {
      final domain = _extractDomain(emailAddress);
      final data = <String, dynamic>{
        'domain': domain,
        'label': label,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _domainBox!.put(domain, data);
      debugPrint('Saved domain priority: $domain -> $label');
    } catch (e) {
      debugPrint('Error saving domain priority for $emailAddress: $e');
      rethrow;
    }
  }

  /// Load domain-level priority override for a given email address
  Future<String?> loadDomainPriority(String emailAddress) async {
    if (_domainBox == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final domain = _extractDomain(emailAddress);
      final data = _domainBox!.get(domain);
      if (data != null) {
        return data['label'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error loading domain priority for $emailAddress: $e');
      return null;
    }
  }

  /// Load all domain-level priority overrides
  Future<Map<String, String>> loadAllDomainPriorities() async {
    if (_domainBox == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final result = <String, String>{};
      for (var entry in _domainBox!.toMap().entries) {
        final data = entry.value as Map?;
        if (data != null) {
          final domain = data['domain'] as String?;
          final label = data['label'] as String?;
          if (domain != null && label != null) {
            result[domain] = label;
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error loading all domain priorities: $e');
      return {};
    }
  }

  /// Delete domain-level priority override
  Future<void> deleteDomainPriority(String emailAddress) async {
    if (_domainBox == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final domain = _extractDomain(emailAddress);
      await _domainBox!.delete(domain);
    } catch (e) {
      debugPrint('Error deleting domain priority for $emailAddress: $e');
      rethrow;
    }
  }

  Future<void> saveManualPriority(
    String messageId,
    int score,
    String label,
  ) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    if (messageId.isEmpty) {
      debugPrint('Error: messageId cannot be empty');
      return;
    }
    try {
      final data = <String, dynamic>{
        'messageId': messageId,
        'score': score,
        'label': label,
        'manualOverride': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box!.put(messageId, data);
    } catch (e) {
      debugPrint('Error saving manual priority for $messageId: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loadPriority(String messageId) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final data = _box!.get(messageId);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading priority for $messageId: $e');
      return null;
    }
  }

  Future<void> deleteManualPriority(String messageId) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      await _box!.delete(messageId);
    } catch (e) {
      debugPrint('Error deleting priority for $messageId: $e');
      rethrow;
    }
  }

  Future<void> updateManualOverride(
    String messageId,
    String manualLabel,
  ) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final existing = _box!.get(messageId);
      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        data['manualOverride'] = true;
        data['manualLabel'] = manualLabel;
        data['timestamp'] = DateTime.now().toIso8601String();
        await _box!.put(messageId, data);
      }
    } catch (e) {
      debugPrint('Error updating manual override for $messageId: $e');
    }
  }

  Future<void> clearOverride(String messageId) async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final existing = _box!.get(messageId);
      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        data['manualOverride'] = false;
        data['manualLabel'] = null;
        await _box!.put(messageId, data);
      }
    } catch (e) {
      debugPrint('Error clearing override for $messageId: $e');
    }
  }

  Future<void> clear() async {
    if (_box == null || _domainBox == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      await _box!.clear();
      await _domainBox!.clear();
    } catch (e) {
      debugPrint('Error clearing priority store: $e');
    }
  }

  Future<Map<String, Map<String, dynamic>>> loadAllPriorities() async {
    if (_box == null) {
      throw Exception('PriorityStore not initialized. Call init() first.');
    }
    try {
      final result = <String, Map<String, dynamic>>{};
      for (var entry in _box!.toMap().entries) {
        result[entry.key as String] = Map<String, dynamic>.from(entry.value);
      }
      return result;
    } catch (e) {
      debugPrint('Error loading all priorities: $e');
      return {};
    }
  }
}
