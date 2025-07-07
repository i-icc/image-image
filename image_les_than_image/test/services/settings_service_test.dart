
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_les_than_image/models/compression_settings.dart';
import 'package:image_les_than_image/services/settings_service.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  group('SettingsService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('settings_service_test');
      getApplicationDocumentsDirectory.setMockPath(tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('設定の保存と読み込みが正しく行えるか', () async {
      const settings = CompressionSettings(
        quality: 90,
        colorCount: 128,
        overwrite: false,
        outputPrefix: 'prefix_',
      );

      await SettingsService.saveSettings(settings);
      final loadedSettings = await SettingsService.loadSettings();

      expect(loadedSettings.quality, 90);
      expect(loadedSettings.colorCount, 128);
      expect(loadedSettings.overwrite, false);
      expect(loadedSettings.outputPrefix, 'prefix_');
    });

    test('設定ファイルが存在しない場合にデフォルト設定が読み込まれるか', () async {
      final loadedSettings = await SettingsService.loadSettings();
      expect(loadedSettings.quality, 80);
      expect(loadedSettings.colorCount, 256);
      expect(loadedSettings.overwrite, true);
      expect(loadedSettings.outputPrefix, 'compressed_');
    });
  });
}

extension on Function {
  void setMockPath(String path) {
    TestWidgetsFlutterBinding.ensureInitialized();
    (this as dynamic)(path);
  }
}
