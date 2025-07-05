import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ImageItem {
  final File file;
  String get name => p.basename(file.path);
  String get path => file.path;
  int? originalSize;
  int? compressedSize;
  double? compressionRate;
  CompressStatus status;
  String? compressedFilePath; // 圧縮後のファイルパス

  ImageItem({
    required this.file,
    this.originalSize,
    this.compressedSize,
    this.compressionRate,
    this.status = CompressStatus.waiting,
    this.compressedFilePath,
  });

  // 圧縮後のファイルが存在するかチェック
  bool get hasCompressedFile =>
      compressedFilePath != null && File(compressedFilePath!).existsSync();

  // 圧縮後のファイルを取得
  File? get compressedFile =>
      hasCompressedFile ? File(compressedFilePath!) : null;
}

enum CompressStatus { waiting, progress, done, error }

extension CompressStatusExt on CompressStatus {
  String get label {
    switch (this) {
      case CompressStatus.waiting:
        return 'waiting';
      case CompressStatus.progress:
        return 'progress';
      case CompressStatus.done:
        return 'done';
      case CompressStatus.error:
        return 'error';
    }
  }

  Color get color {
    switch (this) {
      case CompressStatus.waiting:
        return Colors.orange;
      case CompressStatus.progress:
        return Colors.blueAccent;
      case CompressStatus.done:
        return Colors.green;
      case CompressStatus.error:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case CompressStatus.waiting:
        return Icons.hourglass_empty;
      case CompressStatus.progress:
        return Icons.autorenew;
      case CompressStatus.done:
        return Icons.check_circle_outline;
      case CompressStatus.error:
        return Icons.error_outline;
    }
  }
}
