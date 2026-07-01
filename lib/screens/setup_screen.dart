import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/nim_service.dart';
import '../services/key_service.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupScreen({super.key, required this.onComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _labelCtrl = TextEditingController(text: 'Personal');
  final _keyCtrl   = TextEditingController();
  bool  _loading = false;
  String _error  = '';
  bool  _obscure = true;

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please enter your API key');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final svc = NimService(apiKey: key);
    final ok  = await svc.testConnection();

    if (!ok) {
      setState(() {
        _loading = false;
        _error   = 'Could not connect. Check your key and internet.';
      });
      return;
    }

    final entry = await KeyService.add(
      label: _labelCtrl.text.trim().isEmpty ? 'Personal' : _labelCtrl.text.trim(),
      key: key,
    );
    await KeyService.setActive(entry.id);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.think],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 24),
                Text('Nemotron Code', style: TextStyle(color: c.textPri, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('AI coding agent · NVIDIA NIM · Free', style: TextStyle(color: c.textSec, fontSize: 13)),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KEY LABEL', style: TextStyle(color: c.textSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .08)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _labelCtrl,
                        style: TextStyle(color: c.textPri, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'e.g. Personal, Work'),
                      ),
                      const SizedBox(height: 16),
                      Text('NVIDIA API KEY', style: TextStyle(color: c.textSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .08)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: c.textPri, fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'nvapi-...',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: c.textDim, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 12),
                      Text('Get a free key at build.nvidia.com →', style: TextStyle(color: c.accent, fontSize: 12)),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.1),
                            border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Connect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('You can add more keys later in Settings', style: TextStyle(color: c.textDim, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
