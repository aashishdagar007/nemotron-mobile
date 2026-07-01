import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/nim_service.dart';
import 'services/key_service.dart';
import 'services/theme_controller.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const NemotronApp());
}

class NemotronApp extends StatefulWidget {
  const NemotronApp({super.key});
  @override
  State<NemotronApp> createState() => _NemotronAppState();
}

class _NemotronAppState extends State<NemotronApp> {
  bool _loading = true;
  NimService? _nim;

  @override
  void initState() {
    super.initState();
    _loadActiveKey();
  }

  Future<void> _loadActiveKey() async {
    final active = await KeyService.getActive();
    setState(() {
      _nim     = active != null ? NimService(apiKey: active.key) : null;
      _loading = false;
    });
  }

  void _onSetupComplete()    => _loadActiveKey();
  void _onKeyCleared()       => setState(() { _nim = null; });
  void _onActiveKeyChanged() => _loadActiveKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, __) => MaterialApp(
        title: 'Nemotron Code',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _loading
            ? Scaffold(
                backgroundColor: AppTheme.bgDeep,
                body: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
              )
            : (_nim == null
                ? SetupScreen(onComplete: _onSetupComplete)
                : HomeScreen(
                    nim: _nim!,
                    onKeyCleared: _onKeyCleared,
                    onActiveKeyChanged: _onActiveKeyChanged,
                  )),
      ),
    );
  }
}
