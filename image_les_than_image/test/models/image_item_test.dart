
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_les_than_image/models/image_item.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ImageItem', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_item_test');
      testFile = File(p.join(tempDir.path, 'test_image.png'));
      await testFile.writeAsString('test content');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('プロパティが正しく取得できるか', () {
      final imageItem = ImageItem(file: testFile);
      expect(imageItem.name, 'test_image.png');
      expect(imageItem.path, testFile.path);
    });

    test('圧縮後のファイルが存在するかどうかの判定が正しいか', () async {
      final imageItem = ImageItem(file: testFile);
      expect(imageItem.hasCompressedFile, false);

      final compressedFilePath = p.join(tempDir.path, 'compressed_test_image.png');
      final compressedFile = File(compressedFilePath);
      await compressedFile.writeAsString('compressed content');

      imageItem.compressedFilePath = compressedFilePath;
      expect(imageItem.hasCompressedFile, true);
    });
  });
}
