import 'package:flutter/material.dart';
import '../theme.dart';

class ThinkingBlock extends StatefulWidget {
  final String text;
  final bool   isStreaming;
  const ThinkingBlock({super.key, required this.text, this.isStreaming = false});

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.trim().split(RegExp(r'\s+')).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.thinkDim,
        border: Border.all(color: AppTheme.think.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  // Pulsing dot
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.think.withOpacity(
                          widget.isStreaming
                              ? 0.4 + 0.6 * _pulse.value
                              : 1.0,
                        ),
                        boxShadow: [BoxShadow(
                          color: AppTheme.think.withOpacity(0.4),
                          blurRadius: 6,
                        )],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isStreaming
                        ? 'Reasoning…'
                        : 'Reasoning · $words words',
                    style: const TextStyle(
                      color: AppTheme.think,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.think, size: 18,
                  ),
                ],
              ),
            ),
          ),
          // ── Body ────────────────────────────────────────
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
