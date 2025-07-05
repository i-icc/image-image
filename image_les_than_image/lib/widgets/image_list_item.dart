import 'package:flutter/material.dart';
import 'dart:io';
import '../models/image_item.dart';
import 'image_preview_dialog.dart';

class ImageListItem extends StatelessWidget {
  final ImageItem item;
  final VoidCallback? onCompress;

  const ImageListItem({super.key, required this.item, this.onCompress});

  void _showImagePreview(BuildContext context, bool showCompressed) {
    showDialog(
      context: context,
      builder:
          (context) =>
              ImagePreviewDialog(item: item, showCompressed: showCompressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    // デバッグ情報を出力
    if (item.hasCompressedFile) {
      print('=== 圧縮後画像情報 ===');
      print('圧縮後ファイルパス: ${item.compressedFilePath}');
      print('ファイル存在: ${item.hasCompressedFile}');
      print('ファイルサイズ: ${item.compressedFile?.lengthSync()} bytes');
    }

    return ListTile(
      leading: SizedBox(
        width: 120, // 幅を拡大して2つの画像を表示
        height: 60,
        child: Row(
          children: [
            // 元画像プレビュー
            Expanded(
              child: GestureDetector(
                onTap: () => _showImagePreview(context, false),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      item.file,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('元画像読み込みエラー: $error');
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 圧縮後画像プレビュー（存在する場合のみ）
            if (item.hasCompressedFile)
              Expanded(
                child: GestureDetector(
                  onTap: () => _showImagePreview(context, true),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        item.compressedFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('圧縮後画像読み込みエラー: $error');
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(item.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.path,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(item.status.icon, color: item.status.color, size: 16),
              const SizedBox(width: 4),
              Text(
                item.status.label,
                style: TextStyle(color: item.status.color, fontSize: 12),
              ),
              if (item.hasCompressedFile) ...[
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                const Text(
                  '元',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                const Text(
                  '圧縮後',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: SizedBox(
        width: 120, // 固定幅でオーバーフローを防ぐ
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.originalSize != null)
                    Text(
                      '元: ${(item.originalSize! / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.compressedSize != null)
                    Text(
                      '圧縮後: ${(item.compressedSize! / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.compressionRate != null)
                    Text(
                      '圧縮率: ${(item.compressionRate! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.status == CompressStatus.waiting ||
                item.status == CompressStatus.error)
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onCompress,
                  child: const Text('圧縮', style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
