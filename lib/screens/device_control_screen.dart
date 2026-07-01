import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/device_control_service.dart';
import '../services/device_agent.dart';
import '../services/nim_service.dart';

class DeviceControlScreen extends StatefulWidget {
  final NimService nim;
  const DeviceControlScreen({super.key, required this.nim});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  bool _enabled = false;
  bool _checking = true;
  bool _running = false;
  final _instructionCtrl = TextEditingController();
  final List<_LogEntry> _log = [];
  final _scrollCtrl = ScrollController();
  DeviceAgent? _agent;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await DeviceControlService.isEnabled();
    setState(() { _enabled = ok; _checking = false; });
  }

  Future<void> _runTask() async {
    final instruction = _instructionCtrl.text.trim();
    if (instruction.isEmpty || _running) return;

    setState(() {
      _log.clear();
      _running = true;
    });

    _agent = DeviceAgent(widget.nim);

    await for (final step in _agent!.run(instruction)) {
      setState(() {
        _log.add(_LogEntry(step.type, step.message));
        if (step.type == AgentEvent.done || step.type == AgentEvent.error) {
          _running = false;
        }
      });
      _scrollToBottom();
    }

    setState(() => _running = false);
  }

  void _stopTask() {
    _agent?.stop();
    setState(() => _running = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgMain,
      appBar: AppBar(title: const Text('Device Control')),
      body: _checking
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : !_enabled
              ? _PermissionPrompt(onGranted: _check)
              : _AgentRunner(
                  enabled: _enabled,
                  running: _running,
                  log: _log,
                  scrollCtrl: _scrollCtrl,
                  instructionCtrl: _instructionCtrl,
                  onRun: _runTask,
                  onStop: _stopTask,
                ),
    );
  }
}

// ── PERMISSION PROMPT ────────────────────────────────────────
class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onGranted;
  const _PermissionPrompt({required this.onGranted});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.touch_app_outlined, color: AppTheme.danger, size: 30),
            ),
            const SizedBox(height: 20),
            Text('Accessibility Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPri, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'To tap, swipe, and type in other apps, Nemotron Code needs the Accessibility Service permission. This is the same permission used by screen readers and automation apps like Tasker.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSec, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⚠ Once enabled, this app can see screen content and simulate taps system-wide. Only enable this if you trust the source of this app.',
                style: TextStyle(color: AppTheme.danger.withOpacity(0.9), fontSize: 12, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await DeviceControlService.openAccessibilitySettings();
                },
                style: ElevatedButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.black),
                child: const Text('Open Accessibility Settings', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onGranted,
              child: Text("I've enabled it — Check again", style: TextStyle(color: c.textSec)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AGENT RUNNER ──────────────────────────────────────────────
class _AgentRunner extends StatelessWidget {
  final bool enabled, running;
  final List<_LogEntry> log;
  final ScrollController scrollCtrl;
  final TextEditingController instructionCtrl;
  final VoidCallback onRun, onStop;

  const _AgentRunner({
    required this.enabled, required this.running, required this.log,
    required this.scrollCtrl, required this.instructionCtrl,
    required this.onRun, required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 14),
            const SizedBox(width: 6),
            const Text('Accessibility enabled', style: TextStyle(color: AppTheme.success, fontSize: 12)),
          ]),
        ),

        Expanded(
          child: log.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Describe a task, e.g.\n"Open WhatsApp and send Mom a good morning message"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textDim, fontSize: 13),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: log.length,
                  itemBuilder: (_, i) => _LogTile(entry: log[i]),
                ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(color: c.bgMain, border: Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: instructionCtrl,
                  enabled: !running,
                  style: TextStyle(color: c.textPri, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'What should I do?'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: running ? onStop : onRun,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: running ? AppTheme.danger.withOpacity(0.15) : c.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    running ? Icons.stop : Icons.play_arrow,
                    color: running ? AppTheme.danger : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogEntry {
  final AgentEvent type;
  final String message;
  _LogEntry(this.type, this.message);
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Color color; IconData icon;
    switch (entry.type) {
      case AgentEvent.thinking: color = c.think; icon = Icons.psychology; break;
      case AgentEvent.action:   color = c.accent; icon = Icons.touch_app; break;
      case AgentEvent.done:     color = AppTheme.success; icon = Icons.check_circle; break;
      case AgentEvent.error:    color = AppTheme.danger; icon = Icons.error_outline; break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry.message, style: TextStyle(color: c.textPri, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
