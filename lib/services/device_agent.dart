import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_control_service.dart';
import 'nim_service.dart';

enum AgentEvent { thinking, action, done, error }

class AgentStep {
  final AgentEvent type;
  final String message;
  AgentStep(this.type, this.message);
}

/// Drives the screen step-by-step: capture → ask AI → execute → repeat,
/// until the AI reports the task is complete or max steps is hit.
class DeviceAgent {
  final NimService nim;
  bool _stopRequested = false;

  DeviceAgent(this.nim);

  void stop() => _stopRequested = true;

  Stream<AgentStep> run(String instruction, {int maxSteps = 15}) async* {
    _stopRequested = false;

    if (!await DeviceControlService.isEnabled()) {
      yield AgentStep(AgentEvent.error,
          'Accessibility service not enabled. Enable it in Settings → Device Control.');
      return;
    }

    final actionLog = <String>[];

    for (int step = 0; step < maxSteps; step++) {
      if (_stopRequested) {
        yield AgentStep(AgentEvent.done, 'Stopped by user.');
        return;
      }

      final elements = await DeviceControlService.captureScreen();
      final app = await DeviceControlService.currentApp();

      // Trim screen elements to keep prompt small — top 60 most relevant
      final trimmed = elements.take(60).toList();

      final decision = await _decide(
        instruction: instruction,
        currentApp: app,
        elements: trimmed,
        history: actionLog,
      );

      if (decision == null) {
        yield AgentStep(AgentEvent.error, 'AI returned an invalid response. Stopping.');
        return;
      }

      final action = decision['action'] as String? ?? 'stop';
      final reason = decision['reason'] as String? ?? '';

      yield AgentStep(AgentEvent.thinking, reason);

      if (action == 'done') {
        yield AgentStep(AgentEvent.done, decision['summary'] ?? 'Task complete.');
        return;
      }

      final desc = await _execute(action, decision);
      actionLog.add(desc);
      yield AgentStep(AgentEvent.action, desc);

      // Small delay to let UI settle after the action
      await Future.delayed(const Duration(milliseconds: 600));
    }

    yield AgentStep(AgentEvent.done, 'Reached max steps ($maxSteps) without completion.');
  }

  // ── ASK THE MODEL WHAT TO DO NEXT ────────────────────────
  Future<Map<String, dynamic>?> _decide({
    required String instruction,
    required String currentApp,
    required List<Map<String, dynamic>> elements,
    required List<String> history,
  }) async {
    final systemPrompt = '''
You control an Android phone screen. You see a JSON list of UI elements (text, position, clickable/editable flags) and must choose ONE next action to progress toward the user's goal.

Respond with ONLY raw JSON, no markdown, no explanation outside the JSON:

{"action":"tap","x":123,"y":456,"reason":"short reason"}
{"action":"type","text":"hello","reason":"short reason"}
{"action":"swipe","x1":500,"y1":1500,"x2":500,"y2":500,"reason":"scroll down"}
{"action":"back","reason":"short reason"}
{"action":"home","reason":"short reason"}
{"action":"open_app","package":"com.android.chrome","reason":"short reason"}
{"action":"done","summary":"what was accomplished","reason":"task complete"}

Rules:
- Pick coordinates from the element list's x/y values (these are element centers).
- Use "type" only right after tapping an editable field.
- If the goal is achieved, return "done" with a summary.
- If stuck or instruction is unclear, return "done" with summary explaining why.
- Keep "reason" under 12 words.
''';

    final userPrompt = '''
GOAL: $instruction

CURRENT APP: $currentApp

ACTIONS TAKEN SO FAR:
${history.isEmpty ? '(none yet)' : history.map((h) => '- $h').join('\n')}

VISIBLE SCREEN ELEMENTS:
${jsonEncode(elements)}

What is the next single action?
''';

    try {
      final resp = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${nim.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': nim.model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': 300,
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body);
      String text = body['choices'][0]['message']['content'] ?? '';
      text = text.trim();

      // Strip markdown fences if model added them anyway
      if (text.startsWith('```')) {
        final lines = text.split('\n');
        lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.trim().startsWith('```')) lines.removeLast();
        text = lines.join('\n');
      }

      // Extract first {...} block defensively
      final start = text.indexOf('{');
      final end   = text.lastIndexOf('}');
      if (start == -1 || end == -1) return null;
      text = text.substring(start, end + 1);

      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── EXECUTE THE CHOSEN ACTION ─────────────────────────────
  Future<String> _execute(String action, Map<String, dynamic> d) async {
    switch (action) {
      case 'tap':
        final x = (d['x'] as num?)?.toInt() ?? 0;
        final y = (d['y'] as num?)?.toInt() ?? 0;
        await DeviceControlService.tap(x, y);
        return 'Tapped ($x, $y)';

      case 'type':
        final text = d['text']?.toString() ?? '';
        await DeviceControlService.typeText(text);
        return 'Typed "$text"';

      case 'swipe':
        final x1 = (d['x1'] as num?)?.toInt() ?? 0;
        final y1 = (d['y1'] as num?)?.toInt() ?? 0;
        final x2 = (d['x2'] as num?)?.toInt() ?? 0;
        final y2 = (d['y2'] as num?)?.toInt() ?? 0;
        await DeviceControlService.swipe(x1, y1, x2, y2);
        return 'Swiped ($x1,$y1)→($x2,$y2)';

      case 'back':
        await DeviceControlService.back();
        return 'Pressed Back';

      case 'home':
        await DeviceControlService.home();
        return 'Pressed Home';

      case 'open_app':
        final pkg = d['package']?.toString() ?? '';
        final ok = await DeviceControlService.openApp(pkg);
        return ok ? 'Opened $pkg' : 'Failed to open $pkg';

      default:
        return 'Unknown action: $action';
    }
  }
}
