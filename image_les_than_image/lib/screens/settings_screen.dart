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
          height: 400,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '圧縮設定',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // 圧縮品質設定
                Text('圧縮品質: ${_settings.qualityMin}-${_settings.qualityMax}'),
                RangeSlider(
                  values: RangeValues(
                    _settings.qualityMin.toDouble(),
                    _settings.qualityMax.toDouble(),
                  ),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  labels: RangeLabels(
                    '${_settings.qualityMin}',
                    '${_settings.qualityMax}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _settings = _settings.copyWith(
                        qualityMin: values.start.round(),
                        qualityMax: values.end.round(),
                      );
                    });
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
                  onChanged: (value) {
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
    );
  }
}
