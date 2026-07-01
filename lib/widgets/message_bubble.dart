import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import '../theme.dart';
import 'thinking_block.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _UserBubble(message) : _AIBubble(message);
  }
}

// ── USER ─────────────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final Message msg;
  const _UserBubble(this.msg);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.userBubble,
          border: Border.all(color: const Color(0xFF1A3050)),
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(16),
            topRight:    Radius.circular(16),
            bottomLeft:  Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          msg.content,
          style: const TextStyle(color: AppTheme.textPri, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

// ── AI ───────────────────────────────────────────────────────
class _AIBubble extends StatelessWidget {
  final Message msg;
  const _AIBubble(this.msg);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.think],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nemotron',
                style: TextStyle(
                  color: AppTheme.textSec,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (msg.isStreaming) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Thinking block
          if (msg.thinking.isNotEmpty)
            ThinkingBlock(
              text: msg.thinking,
              isStreaming: msg.isStreaming,
            ),

          // Content
          if (msg.content.isNotEmpty)
            _MarkdownContent(msg.content),
        ],
      ),
    );
  }
}

// ── MARKDOWN CONTENT ─────────────────────────────────────────
class _MarkdownContent extends StatelessWidget {
  final String text;
  const _MarkdownContent(this.text);

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p:          const TextStyle(color: AppTheme.textPri, fontSize: 14, height: 1.7),
        h1:         const TextStyle(color: AppTheme.textPri, fontSize: 20, fontWeight: FontWeight.w700),
        h2:         const TextStyle(color: AppTheme.textPri, fontSize: 17, fontWeight: FontWeight.w600),
        h3:         const TextStyle(color: AppTheme.accent,  fontSize: 15, fontWeight: FontWeight.w600),
        code:       const TextStyle(color: AppTheme.accent,  fontSize: 12.5, fontFamily: 'monospace', backgroundColor: Color(0x1A00C8FF)),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        blockquoteDecoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.accent, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        blockquote: const TextStyle(color: AppTheme.textSec, fontSize: 14),
        strong: const TextStyle(color: AppTheme.textPri, fontWeight: FontWeight.w600),
        em:     const TextStyle(color: Color(0xFF93C5FD)),
        a:      const TextStyle(color: AppTheme.accent),
        listBullet: const TextStyle(color: AppTheme.textSec),
        tableHead: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
        tableBody: const TextStyle(color: AppTheme.textPri),
        tableBorder: TableBorder.all(color: AppTheme.border),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      builders: {'code': _CodeBlockBuilder()},
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(element, preferredStyle) {
    if (element.tag != 'code') return null;
    final code = element.textContent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF1A2336),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('code', style: TextStyle(color: AppTheme.textDim, fontSize: 11, letterSpacing: .05)),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: code)),
                  child: const Text('Copy', style: TextStyle(color: AppTheme.textSec, fontSize: 11)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontFamily: 'monospace',
                fontSize: 12.5, height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
