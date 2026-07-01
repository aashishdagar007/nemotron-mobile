import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {

  // ── PERMISSIONS ─────────────────────────────────────────
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      final legacy = await Permission.storage.request();
      return legacy.isGranted;
    }
    return true;
  }

  // ── BASE DIRECTORIES ────────────────────────────────────
  static Future<Directory> getDefaultDir() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }

  static Future<String> getDefaultPath() async {
    final dir = await getDefaultDir();
    return dir.path;
  }

  // ── LIST ────────────────────────────────────────────────
  static Future<List<FileSystemEntity>> listDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    final items = await dir.list().toList();
    items.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.path.compareTo(b.path);
    });
    return items;
  }

  // ── READ ─────────────────────────────────────────────────
  static Future<String> readFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 'ERROR: File not found';
      final size = await file.length();
      if (size > 500 * 1024) return 'ERROR: File too large (>500KB)';
      return await file.readAsString();
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  // ── WRITE ────────────────────────────────────────────────
  static Future<String> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return 'Saved: $path';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  // ── CREATE DIR ───────────────────────────────────────────
  static Future<String> createDir(String path) async {
    try {
      await Directory(path).create(recursive: true);
      return 'Created: $path';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  // ── DELETE ───────────────────────────────────────────────
  static Future<String> deleteEntity(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) { await f.delete(); return 'Deleted: $path'; }
      final d = Directory(path);
      if (await d.exists()) { await d.delete(recursive: true); return 'Deleted: $path'; }
      return 'ERROR: Not found';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  // ── PICK FILE ────────────────────────────────────────────
  static Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    return result?.files.single.path;
  }

  // ── HELPERS ──────────────────────────────────────────────
  static String fileName(String path) => path.split('/').last;
  static String parentPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 1) return path;
    parts.removeLast();
    return parts.join('/');
  }
  static bool isTextFile(String path) {
    const textExts = {
      '.txt', '.md', '.py', '.js', '.ts', '.dart', '.java',
      '.kt', '.cpp', '.c', '.h', '.cs', '.go', '.rs', '.rb',
      '.swift', '.json', '.yaml', '.yml', '.xml', '.html',
      '.css', '.sh', '.bat', '.env', '.toml', '.ini', '.cfg',
      '.gradle', '.sql', '.r', '.m', '.php', '.vue', '.jsx',
    };
    final ext = '.${path.split('.').last.toLowerCase()}';
    return textExts.contains(ext);
  }
}
