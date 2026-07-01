import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class ChatStorageService {
  static const _kChats = 'nemotron_chats';

  static Future<List<ChatSession>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kChats);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    final chats = list.map((e) => ChatSession.fromJson(e)).toList();
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  static Future<void> save(ChatSession chat) async {
    final all = await getAll();
    final idx = all.indexWhere((c) => c.id == chat.id);
    chat.updatedAt = DateTime.now();
    if (idx == -1) {
      all.add(chat);
    } else {
      all[idx] = chat;
    }
    await _saveAll(all);
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((c) => c.id == id);
    await _saveAll(all);
  }

  static Future<void> _saveAll(List<ChatSession> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(chats.map((c) => c.toJson()).toList());
    await prefs.setString(_kChats, raw);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChats);
  }

  static String genId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static String titleFromText(String text) {
    final clean = text.trim().replaceAll('\n', ' ');
    return clean.length > 42 ? '${clean.substring(0, 42)}…' : clean;
  }
}
