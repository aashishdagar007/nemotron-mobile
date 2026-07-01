import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../models/api_key_entry.dart';
import '../services/nim_service.dart';
import '../services/chat_storage_service.dart';
import '../services/key_service.dart';
import '../theme.dart';
import '../widgets/message_bubble.dart';
import 'keys_screen.dart';

class ChatScreen extends StatefulWidget {
  final NimService nim;
  const ChatScreen({super.key, required this.nim});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  ChatSession _current = ChatSession(id: ChatStorageService.genId(), title: 'New Chat');
  List<ChatSession> _allChats = [];
  ApiKeyEntry? _activeKey;
  bool _isStreaming = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadActiveKey();
  }

  Future<void> _loadHistory() async {
    final chats = await ChatStorageService.getAll();
    setState(() {
      _allChats = chats;
      _loadingHistory = false;
    });
  }

  Future<void> _loadActiveKey() async {
    final key = await KeyService.getActive();
    setState(() => _activeKey = key);
  }

  // ── SEND ──────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isStreaming) return;
    _inputCtrl.clear();

    final userMsg = Message(role: Role.user, content: text);
    final aiMsg   = Message(role: Role.assistant, content: '', isStreaming: true);

    if (_current.messages.isEmpty) {
      _current.title = ChatStorageService.titleFromText(text);
    }

    setState(() {
      _current.messages.add(userMsg);
      _current.messages.add(aiMsg);
      _isStreaming = true;
    });
    _scrollToBottom();

    final history = _current.messages.where((m) => !m.isStreaming).toList();

    try {
      await for (final chunk in widget.nim.streamChat(
        history:     history,
        userMessage: text,
      )) {
        setState(() {
          if (chunk['type'] == 'think') {
            aiMsg.thinking += chunk['text']!;
          } else if (chunk['type'] == 'answer') {
            aiMsg.content += chunk['text']!;
          } else if (chunk['type'] == 'error') {
            aiMsg.content = '❌ ${chunk['text']}';
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => aiMsg.content = '❌ $e');
    }

    setState(() {
      aiMsg.isStreaming = false;
      _isStreaming      = false;
    });
    _scrollToBottom();

    await ChatStorageService.save(_current);
    _loadHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _newChat() {
    setState(() {
      _current = ChatSession(id: ChatStorageService.genId(), title: 'New Chat');
    });
    Navigator.of(context).maybePop();
  }

  void _openChat(ChatSession chat) {
    setState(() => _current = chat);
    Navigator.of(context).maybePop();
  }

  Future<void> _deleteChat(ChatSession chat) async {
    await ChatStorageService.delete(chat.id);
    if (_current.id == chat.id) {
      setState(() => _current = ChatSession(id: ChatStorageService.genId(), title: 'New Chat'));
    }
    _loadHistory();
  }

  void _sendStarter(String text) {
    _inputCtrl.text = text;
    _send();
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgMain,
      drawer: _HistoryDrawer(
        chats: _allChats,
        currentId: _current.id,
        loading: _loadingHistory,
        onNewChat: _newChat,
        onOpenChat: _openChat,
        onDeleteChat: _deleteChat,
      ),
      appBar: AppBar(
        title: const Text('⚡ Nemotron Code'),
        actions: [
          // Active key chip
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => KeysScreen(nim: widget.nim, onActiveKeyChanged: _loadActiveKey),
              ));
              _loadActiveKey();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.accentDim,
                border: Border.all(color: c.accent.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key, size: 11, color: c.accent),
                  const SizedBox(width: 4),
                  Text(
                    _activeKey?.label ?? 'No key',
                    style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // Model chip
          GestureDetector(
            onTap: _showModelPicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.bgCard,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _modelShortName(widget.nim.model),
                style: TextStyle(color: c.textSec, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.psychology, color: widget.nim.thinking ? c.think : c.textDim),
            tooltip: 'Toggle Reasoning',
            onPressed: () => setState(() => widget.nim.thinking = !widget.nim.thinking),
          ),
          IconButton(
            icon: Icon(Icons.add, color: c.textSec),
            tooltip: 'New Chat',
            onPressed: _newChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _current.messages.isEmpty
                ? _WelcomeView(onStarter: _sendStarter)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _current.messages.length,
                    itemBuilder: (_, i) => MessageBubble(message: _current.messages[i]),
                  ),
          ),
          _InputBar(controller: _inputCtrl, onSend: _send, isStreaming: _isStreaming),
        ],
      ),
    );
  }

  String _modelShortName(String model) {
    if (model.contains('super')) return 'Super';
    if (model.contains('ultra')) return 'Ultra';
    if (model.contains('nano'))  return 'Nano';
    return 'NIM';
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModelPicker(
        current: widget.nim.model,
        onSelect: (m) {
          setState(() => widget.nim.model = m);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── HISTORY DRAWER ───────────────────────────────────────────
class _HistoryDrawer extends StatelessWidget {
  final List<ChatSession> chats;
  final String currentId;
  final bool loading;
  final VoidCallback onNewChat;
  final void Function(ChatSession) onOpenChat;
  final void Function(ChatSession) onDeleteChat;

  const _HistoryDrawer({
    required this.chats, required this.currentId, required this.loading,
    required this.onNewChat, required this.onOpenChat, required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Drawer(
      backgroundColor: c.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.think]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('⚡', style: TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Text('Nemotron Code', style: TextStyle(color: c.textPri, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.accent.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('RECENT CHATS',
                  style: TextStyle(color: c.textDim, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .08)),
              ),
            ),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : chats.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No chats yet', style: TextStyle(color: c.textDim, fontSize: 12)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: chats.length,
                          itemBuilder: (_, i) {
                            final chat = chats[i];
                            final active = chat.id == currentId;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: active ? c.accentDim : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.chat_bubble_outline, size: 16,
                                  color: active ? c.accent : c.textDim),
                                title: Text(chat.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active ? c.accent : c.textPri,
                                    fontSize: 12.5,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, size: 16, color: c.textDim),
                                  onPressed: () => onDeleteChat(chat),
                                ),
                                onTap: () => onOpenChat(chat),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WELCOME ──────────────────────────────────────────────────
class _WelcomeView extends StatelessWidget {
  final void Function(String) onStarter;
  const _WelcomeView({required this.onStarter});

  static const _starters = [
    ('Explain WFP hooks', 'How Windows Filtering Platform intercepts traffic'),
    ('AMSI bypass methods', 'How malware evades antimalware scan interface'),
    ('Review my code', 'Paste code for analysis and improvements'),
    ('Security+ prep', 'Quiz me on exam domains'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0x2200C8FF), Color(0x227C3AED)]),
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: Text('🧠', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(height: 16),
            Text('Nemotron 3 Ultra',
              style: TextStyle(color: c.textPri, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('550B parameters · Free via NVIDIA NIM',
              style: TextStyle(color: c.textSec, fontSize: 13)),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: _starters.map((s) => _StarterCard(
                title: s.$1, sub: s.$2, onTap: () => onStarter(s.$1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  final String title, sub;
  final VoidCallback onTap;
  const _StarterCard({required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgSurface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: c.textPri, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: c.textSec, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── INPUT BAR ────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isStreaming;
  const _InputBar({required this.controller, required this.onSend, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: c.bgMain,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: c.textPri, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ask Nemotron anything…',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isStreaming ? null : onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: isStreaming ? null : const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF0090FF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                color: isStreaming ? c.bgCard : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isStreaming
                  ? Center(child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)))
                  : const Icon(Icons.send, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MODEL PICKER ─────────────────────────────────────────────
class _ModelPicker extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;
  const _ModelPicker({required this.current, required this.onSelect});

  static const _models = [
    ('super', 'nvidia/nemotron-3-super-120b-a12b', 'Best for coding · Fast'),
    ('ultra', 'nvidia/nemotron-3-ultra-550b-a55b', 'Deepest reasoning · Slower'),
    ('nano',  'nvidia/nemotron-3-nano-30b-a3b',   'Fastest responses'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Model', style: TextStyle(color: c.textPri, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._models.map((m) => ListTile(
            onTap: () => onSelect(m.$2),
            leading: Radio<String>(
              value: m.$2, groupValue: current,
              onChanged: (v) => onSelect(v!),
              activeColor: c.accent,
            ),
            title: Text(m.$1.toUpperCase(),
              style: TextStyle(color: current == m.$2 ? c.accent : c.textPri, fontWeight: FontWeight.w600)),
            subtitle: Text(m.$3, style: TextStyle(color: c.textSec, fontSize: 12)),
          )),
        ],
      ),
    );
  }
}
