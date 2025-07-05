class CompressionSettings {
  final int qualityMin;
  final int qualityMax;
  final bool overwrite;
  final String outputPrefix;

  const CompressionSettings({
    this.qualityMin = 65,
    this.qualityMax = 90,
    this.overwrite = true, // デフォルトをtrueに変更
    this.outputPrefix = 'compressed_',
  });

  CompressionSettings copyWith({
    int? qualityMin,
    int? qualityMax,
    bool? overwrite,
    String? outputPrefix,
  }) {
    return CompressionSettings(
      qualityMin: qualityMin ?? this.qualityMin,
      qualityMax: qualityMax ?? this.qualityMax,
      overwrite: overwrite ?? this.overwrite,
      outputPrefix: outputPrefix ?? this.outputPrefix,
    );
  }
}
