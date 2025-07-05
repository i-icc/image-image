import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';

class DropZone extends StatefulWidget {
  final Function(List<File>) onFilesDropped;

  const DropZone({super.key, required this.onFilesDropped});

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _dragging = false;

  bool _isImageFile(String path) {
    final extension = path.toLowerCase();
    return extension.endsWith('.png') ||
        extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        widget.onFilesDropped(
          detail.files
              .where((f) => _isImageFile(f.path))
              .map((f) => File(f.path))
              .toList(),
        );
      },
      onDragEntered: (detail) {
        setState(() => _dragging = true);
      },
      onDragExited: (detail) {
        setState(() => _dragging = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 600,
        height: 120,
        decoration: BoxDecoration(
          color:
              _dragging
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _dragging ? Colors.blueAccent : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            'ここに画像ファイル（PNG/JPG）をドラッグ＆ドロップ',
            style: TextStyle(
              fontSize: 20,
              color: _dragging ? Colors.blueAccent : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
