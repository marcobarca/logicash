import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_key_model.dart';

class ApiKeyStore {
  static const _storageKey = 'custom_api_keys';
  final FlutterSecureStorage _storage;

  ApiKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<ApiKeyEntry>> getAll() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ApiKeyEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(ApiKeyEntry entry) async {
    final all = await getAll();
    final idx = all.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      all[idx] = entry;
    } else {
      all.add(entry);
    }
    await _storage.write(key: _storageKey, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((e) => e.id == id);
    await _storage.write(key: _storageKey, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<String?> getKey(String name) async {
    final all = await getAll();
    try {
      return all.firstWhere((e) => e.name.toLowerCase() == name.toLowerCase()).key;
    } catch (_) {
      return null;
    }
  }
}
