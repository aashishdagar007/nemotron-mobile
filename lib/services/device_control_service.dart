import 'dart:convert';
import 'package:flutter/services.dart';

class DeviceControlService {
  static const _channel = MethodChannel('nemotron/control');

  static Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Returns a list of screen elements: {text, desc, class, clickable, editable, x, y, w, h}
  static Future<List<Map<String, dynamic>>> captureScreen() async {
    final raw = await _channel.invokeMethod<String>('captureScreen') ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<String> currentApp() async {
    return await _channel.invokeMethod<String>('currentApp') ?? 'unknown';
  }

  static Future<bool> tap(int x, int y) async {
    return await _channel.invokeMethod<bool>('tap', {'x': x, 'y': y}) ?? false;
  }

  static Future<bool> swipe(int x1, int y1, int x2, int y2, {int durationMs = 300}) async {
    return await _channel.invokeMethod<bool>('swipe', {
      'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 'duration': durationMs,
    }) ?? false;
  }

  static Future<bool> typeText(String text) async {
    return await _channel.invokeMethod<bool>('typeText', {'text': text}) ?? false;
  }

  static Future<void> back()    async => _channel.invokeMethod('back');
  static Future<void> home()    async => _channel.invokeMethod('home');
  static Future<void> recents() async => _channel.invokeMethod('recents');

  static Future<bool> openApp(String packageName) async {
    return await _channel.invokeMethod<bool>('openApp', {'package': packageName}) ?? false;
  }
}
