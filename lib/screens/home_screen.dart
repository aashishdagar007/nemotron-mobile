import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/nim_service.dart';
import 'chat_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';
import 'editor_screen.dart';
import 'device_control_screen.dart';

class HomeScreen extends StatefulWidget {
  final NimService nim;
  final VoidCallback onKeyCleared;
  final VoidCallback onActiveKeyChanged;
  const HomeScreen({
    super.key,
    required this.nim,
    required this.onKeyCleared,
    required this.onActiveKeyChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    NimServiceHolder.apiKey = widget.nim.apiKey;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(nim: widget.nim),
      DeviceControlScreen(nim: widget.nim),
      const FilesScreen(),
      SettingsScreen(
        nim: widget.nim,
        onKeyCleared: widget.onKeyCleared,
        onActiveKeyChanged: widget.onActiveKeyChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: context.colors.bgMain,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.touch_app_outlined), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
