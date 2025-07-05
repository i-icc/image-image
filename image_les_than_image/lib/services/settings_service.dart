import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/compression_settings.dart';

class SettingsService {
  static const String _settingsFileName = 'compression_settings.json';

  // 設定を保存
  static Future<void> saveSettings(CompressionSettings settings) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_settingsFileName');

      final settingsMap = {
        'quality': settings.quality,
        'colorCount': settings.colorCount,
        'overwrite': settings.overwrite,
        'outputPrefix': settings.outputPrefix,
      };

      await file.writeAsString(jsonEncode(settingsMap));
      print('設定を保存しました: ${file.path}');
    } catch (e) {
      print('設定の保存に失敗しました: $e');
    }
  }

  // 設定を読み込み
  static Future<CompressionSettings> loadSettings() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_settingsFileName');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final settingsMap = jsonDecode(jsonString) as Map<String, dynamic>;

        return CompressionSettings(
          quality: settingsMap['quality'] ?? 80,
          colorCount: settingsMap['colorCount'] ?? 256,
          overwrite: settingsMap['overwrite'] ?? true,
          outputPrefix: settingsMap['outputPrefix'] ?? 'compressed_',
        );
      }
    } catch (e) {
      print('設定の読み込みに失敗しました: $e');
    }

    // デフォルト設定を返す
    return const CompressionSettings();
  }
}
