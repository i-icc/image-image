import 'package:flutter/material.dart';
import 'dart:io';
import '../models/image_item.dart';

class ImagePreviewDialog extends StatelessWidget {
  final ImageItem item;
  final bool showCompressed;

  const ImagePreviewDialog({
    super.key,
    required this.item,
    this.showCompressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final file = showCompressed ? item.compressedFile : item.file;
    final title = showCompressed ? '圧縮後: ${item.name}' : '元画像: ${item.name}';

    // デバッグ情報を出力
    print('=== プレビューダイアログ ===');
    print('表示モード: ${showCompressed ? "圧縮後" : "元画像"}');
    print('ファイルパス: ${file?.path}');
    print('ファイル存在: ${file?.existsSync()}');
    print('ファイルサイズ: ${file?.lengthSync()} bytes');

    if (file == null) {
      print('ファイルが見つかりません');
      return AlertDialog(
        title: Text(title),
        content: const Text('ファイルが見つかりません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // 画像表示エリア
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('プレビュー画像読み込みエラー: $error');
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '画像を読み込めませんでした',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 情報表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ファイルサイズ: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                  ),
                  if (showCompressed && item.compressionRate != null)
                    Text(
                      '圧縮率: ${(item.compressionRate! * 100).toStringAsFixed(1)}%',
                    ),
                  Text('パス: ${file.path}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
