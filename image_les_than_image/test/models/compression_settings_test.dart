
import 'package:flutter_test/flutter_test.dart';
import 'package:image_les_than_image/models/compression_settings.dart';

void main() {
  group('CompressionSettings', () {
    test('デフォルト値が正しく設定されているか', () {
      const settings = CompressionSettings();
      expect(settings.quality, 80);
      expect(settings.colorCount, 256);
      expect(settings.overwrite, true);
      expect(settings.outputPrefix, 'compressed_');
    });

    test('copyWithが正しく動作するか', () {
      const settings = CompressionSettings();
      final newSettings = settings.copyWith(
        quality: 90,
        colorCount: 128,
        overwrite: false,
        outputPrefix: 'prefix_',
      );

      expect(newSettings.quality, 90);
      expect(newSettings.colorCount, 128);
      expect(newSettings.overwrite, false);
      expect(newSettings.outputPrefix, 'prefix_');
    });
  });
}
