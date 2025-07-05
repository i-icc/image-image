class CompressionSettings {
  final int quality;
  final int colorCount;
  final bool overwrite;
  final String outputPrefix;

  const CompressionSettings({
    this.quality = 80,
    this.colorCount = 256,
    this.overwrite = true, // デフォルトをtrueに変更
    this.outputPrefix = 'compressed_',
  });

  CompressionSettings copyWith({
    int? quality,
    int? colorCount,
    bool? overwrite,
    String? outputPrefix,
  }) {
    return CompressionSettings(
      quality: quality ?? this.quality,
      colorCount: colorCount ?? this.colorCount,
      overwrite: overwrite ?? this.overwrite,
      outputPrefix: outputPrefix ?? this.outputPrefix,
    );
  }
}
