import 'package:flutter/material.dart';
import 'dart:io';
import '../models/image_item.dart';
import 'dart:typed_data';

class ImageListItem extends StatelessWidget {
  final ImageItem item;
  final VoidCallback? onCompress;

  const ImageListItem({super.key, required this.item, this.onCompress});

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                            '画像比較: ${item.name}',
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
                  // 画像比較エリア
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 元画像
                          Expanded(
                            child: _PreviewWithCheckerboard(
                              label: '元画像',
                              image: Image.file(item.file, fit: BoxFit.contain),
                            ),
                          ),
                          const VerticalDivider(width: 32),
                          // 圧縮後画像
                          Expanded(
                            child:
                                item.hasCompressedFile &&
                                        item.status == CompressStatus.done
                                    ? FutureBuilder<Uint8List>(
                                      future:
                                          item.compressedFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (!snapshot.hasData ||
                                            snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              '画像を読み込めませんでした',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          );
                                        }
                                        return _PreviewWithCheckerboard(
                                          label: '圧縮後',
                                          image: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                          ),
                                        );
                                      },
                                    )
                                    : Center(
                                      child: Text(
                                        '圧縮画像なし',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                          ),
                        ],
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
                          '元: ${(item.originalSize ?? item.file.lengthSync()) / 1024} KB',
                        ),
                        if (item.compressedSize != null)
                          Text(
                            '圧縮後: ${(item.compressedSize! / 1024).toStringAsFixed(1)} KB',
                          ),
                        if (item.compressionRate != null)
                          Text(
                            '圧縮率: ${(item.compressionRate! * 100).toStringAsFixed(1)}%',
                          ),
                        Text('パス: ${item.file.path}'),
                        if (item.compressedFilePath != null)
                          Text('圧縮後パス: ${item.compressedFilePath}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showImagePreview(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              item.file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
            ],
          ),
        ],
      ),
      trailing: SizedBox(
        width: 120,
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

// 画像の格子背景＋ラベル付きプレビューWidget
class _PreviewWithCheckerboard extends StatelessWidget {
  final String label;
  final Widget image;
  const _PreviewWithCheckerboard({required this.label, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _CheckerboardPainter()),
                Center(child: image),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 格子模様を描画するCustomPainter
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 16;
    final paint1 = Paint()..color = const Color(0xFFE0E0E0);
    final paint2 = Paint()..color = const Color(0xFFFFFFFF);
    for (int y = 0; y < size.height / squareSize; y++) {
      for (int x = 0; x < size.width / squareSize; x++) {
        final paint = (x + y) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
