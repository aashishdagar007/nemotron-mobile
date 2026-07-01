import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/nim_service.dart';
import '../services/theme_controller.dart';
import '../services/key_service.dart';
import '../services/chat_storage_service.dart';
import 'keys_screen.dart';

class SettingsScreen extends StatefulWidget {
  final NimService nim;
  final VoidCallback onKeyCleared;
  final VoidCallback onActiveKeyChanged;
  const SettingsScreen({
    super.key,
    required this.nim,
    required this.onKeyCleared,
    required this.onActiveKeyChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _budget = 8192;

  @override
  void initState() {
    super.initState();
    _budget = widget.nim.budget;
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Clear everything?', style: TextStyle(color: AppTheme.textPri)),
        content: const Text('This removes all saved keys and chat history.',
          style: TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      widget.onKeyCleared();
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Clear chat history?', style: TextStyle(color: AppTheme.textPri)),
        content: const Text('All saved chats will be deleted. API keys stay intact.',
          style: TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ChatStorageService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history cleared'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgMain,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('APPEARANCE'),
          Container(
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (_, mode, __) => Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    onChanged: (m) => ThemeController.set(m!),
                    activeColor: c.accent,
                    title: Text('Dark', style: TextStyle(color: c.textPri, fontSize: 14)),
                    secondary: Icon(Icons.dark_mode_outlined, color: c.textSec, size: 20),
                  ),
                  Divider(height: 1, color: c.border),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    onChanged: (m) => ThemeController.set(m!),
                    activeColor: c.accent,
                    title: Text('Light', style: TextStyle(color: c.textPri, fontSize: 14)),
                    secondary: Icon(Icons.light_mode_outlined, color: c.textSec, size: 20),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('API KEYS'),
          Container(
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.vpn_key_outlined, color: c.accent, size: 20),
              title: Text('Manage API Keys', style: TextStyle(color: c.textPri, fontSize: 14)),
              subtitle: Text('Add, switch, or remove saved keys', style: TextStyle(color: c.textSec, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: c.textDim),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => KeysScreen(nim: widget.nim, onActiveKeyChanged: widget.onActiveKeyChanged),
                ));
                widget.onActiveKeyChanged();
              },
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('REASONING BUDGET'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Slider(
                  value: _budget.toDouble(),
                  min: 2048, max: 32768, divisions: 14,
                  activeColor: c.think,
                  inactiveColor: c.border,
                  label: '$_budget tokens',
                  onChanged: (v) {
                    setState(() => _budget = v.round());
                    widget.nim.budget = _budget;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('$_budget tokens', style: TextStyle(color: c.textSec, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('DATA'),
          Container(
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: c.textSec, size: 20),
              title: Text('Clear Chat History', style: TextStyle(color: c.textPri, fontSize: 14)),
              subtitle: Text('Keeps your saved API keys', style: TextStyle(color: c.textSec, fontSize: 12)),
              onTap: _clearChatHistory,
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('ABOUT'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nemotron Code', style: TextStyle(color: c.textPri, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('v1.1.0 · Powered by NVIDIA NIM', style: TextStyle(color: c.textSec, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Free, unlimited tokens, no subscription', style: TextStyle(color: c.textDim, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              child: const Text('Clear All Data & Reset'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: TextStyle(
      color: context.colors.textDim, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .08,
    )),
  );
}
