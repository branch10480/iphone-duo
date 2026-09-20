# iPhone Duo サンプルアプリ —— 引き継ぎ書（2026-09-20）

リサーチセッションの引き継ぎ書。**サンプルアプリを作るセッションはこれを先に読む。**

## このセッションでやったこと（完了）

- `~/ghq/github.com/branch10480/iphone-duo/` で**ローカル git リポジトリ**を作成（commit `53ddf90`、18 ファイル）
  - **gh ではリポジトリ作成できず**（sandbox が `~/.config/gh` を拒否＋network deny。gh は認証もネットワークも使えない）。`ghq` の配置規則どおりのパスに置いたので、push するだけであの場所になる
- 調査結果を `docs/iphone-duo-support.md`（主ドキュメント）にまとめた
  - 根拠は二系統:【web】Apple 公式 Tech Talk 111461–66 全文・Newsroom・仕様ページ（verify で独立検証済み）／【SDK】この Mac の Xcode 27.1（27A9269）の iOS 27.1 SDK ヘッダ実読（27.0↔27.1 差分を全取得）
- SDK 一次資料を `artifacts/ios27.1-sdk/` に保存（ヘッダ原本＋27.0→27.1 差分）
- **リモートリポジトリ作成＋ push 完了**（2026-09-20）:
  - `gh repo create iphone-duo --public` で https://github.com/branch10480/iphone-duo を作成（`--source`/`--push` は seed の gh allowlist の `GH_BLOCKED_FLAGS` にあって専用 profile 外 → 使えない）
  - push は seed の git-network 転送（単独 `git push -u origin main`）で実行済み。remote `origin`、upstream `main`、リモート default branch = main

## 未完了（次のセッションでやる前 / 中の作業）

1. **サンプルアプリ本体の作成** —— ここからが次のセッションの本体。要件は `docs/iphone-duo-support.md` §6 のチェックリスト（14 項目）。
2. **内側ディスプレイの論理解像度をシミュレータ実測** —— 推測で残っている唯一の数字（§2、要実機確認の 1 つ）。

## 次のセッションの注意点（ハマり所）

- **この Mac に 2 つの Xcode がある。** `xcode-select` の既定は `/Applications/Xcode_27_1.app`（Duo 対応）。**`/Applications/Xcode.app`（27.0、Duo 非対応）を見て API を「無い」と結論しない。** SDK パスは必ず `Xcode_27_1.app` 配下。
- **シミュレータは 2 台ある**（iOS 27.1 ランタイム）:
  - `6B8C075B-0655-4C20-9CAD-ACB1A97B5EEC`（Booted、9/19 使用済）
  - `0F5B43CE-FEEC-4388-8DEA-50866D9AB922`（Shutdown）
  - 初回シミュレータ起動に数分かかる（Known Issue）
- **シミュレータの既知の問題**: StandBy 不可、アプリエクステンション大半が実行・デバッグ不可 → その辺の機能は実機テスト
- **利用可アノテーション**: Hinge/Arrangement/ReservedRegion 系は `ios/tvos/visionos 27.1`（watchOS 不可）。**バー軸の個別値（horizontalOnly 等）と `UIVerticalBarEdge.leading/.trailing` は iOS 限定**。deployment target 27.1 か `@available(iOS 27.1, *)` でガード
- **Mac Catalyst**: iOS 27.1 専用 API でコンパイルエラー・実行先が消える → `#if !targetEnvironment(macCatalyst)` でガード（アプリが Mac にも出す場合）
- 内側ディスプレイの `size class` は **regular×regular**、**`supportedInterfaceOrientations` に従わない**（orientation 判定を size class に置換）
- ヒンジデータ（angle/status）は**インタラクション用**。レイアウトは Arrangement / Reserved Region（混同しない）
- Apple の HIG「Designing for iPhone Duo」は JS 描画ページで browser_read が落ちる（ProfileSingleton 競合の兆候）→ 読めなくても Tech Talk 111466 の内容で十分（§4.4 等にも設計ルールがある）
- **push は seed の git-network 転送を使う**（単独 `git push -u origin main`。shell 構文を付けると素の sandbox network deny に落ちる）。`gh repo create --source`/`--push` は allowlist 外で使えない

## API 早見（詳細・コード例は docs/iphone-duo-support.md §4）

| 群 | SwiftUI | UIKit |
|---|---|---|
| ヒンジ | `.onHingeChange { _, ctx in }`（`DeviceHinge.status/.angle`） | `UIHingeInteraction` + `UIHinge.status/.angle` |
| 2 面レイアウト | `ArrangementView` + `.arrangementViewStyle(.split/.overlay)`、`\.overlayArrangementZIndex` | `UIArrangementViewController` + `UISplitArrangement`/`UIOverlayArrangement` |
| 折り目・カメラ | `GeometryProxy.reservedRegions(kind:options:)`（`.division`/`.occlusion`） | `UIView.reservedRegions(ofKind:)` |
| 縦バー | `.toolbarVerticalBehavior(.disabled)` 等 | `preferredVerticalBarBehavior`、`axisBehavior`、`verticalBarEdge` |
| 複数ディスプレイ | `CameraCaptureAccessory` + `.sceneAccessory`、`.onAvailabilityChange` | `UISceneAccessory.cameraCapture(...)`、`UIWindowSceneActivationAction` |
| カメラ方向 | — | `AVCaptureDeviceDirectionCoordinator`（`builtInOuter/InnerUltraWideCamera`） |
