import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../services/nim_service.dart';
import '../theme.dart';
import '../models/message.dart';

class EditorScreen extends StatefulWidget {
  final String path;
  const EditorScreen({super.key, required this.path});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _ctrl;
  bool _loading  = true;
  bool _dirty    = false;
  bool _aiBusy   = false;
  String _original = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final content = await FileService.readFile(widget.path);
    _original = content.startsWith('ERROR') ? '' : content;
    _ctrl.text = _original;
    _ctrl.addListener(() {
      final isDirty = _ctrl.text != _original;
      if (isDirty != _dirty) setState(() => _dirty = isDirty);
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final result = await FileService.writeFile(widget.path, _ctrl.text);
    _original = _ctrl.text;
    setState(() => _dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.startsWith('ERROR') ? result : 'Saved'),
          duration: const Duration(seconds: 1),
          backgroundColor: result.startsWith('ERROR') ? AppTheme.danger : AppTheme.success,
        ),
      );
    }
  }

  // ── AI ASSIST ────────────────────────────────────────────
  Future<void> _askAI(String apiKey, String model) async {
    final instruction = await _promptInstruction();
    if (instruction == null || instruction.isEmpty) return;

    setState(() => _aiBusy = true);

    final nim = NimService(apiKey: apiKey, model: model, thinking: false);
    final prompt = '''
Here is the current file content:

```
${_ctrl.text}
```

Instruction: $instruction

Return ONLY the complete updated file content. No explanations, no markdown fences, just the raw code.
''';

    String result = '';
    try {
      await for (final chunk in nim.streamChat(history: [], userMessage: prompt)) {
        if (chunk['type'] == 'answer') result += chunk['text']!;
      }
      // Strip markdown fences if model added them anyway
      result = result.trim();
      if (result.startsWith('```')) {
        final lines = result.split('\n');
        lines.removeAt(0);
        if (lines.isNotEmpty && lines.last.trim() == '```') lines.removeLast();
        result = lines.join('\n');
      }
      setState(() {
        _ctrl.text = result;
        _dirty = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }

    setState(() => _aiBusy = false);
  }

  Future<String?> _promptInstruction() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Ask Nemotron', style: TextStyle(color: AppTheme.textPri, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPri),
          decoration: const InputDecoration(
            hintText: 'e.g. "add error handling" or "fix the bug"',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Apply', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: Text(FileService.fileName(widget.path), overflow: TextOverflow.ellipsis),
        actions: [
          if (_aiBusy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.think),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: AppTheme.think),
              tooltip: 'Ask AI to edit',
              onPressed: () async {
                final key = await _getApiKey();
                if (key != null) _askAI(key, kModels['super']!);
              },
            ),
          IconButton(
            icon: Icon(Icons.save, color: _dirty ? AppTheme.accent : AppTheme.textDim),
            onPressed: _dirty ? _save : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
    );
  }

  Future<String?> _getApiKey() async {
    // Pulled from shared prefs via parent — simplified here
    return NimServiceHolder.apiKey;
  }
}

/// Simple static holder so editor can access the saved key
/// without re-plumbing providers through every screen.
class NimServiceHolder {
  static String? apiKey;
}
