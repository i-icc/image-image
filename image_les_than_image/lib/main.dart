import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dart:io';
import 'models/image_item.dart';
import 'models/compression_settings.dart';
import 'services/compression_service.dart';
import 'services/settings_service.dart';
import 'widgets/drop_zone.dart';
import 'widgets/image_list_item.dart';
import 'widgets/progress_indicator.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNGpng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<ImageItem> _images = [];
  bool _batchCompressing = false;
  CompressionSettings _settings = const CompressionSettings();
  double _overallProgress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.loadSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(CompressionSettings settings) async {
    await SettingsService.saveSettings(settings);
  }

  void _addImages(List<File> files) {
    setState(() {
      for (final file in files) {
        if (_images.any((item) => item.path == file.path)) continue;
        _images.add(ImageItem(file: file, originalSize: file.lengthSync()));
      }
    });
  }

  Future<void> _compressImage(int index) async {
    final item = _images[index];
    setState(() {
      item.status = CompressStatus.progress;
    });

    await CompressionService.compressImage(item, settings: _settings);
    setState(() {});
  }

  Future<void> _compressAll() async {
    setState(() {
      _batchCompressing = true;
      _overallProgress = 0.0;
    });

    final compressibleItems =
        _images
            .where(
              (item) =>
                  item.status == CompressStatus.waiting ||
                  item.status == CompressStatus.error,
            )
            .toList();

    for (int i = 0; i < compressibleItems.length; i++) {
      final item = compressibleItems[i];
      item.status = CompressStatus.progress;
      setState(() {});

      await CompressionService.compressImage(item, settings: _settings);

      setState(() {
        _overallProgress = (i + 1) / compressibleItems.length;
      });
    }

    setState(() {
      _batchCompressing = false;
      _overallProgress = 0.0;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              settings: _settings,
              onSettingsChanged: (settings) async {
                setState(() {
                  _settings = settings;
                });
                await _saveSettings(settings);
              },
            ),
      ),
    );
  }

  void _clearImages() {
    setState(() {
      _images.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: GlassmorphicContainer(
          width: 1000, // 幅をさらに拡大
          height: 700,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.blue.withOpacity(0.2),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.blueAccent.withOpacity(0.5),
            ],
          ),
          child: Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PNGpng',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      tooltip: '設定',
                    ),
                  ],
                ),
              ),

              // ドロップゾーン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropZone(onFilesDropped: _addImages),
              ),

              const SizedBox(height: 16),

              // 全体進捗表示
              if (_batchCompressing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AnimatedProgressIndicator(
                    progress: _overallProgress,
                    label: '全体進捗',
                    color: Colors.blueAccent,
                  ),
                ),

              const SizedBox(height: 16),

              // 操作ボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // クリアボタン
                    ElevatedButton.icon(
                      onPressed: _images.isNotEmpty ? _clearImages : null,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('一覧クリア'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.red[700],
                      ),
                    ),

                    // 圧縮ボタン
                    ElevatedButton.icon(
                      onPressed:
                          (_images.any(
                                    (e) =>
                                        e.status == CompressStatus.waiting ||
                                        e.status == CompressStatus.error,
                                  ) &&
                                  !_batchCompressing)
                              ? _compressAll
                              : null,
                      icon:
                          _batchCompressing
                              ? const CircularProgressWithIcon(
                                icon: Icons.compress,
                                color: Colors.white,
                                size: 16,
                              )
                              : const Icon(Icons.compress),
                      label:
                          _batchCompressing
                              ? const Text('圧縮中...')
                              : const Text('全画像一括圧縮'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 画像リスト
              Expanded(
                child:
                    _images.isEmpty
                        ? const Center(
                          child: Text(
                            '画像が追加されていません',
                            style: TextStyle(color: Colors.black45),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _images.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return ImageListItem(
                              item: _images[index],
                              onCompress: () => _compressImage(index),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
