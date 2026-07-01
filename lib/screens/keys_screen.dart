import 'package:flutter/material.dart';
import '../models/api_key_entry.dart';
import '../services/key_service.dart';
import '../services/nim_service.dart';
import '../theme.dart';

class KeysScreen extends StatefulWidget {
  final NimService nim;
  final VoidCallback onActiveKeyChanged;
  const KeysScreen({super.key, required this.nim, required this.onActiveKeyChanged});

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  List<ApiKeyEntry> _keys = [];
  String? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final keys   = await KeyService.getAll();
    final active = await KeyService.getActive();
    setState(() {
      _keys     = keys;
      _activeId = active?.id;
      _loading  = false;
    });
  }

  Future<void> _addKey() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddKeyDialog(),
    );
    if (result == null) return;

    final label = result['label'] ?? '';
    final key   = result['key'] ?? '';
    if (key.isEmpty) return;

    // Test connection first
    final testSvc = NimService(apiKey: key);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FutureBuilder<bool>(
        future: testSvc.testConnection(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Dialog(
              backgroundColor: AppTheme.bgSurface,
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(width: 16),
                  Text('Testing key…', style: TextStyle(color: AppTheme.textPri)),
                ]),
              ),
            );
          }
          Future.microtask(() => Navigator.pop(ctx, snap.data));
          return const SizedBox.shrink();
        },
      ),
    );

    if (ok != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect with that key'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    final entry = await KeyService.add(label: label, key: key);
    await KeyService.setActive(entry.id);
    widget.nim.apiKey = entry.key;
    widget.onActiveKeyChanged();
    _load();
  }

  Future<void> _setActive(ApiKeyEntry entry) async {
    await KeyService.setActive(entry.id);
    widget.nim.apiKey = entry.key;
    widget.onActiveKeyChanged();
    setState(() => _activeId = entry.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Active key: ${entry.label}'), backgroundColor: AppTheme.success),
      );
    }
  }

  Future<void> _remove(ApiKeyEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Remove key?', style: TextStyle(color: AppTheme.textPri)),
        content: Text(entry.label, style: const TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await KeyService.remove(entry.id);
    final active = await KeyService.getActive();
    if (active != null) widget.nim.apiKey = active.key;
    widget.onActiveKeyChanged();
    _load();
  }

  Future<void> _rename(ApiKeyEntry entry) async {
    final ctrl = TextEditingController(text: entry.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Rename key', style: TextStyle(color: AppTheme.textPri)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPri),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
    if (newLabel == null || newLabel.isEmpty) return;
    await KeyService.rename(entry.id, newLabel);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('API Keys'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addKey),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _keys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_outlined, color: AppTheme.textDim, size: 40),
                      const SizedBox(height: 12),
                      const Text('No keys saved yet', style: TextStyle(color: AppTheme.textSec)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addKey,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add a key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent, foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _keys.length,
                  itemBuilder: (_, i) {
                    final entry    = _keys[i];
                    final isActive = entry.id == _activeId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accentDim : AppTheme.bgSurface,
                        border: Border.all(
                          color: isActive ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.accent.withOpacity(0.15) : AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isActive ? Icons.check_circle : Icons.vpn_key_outlined,
                              color: isActive ? AppTheme.accent : AppTheme.textDim,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(entry.label,
                                      style: const TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('ACTIVE',
                                          style: TextStyle(color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(entry.masked,
                                  style: const TextStyle(color: AppTheme.textSec, fontSize: 12, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: AppTheme.bgCard,
                            icon: const Icon(Icons.more_vert, color: AppTheme.textDim, size: 20),
                            onSelected: (v) {
                              if (v == 'use')    _setActive(entry);
                              if (v == 'rename') _rename(entry);
                              if (v == 'remove') _remove(entry);
                            },
                            itemBuilder: (_) => [
                              if (!isActive)
                                const PopupMenuItem(value: 'use', child: Text('Use this key', style: TextStyle(color: AppTheme.textPri))),
                              const PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AppTheme.textPri))),
                              const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppTheme.danger))),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ── ADD KEY DIALOG ────────────────────────────────────────────
class _AddKeyDialog extends StatefulWidget {
  const _AddKeyDialog();
  @override
  State<_AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<_AddKeyDialog> {
  final _labelCtrl = TextEditingController();
  final _keyCtrl   = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgSurface,
      title: const Text('Add API Key', style: TextStyle(color: AppTheme.textPri, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: AppTheme.textPri),
            decoration: const InputDecoration(hintText: 'Label (e.g. Personal, Work)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppTheme.textPri, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'nvapi-...',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: AppTheme.textDim),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'label': _labelCtrl.text.trim(),
            'key':   _keyCtrl.text.trim(),
          }),
          child: const Text('Add & Test', style: TextStyle(color: AppTheme.accent)),
        ),
      ],
    );
  }
}
