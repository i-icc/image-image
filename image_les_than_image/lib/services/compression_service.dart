import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../models/image_item.dart';
import '../models/compression_settings.dart';

class CompressionService {
  static Future<void> compressImage(
    ImageItem item, {
    CompressionSettings? settings,
  }) async {
    final compressionSettings = settings ?? const CompressionSettings();

    try {
      print('=== 圧縮開始 ===');
      print('元ファイル: ${item.file.path}');
      print(
        '圧縮設定: ${compressionSettings.qualityMin}-${compressionSettings.qualityMax}',
      );
      print('上書き設定: ${compressionSettings.overwrite}');

      // 元画像を読み込み
      final bytes = await item.file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        print('画像のデコードに失敗しました');
        item.status = CompressStatus.error;
        return;
      }

      print('画像サイズ: ${image.width}x${image.height}');

      // 出力ファイルパスを決定
      final dir = item.file.parent;
      String outPath;

      if (compressionSettings.overwrite) {
        // 上書きの場合：元のファイル名を使用
        outPath = p.join(dir.path, item.name);
      } else {
        // 上書きしない場合：プレフィックス付きのファイル名を使用
        outPath = p.join(
          dir.path,
          '${compressionSettings.outputPrefix}${item.name}',
        );
      }

      print('出力ファイル: $outPath');

      // PNG圧縮処理
      final compressedBytes = await _compressPng(image, compressionSettings);

      if (compressedBytes != null) {
        // 圧縮後のファイルを保存
        final compressedFile = File(outPath);
        await compressedFile.writeAsBytes(compressedBytes);

        final compressedSize = compressedBytes.length;
        final rate = 1 - (compressedSize / (item.originalSize ?? 1));

        print('=== 圧縮成功 ===');
        print('圧縮後ファイルサイズ: $compressedSize bytes');
        print('圧縮率: ${(rate * 100).toStringAsFixed(1)}%');

        item.compressedSize = compressedSize;
        item.compressionRate = rate;
        item.compressedFilePath = outPath;
        item.status = CompressStatus.done;
      } else {
        print('=== 圧縮失敗 ===');
        item.status = CompressStatus.error;
      }
    } catch (e) {
      print('=== 圧縮エラー ===');
      print('エラー内容: $e');
      item.status = CompressStatus.error;
    }
  }

  static Future<Uint8List?> _compressPng(
    img.Image image,
    CompressionSettings settings,
  ) async {
    try {
      // 品質設定に基づいて圧縮
      final quality = (settings.qualityMin + settings.qualityMax) / 2;

      // 画像の最適化
      img.Image optimizedImage = image;

      // 透明度の最適化
      if (hasTransparency(image)) {
        optimizedImage = optimizeTransparency(image);
      }

      // 色数の削減（品質に応じて）
      if (quality < 80) {
        optimizedImage = reduceColors(optimizedImage, quality);
      }

      // PNGエンコード（圧縮レベルを調整）
      final compressedBytes = img.encodePng(
        optimizedImage,
        level: _getCompressionLevel(quality),
      );

      return compressedBytes;
    } catch (e) {
      print('PNG圧縮エラー: $e');
      return null;
    }
  }

  static bool hasTransparency(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Pixel型のアルファ値を取得
        if (pixel.a < 255) {
          return true;
        }
      }
    }
    return false;
  }

  static img.Image optimizeTransparency(img.Image image) {
    // 透明度の最適化（現状はそのまま返す）
    return image;
  }

  static img.Image reduceColors(img.Image image, double quality) {
    // 品質に応じて色数を削減
    final maxColors =
        quality < 60
            ? 64
            : quality < 80
            ? 128
            : 256;

    // パレット化（imageパッケージの正しいAPIを使用）
    return img.quantize(image, numberOfColors: maxColors);
  }

  static int _getCompressionLevel(double quality) {
    // 品質を圧縮レベルに変換（0-9、9が最高圧縮）
    if (quality >= 90) return 0;
    if (quality >= 80) return 2;
    if (quality >= 70) return 4;
    if (quality >= 60) return 6;
    if (quality >= 50) return 7;
    return 8;
  }

  static Future<void> compressAll(
    List<ImageItem> images, {
    CompressionSettings? settings,
  }) async {
    for (final item in images) {
      if (item.status == CompressStatus.waiting ||
          item.status == CompressStatus.error) {
        item.status = CompressStatus.progress;
        await compressImage(item, settings: settings);
      }
    }
  }
}
