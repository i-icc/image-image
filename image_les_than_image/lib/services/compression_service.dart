import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'dart:math';
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
        '圧縮設定: 品質=${compressionSettings.quality}, 色数=${compressionSettings.colorCount}',
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

      // ファイル拡張子を取得
      final extension = p.extension(item.file.path).toLowerCase();
      final isJpeg = extension == '.jpg' || extension == '.jpeg';

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

      // ファイル形式に応じて圧縮処理を選択
      Uint8List? compressedBytes;
      if (isJpeg) {
        compressedBytes = await _compressJpeg(image, compressionSettings);
      } else {
        compressedBytes = await _compressPng(image, compressionSettings);
      }

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

  static Future<Uint8List?> _compressJpeg(
    img.Image image,
    CompressionSettings settings,
  ) async {
    try {
      // JPEG品質を設定（1-100）
      final quality = settings.quality;

      // 減色なしの場合はそのまま
      img.Image optimizedImage = image;
      if (settings.colorCount != -1) {
        // 色数の削減（設定された色数に基づいて）
        optimizedImage = reduceColors(optimizedImage, settings.colorCount);
      }

      // JPEGエンコード
      final compressedBytes = img.encodeJpg(optimizedImage, quality: quality);

      return compressedBytes;
    } catch (e) {
      print('JPEG圧縮エラー: $e');
      return null;
    }
  }

  static Future<Uint8List?> _compressPng(
    img.Image image,
    CompressionSettings settings,
  ) async {
    try {
      // 品質設定に基づいて圧縮
      final quality = settings.quality.toDouble();

      // 減色なしの場合はそのまま
      img.Image optimizedImage = image;
      if (settings.colorCount != -1) {
        // 透明度の有無を確認
        final hasAlpha = hasTransparency(image);
        print('透明度チェック: $hasAlpha');
        // 色数の削減（透明度を考慮）
        if (hasAlpha) {
          optimizedImage = reduceColorsWithTransparency(
            image,
            settings.colorCount,
          );
          print('透明度保持減色処理を実行');
        } else {
          optimizedImage = reduceColors(image, settings.colorCount);
          print('通常の減色処理を実行');
        }
        // 透明度の最適化
        if (hasAlpha) {
          optimizedImage = optimizeTransparency(optimizedImage);
        }
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

  static img.Image reduceColors(img.Image image, int colorCount) {
    // 設定された色数でパレット化
    return img.quantize(
      image,
      numberOfColors: colorCount,
      method: img.QuantizeMethod.neuralNet,
    );
  }

  /// 透明度を保持しながら色数を減らす独自実装
  static img.Image reduceColorsWithTransparency(
    img.Image image,
    int colorCount,
  ) {
    try {
      // 透明ピクセルと不透明ピクセルを分離
      final transparentPixels = <int, int>{};
      final opaquePixels = <int, int>{};

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final key = y * image.width + x;

          if (pixel.a < 128) {
            // 半透明以下は透明として扱う
            transparentPixels[key] = pixel.a.toInt();
          } else {
            opaquePixels[key] = pixel.a.toInt();
          }
        }
      }

      print('透明ピクセル数: ${transparentPixels.length}');
      print('不透明ピクセル数: ${opaquePixels.length}');

      // 不透明部分のみを減色処理
      if (opaquePixels.isEmpty) {
        // 全て透明の場合はそのまま返す
        return image;
      }

      // 不透明部分の一時的な画像を作成
      final tempImage = img.Image(
        width: image.width,
        height: image.height,
        format: img.Format.uint8,
        numChannels: 4,
      );

      // 不透明ピクセルのみをコピー
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (pixel.a >= 128) {
            tempImage.setPixel(x, y, pixel);
          } else {
            // 透明部分は白で埋める（減色処理用）
            tempImage.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
          }
        }
      }

      // 不透明部分を減色
      final quantizedImage = img.quantize(
        tempImage,
        numberOfColors: colorCount,
        method: img.QuantizeMethod.neuralNet,
      );

      // 結果画像を作成
      final resultImage = img.Image(
        width: image.width,
        height: image.height,
        format: img.Format.uint8,
        numChannels: 4,
      );

      // 減色された不透明部分と元の透明部分を合成
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final originalPixel = image.getPixel(x, y);

          if (originalPixel.a < 128) {
            // 透明部分は元のピクセルを使用
            resultImage.setPixel(x, y, originalPixel);
          } else {
            // 不透明部分は減色されたピクセルを使用（アルファ値は元のまま）
            final quantizedPixel = quantizedImage.getPixel(x, y);
            resultImage.setPixel(
              x,
              y,
              img.ColorRgba8(
                quantizedPixel.r.toInt(),
                quantizedPixel.g.toInt(),
                quantizedPixel.b.toInt(),
                originalPixel.a.toInt(),
              ),
            );
          }
        }
      }

      return resultImage;
    } catch (e) {
      print('透明度保持減色エラー: $e');
      // エラーが発生した場合は元の画像を返す
      return image;
    }
  }

  /// K-means法による色数削減（透明度保持版）
  static img.Image reduceColorsKMeans(img.Image image, int colorCount) {
    try {
      // 不透明ピクセルの色を収集
      final colors = <List<int>>[];
      final pixelPositions = <List<int>>[];

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (pixel.a >= 128) {
            // 半透明以上の場合のみ
            colors.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
            pixelPositions.add([x, y]);
          }
        }
      }

      if (colors.isEmpty) {
        return image;
      }

      // K-means クラスタリング
      final clusters = _kMeansCluster(colors, min(colorCount, colors.length));

      // クラスタの代表色を計算
      final representativeColors = <List<int>>[];
      for (final cluster in clusters) {
        if (cluster.isEmpty) continue;

        int r = 0, g = 0, b = 0;
        for (final color in cluster) {
          r += color[0];
          g += color[1];
          b += color[2];
        }
        representativeColors.add([
          r ~/ cluster.length,
          g ~/ cluster.length,
          b ~/ cluster.length,
        ]);
      }

      // 結果画像を作成
      final resultImage = img.Image(
        width: image.width,
        height: image.height,
        format: img.Format.uint8,
        numChannels: 4,
      );

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final originalPixel = image.getPixel(x, y);

          if (originalPixel.a < 128) {
            // 透明部分はそのまま
            resultImage.setPixel(x, y, originalPixel);
          } else {
            // 最も近い代表色を見つける
            final nearestColor = _findNearestColor([
              originalPixel.r.toInt(),
              originalPixel.g.toInt(),
              originalPixel.b.toInt(),
            ], representativeColors);

            resultImage.setPixel(
              x,
              y,
              img.ColorRgba8(
                nearestColor[0],
                nearestColor[1],
                nearestColor[2],
                originalPixel.a.toInt(),
              ),
            );
          }
        }
      }

      return resultImage;
    } catch (e) {
      print('K-means減色エラー: $e');
      return image;
    }
  }

  /// K-meansクラスタリング
  static List<List<List<int>>> _kMeansCluster(List<List<int>> colors, int k) {
    if (colors.length <= k) {
      return colors.map((color) => [color]).toList();
    }

    final random = Random();

    // 初期クラスタ中心を選択
    final centers = <List<int>>[];
    for (int i = 0; i < k; i++) {
      centers.add(colors[random.nextInt(colors.length)]);
    }

    List<List<List<int>>> clusters = [];

    // 反復処理
    for (int iteration = 0; iteration < 20; iteration++) {
      // クラスタを初期化
      clusters = List.generate(k, (index) => <List<int>>[]);

      // 各色を最も近いクラスタに割り当て
      for (final color in colors) {
        int nearestIndex = 0;
        double minDistance = double.infinity;

        for (int i = 0; i < centers.length; i++) {
          final distance = _colorDistance(color, centers[i]);
          if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
          }
        }

        clusters[nearestIndex].add(color);
      }

      // 新しいクラスタ中心を計算
      bool changed = false;
      for (int i = 0; i < centers.length; i++) {
        if (clusters[i].isEmpty) continue;

        int r = 0, g = 0, b = 0;
        for (final color in clusters[i]) {
          r += color[0];
          g += color[1];
          b += color[2];
        }

        final newCenter = [
          r ~/ clusters[i].length,
          g ~/ clusters[i].length,
          b ~/ clusters[i].length,
        ];

        if (_colorDistance(centers[i], newCenter) > 1.0) {
          centers[i] = newCenter;
          changed = true;
        }
      }

      if (!changed) break;
    }

    return clusters;
  }

  /// 色同士の距離を計算
  static double _colorDistance(List<int> color1, List<int> color2) {
    final dr = color1[0] - color2[0];
    final dg = color1[1] - color2[1];
    final db = color1[2] - color2[2];
    return sqrt(dr * dr + dg * dg + db * db);
  }

  /// 最も近い色を見つける
  static List<int> _findNearestColor(List<int> color, List<List<int>> palette) {
    List<int> nearest = palette[0];
    double minDistance = _colorDistance(color, nearest);

    for (int i = 1; i < palette.length; i++) {
      final distance = _colorDistance(color, palette[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = palette[i];
      }
    }

    return nearest;
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
