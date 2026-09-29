# MY WORKOUT v4

## Web版: GitHub Pages
`web/` の5ファイルを、現在利用しているGitHub Pages Repositoryのルートへ差し替えてください。

追加・改善した機能:
- トレーニング中の日本語音声ガイド（開始、残り5/3/2/1秒、セット終了）
- セット中の回数カウンター
- 健康ダッシュボード（歩数、睡眠、摂取/活動エネルギー）
- 食事の簡易手入力
- v2/v3のlocalStorageデータ移行
- Apple Health連携のWeb-to-native受け口

## iPhoneネイティブ版
`ios/` にSwiftUI + WKWebView + HealthKitの橋渡しコードがあります。

GitHub Pages版だけではApple Healthを直接読めません。HealthKitはiOSネイティブアプリのHealthKit capabilityが必要です。XcodeでiOS Appを作り、`ContentView.swift` / `HealthKitBridge.swift` を追加し、HealthKit capabilityとInfo.plistの説明文を設定してください。

ネイティブ版はGitHub PagesのWeb UIを同じまま表示し、HealthKitから読み取ったデータをJavaScriptの `window.receiveHealthSummary(...)` に渡します。

## 今後の拡張
- HealthKitへのワークアウト書き込み
- ローカル通知によるトレーニングリマインド
- Apple Watch対応
- 食事目標と体重トレンドを合わせた日次フィードバック
