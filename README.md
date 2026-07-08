# BoothWatch

Boothの「登録したアイテム／ショップだけ」を軽量に追跡するFlutterアプリ。
検索結果の巡回は行わず、ユーザーが手動登録したURLのみを対象にすることでBooth側への負荷を最小限に抑える設計。

対応OS: iOS / Android / Windows（Flutterの標準対応範囲）

## 特徴

- **手動登録制**: 商品ページ or ショップページのURLを貼るだけ
- **クールダウン制御**: 同一URLは30分以内なら再取得しない（`TrackedItem.canCheckNow`）
- **直列リフレッシュ**: 一括更新時も並列アクセスせず、800msの間隔を空けて1件ずつ取得
- **OGPタグ中心のパース**: `og:title`/`og:image`など比較的安定したメタ情報を優先。ページ構造の変更に強い
- **価格履歴・新着通知**: 価格が変わったら赤字表示、ショップの新着アイテムはバッジ表示
- **完全ローカル**: Hiveでデバイス内保存。サーバー不要

## セットアップ

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # Hive用アダプタ生成
flutter run
```

`build_runner`の実行で `lib/models/tracked_item.g.dart` が自動生成されます（このファイルは同梱していません）。

## 使い方（UI構成）

下部ナビゲーションは3つ: **Booth / アイテム / ショップ**（お気に入りタブは廃止）。

- **Boothタブ**が起点。中でBooth自体を閲覧でき、商品ページ/ショップページを開いている時だけ右下に「このページを登録」ボタンが出ます。
- **アイテム/ショップタブ**の一覧でカードをタップすると、Boothタブに切り替わり、そのURLがその場で開きます（外部ブラウザは起動しません）。

`add_item_screen.dart`（URL貼り付けによる手動登録画面）は現在どこからも遷移しない未使用ファイルとして残しています。必要なければ削除しても問題ありません。

## Booth表示タブについて

下部ナビゲーションの「Booth」タブでBooth自体を直接表示します。
- Android/iOS: `webview_flutter`
- Windows: `webview_windows`（WebView2ベース。**Microsoft Edge WebView2 Runtime**が必要です。Windows 11は標準搭載、Windows 10は未インストールなら[こちら](https://developer.microsoft.com/microsoft-edge/webview2/)から導入してください）

`webview_flutter`にはWindows公式実装が無い（2026年7月時点でも`flutter/flutter`のissueとしてリクエストされている状態）ため、Windowsのみ別パッケージで対応しています。

## Android向け追加設定

Android 11(API 30)以降のパッケージ可視性制限により、`url_launcher`で外部ブラウザを開く際に失敗することがあります。
`android_manifest_queries_snippet.xml`の内容を、`android/app/src/main/AndroidManifest.xml`の`<manifest>`直下（`<application>`タグと同階層）に追加してください。

## 未実装・今後の検討事項

- バックグラウンドでの自動更新（現状はアプリを開いて手動リフレッシュのみ。OS側のバックグラウンド実行制約もあるため要検討）
- ショップの新着アイテムの個別詳細表示（現状はID差分検知のみ）
- 価格グラフの可視化
- Boothの利用規約変更などに伴うパース失敗時のフォールバック強化

## 注意事項

Booth公式の検索/取得APIは存在しないため、本アプリはページのHTML/メタタグを解析する方式を取っています。
過度な頻度でのアクセスは避け、個人利用の範囲に留めてください。
