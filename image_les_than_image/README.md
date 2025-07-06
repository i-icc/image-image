# image_les_than_image
title: PNGpng
画像圧縮PCソフト。

## 仕様
* ドラッグ & ドロップで画像をポンポン指定できる
  * 簡単なマウス操作のみで複数のPNG形式の画像ファイルを一括で圧縮し、大幅なファイルサイズ削減を実現するツール
* 画像毎に表示する情報は下記
    * ファイル名
    * パス
    * 結果(waiting, progress, done)(アイコンとかを使う？)
    * サイズ
    * 圧縮後サイズ
    * 圧縮率
* 圧縮方法
    * 24bit/32bitフルカラーのPNGファイルを減色アルゴリズムを用いて8bitインデックスカラーに変換する
* デザインは glasmolizm を基本としたシンプルでモダンなデザイン

## 補足
`flutter` は `fvm flutter` で実行

## structure

```
image_les_than_image/
├── lib/
│   ├── main.dart                    # メインアプリケーション（エントリーポイント）
│   ├── models/
│   │   ├── image_item.dart         # 画像アイテムモデル・状態管理
│   │   └── compression_settings.dart # 圧縮設定モデル
│   ├── services/
│   │   └── compression_service.dart # 圧縮処理ロジック
│   ├── screens/
│   │   └── settings_screen.dart    # 設定画面
│   └── widgets/
│       ├── drop_zone.dart          # ドラッグ＆ドロップエリア
│       ├── image_list_item.dart    # 画像リストアイテム
│       └── progress_indicator.dart # プログレスインジケーター
├── macos/                          # macOS用ビルド関連
├── windows/                        # Windows用ビルド関連
├── linux/                          # Linux用ビルド関連
├── test/                           # テストコード
├── pubspec.yaml                    # 依存パッケージ・Flutter設定
├── README.md                       # このファイル
└── ...                             # その他Flutter標準ファイル
```

### アーキテクチャ

- **Models**: データ構造とビジネスロジック
- **Services**: 外部処理
- **Screens**: 画面全体のUI
- **Widgets**: 再利用可能なUIコンポーネント
- **Main**: アプリケーションのエントリーポイント