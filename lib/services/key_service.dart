import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_key_entry.dart';

class KeyService {
  static const _kKeysList   = 'nemotron_keys_list';
  static const _kActiveId   = 'nemotron_active_key_id';

  static Future<List<ApiKeyEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeysList);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ApiKeyEntry.fromJson(e)).toList();
  }

  static Future<void> _saveAll(List<ApiKeyEntry> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(keys.map((e) => e.toJson()).toList());
    await prefs.setString(_kKeysList, raw);
  }

  static Future<ApiKeyEntry?> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kActiveId);
    final all = await getAll();
    if (all.isEmpty) return null;
    if (id == null) return all.first;
    try {
      return all.firstWhere((k) => k.id == id);
    } catch (_) {
      return all.first;
    }
  }

  static Future<void> setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveId, id);
  }

  static Future<ApiKeyEntry> add({required String label, required String key}) async {
    final all = await getAll();
    final entry = ApiKeyEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.isEmpty ? 'Key ${all.length + 1}' : label,
      key: key,
    );
    all.add(entry);
    await _saveAll(all);
    // First key added automatically becomes active
    if (all.length == 1) await setActive(entry.id);
    return entry;
  }

  static Future<void> remove(String id) async {
    final all = await getAll();
    all.removeWhere((k) => k.id == id);
    await _saveAll(all);

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_kActiveId);
    if (activeId == id) {
      if (all.isNotEmpty) {
        await setActive(all.first.id);
      } else {
        await prefs.remove(_kActiveId);
      }
    }
  }

  static Future<void> rename(String id, String newLabel) async {
    final all = await getAll();
    final idx = all.indexWhere((k) => k.id == id);
    if (idx == -1) return;
    all[idx].label = newLabel;
    await _saveAll(all);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeysList);
    await prefs.remove(_kActiveId);
  }
}
