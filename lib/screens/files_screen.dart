import 'dart:io';
import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../theme.dart';
import 'editor_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _currentPath = '';
  List<FileSystemEntity> _items = [];
  bool _loading = true;
  List<String> _pathStack = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await FileService.requestStoragePermission();
    final path = await FileService.getDefaultPath();
    setState(() => _currentPath = path);
    await _load(path);
  }

  Future<void> _load(String path) async {
    setState(() => _loading = true);
    final items = await FileService.listDir(path);
    setState(() {
      _items   = items;
      _loading = false;
    });
  }

  void _openDir(String path) {
    _pathStack.add(_currentPath);
    setState(() => _currentPath = path);
    _load(path);
  }

  void _goBack() {
    if (_pathStack.isEmpty) return;
    final prev = _pathStack.removeLast();
    setState(() => _currentPath = prev);
    _load(prev);
  }

  void _openFile(String path) {
    if (!FileService.isTextFile(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only text/code files can be opened')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(path: path)),
    );
  }

  Future<void> _newFile() async {
    final name = await _promptName('New file name');
    if (name == null || name.isEmpty) return;
    final path = '$_currentPath/$name';
    await FileService.writeFile(path, '');
    _load(_currentPath);
    if (mounted) _openFile(path);
  }

  Future<void> _newFolder() async {
    final name = await _promptName('New folder name');
    if (name == null || name.isEmpty) return;
    await FileService.createDir('$_currentPath/$name');
    _load(_currentPath);
  }

  Future<String?> _promptName(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: Text(title, style: const TextStyle(color: AppTheme.textPri, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPri),
          decoration: const InputDecoration(hintText: 'name.ext'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _delete(FileSystemEntity item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Delete?', style: TextStyle(color: AppTheme.textPri)),
        content: Text(FileService.fileName(item.path),
          style: const TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FileService.deleteEntity(item.path);
      _load(_currentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: Text(
          _currentPath.isEmpty ? 'Files' : FileService.fileName(_currentPath),
          overflow: TextOverflow.ellipsis,
        ),
        leading: _pathStack.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        actions: [
          IconButton(icon: const Icon(Icons.note_add_outlined), tooltip: 'New file', onPressed: _newFile),
          IconButton(icon: const Icon(Icons.create_new_folder_outlined), tooltip: 'New folder', onPressed: _newFolder),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _items.isEmpty
              ? const Center(
                  child: Text('Empty folder', style: TextStyle(color: AppTheme.textDim)),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item   = _items[i];
                    final isDir  = item is Directory;
                    final name   = FileService.fileName(item.path);
                    return ListTile(
                      leading: Icon(
                        isDir ? Icons.folder : _iconFor(name),
                        color: isDir ? AppTheme.accent : AppTheme.textSec,
                      ),
                      title: Text(name, style: const TextStyle(color: AppTheme.textPri, fontSize: 14)),
                      onTap: () => isDir ? _openDir(item.path) : _openFile(item.path),
                      onLongPress: () => _delete(item),
                      trailing: isDir
                          ? const Icon(Icons.chevron_right, color: AppTheme.textDim, size: 18)
                          : null,
                    );
                  },
                ),
    );
  }

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    const codeExts = {'py','js','ts','dart','java','kt','cpp','c','h','cs','go','rs'};
    if (codeExts.contains(ext)) return Icons.code;
    if (ext == 'md') return Icons.description_outlined;
    if (ext == 'json' || ext == 'yaml' || ext == 'yml') return Icons.data_object;
    return Icons.insert_drive_file_outlined;
  }
}
