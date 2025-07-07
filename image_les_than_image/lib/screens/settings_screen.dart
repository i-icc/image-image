import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/compression_settings.dart';

class SettingsScreen extends StatefulWidget {
  final CompressionSettings settings;
  final Function(CompressionSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CompressionSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 600,
          height: 500,
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '圧縮設定',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // 圧縮品質設定
                  const Text(
                    '圧縮品質',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('品質: ${_settings.quality}'),
                  Slider(
                    value: _settings.quality.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${_settings.quality}',
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(quality: value.round());
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // 色数設定
                  const Text(
                    '色数',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _settings.colorCount,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2色')),
                      DropdownMenuItem(value: 4, child: Text('4色')),
                      DropdownMenuItem(value: 8, child: Text('8色')),
                      DropdownMenuItem(value: 16, child: Text('16色')),
                      DropdownMenuItem(value: 32, child: Text('32色')),
                      DropdownMenuItem(value: 64, child: Text('64色')),
                      DropdownMenuItem(value: 128, child: Text('128色')),
                      DropdownMenuItem(value: 256, child: Text('256色')),
                      DropdownMenuItem(value: -1, child: Text('減色なし')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(colorCount: value);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // 出力先設定
                  const Text(
                    '出力設定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // 上書き設定
                  SwitchListTile(
                    title: const Text('既存ファイルを上書き'),
                    value: _settings.overwrite,
                    onChanged: (value) async {
                      if (!value) {
                        // オフにしようとした場合はダイアログを表示し、状態を変更しない
                        await showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('お知らせ'),
                                content: const Text('今は使用できません！'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                        return;
                      }
                      // オンにする場合のみ状態を変更
                      setState(() {
                        _settings = _settings.copyWith(overwrite: value);
                      });
                    },
                  ),

                  // プレフィックス設定（上書きが無効な時のみ表示）
                  if (!_settings.overwrite)
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '出力ファイルプレフィックス',
                        hintText: 'compressed_',
                      ),
                      controller: TextEditingController(
                        text: _settings.outputPrefix,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(outputPrefix: value);
                        });
                      },
                    ),

                  const SizedBox(height: 32),

                  // 保存ボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          widget.onSettingsChanged(_settings);
                          Navigator.pop(context);
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
