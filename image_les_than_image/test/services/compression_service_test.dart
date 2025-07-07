
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_les_than_image/models/compression_settings.dart';
import 'package:image_les_than_image/models/image_item.dart';
import 'package:image_les_than_image/services/compression_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('CompressionService', () {
    late Directory tempDir;
    late File testImageFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('compression_service_test');
      testImageFile = File(p.join(tempDir.path, 'test_image.png'));

      // 1x1の透明なPNG画像を作成
      final image = img.Image(width: 1, height: 1);
      img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
      await testImageFile.writeAsBytes(img.encodePng(image));
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('PNG画像の圧縮が正しく行われるか', () async {
      final imageItem = ImageItem(file: testImageFile);
      await CompressionService.compressImage(imageItem);

      expect(imageItem.status, CompressStatus.done);
      expect(imageItem.compressedFilePath, isNotNull);
      expect(File(imageItem.compressedFilePath!).existsSync(), isTrue);
    });

    test('hasTransparencyが正しく動作するか', () {
      final transparentImage = img.Image(width: 1, height: 1);
      img.fill(transparentImage, color: img.ColorRgba8(0, 0, 0, 128));
      expect(CompressionService.hasTransparency(transparentImage), isTrue);

      final opaqueImage = img.Image(width: 1, height: 1);
      img.fill(opaqueImage, color: img.ColorRgba8(255, 255, 255, 255));
      expect(CompressionService.hasTransparency(opaqueImage), isFalse);
    });

    test('restoreTransparencyが正しく動作するか', () {
      final originalImage = img.Image(width: 2, height: 1);
      originalImage.setPixelRgba(0, 0, 255, 0, 0, 128); // 半透明
      originalImage.setPixelRgba(1, 0, 0, 255, 0, 255); // 不透明

      final modifiedImage = img.Image(width: 2, height: 1);
      modifiedImage.setPixelRgba(0, 0, 0, 0, 255, 255);
      modifiedImage.setPixelRgba(1, 0, 0, 0, 255, 255);

      final restoredImage =
          CompressionService.restoreTransparency(originalImage, modifiedImage);

      final pixel1 = restoredImage.getPixel(0, 0);
      final pixel2 = restoredImage.getPixel(1, 0);

      expect(pixel1.a, 128);
      expect(pixel2.a, 255);
    });
  });
}
