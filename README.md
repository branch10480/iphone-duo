# iphone-duo

iPhone Duo（Apple 初の折りたたみ iPhone、2026-09-09 発表 / 10-23 発売 / iOS 27.1）対応リサーチ。

- [`docs/iphone-duo-support.md`](docs/iphone-duo-support.md) — **対応に必要な情報と API（ヒンジ API 等）のまとめ**。主ドキュメント。
- [`artifacts/ios27.1-sdk/`](artifacts/ios27.1-sdk/) — ローカル Xcode 27.1（27A9269）の iOS 27.1 SDK から取得した一次資料。
  - `UIHinge.h` / `UIHingeInteraction.h` — ヒンジ API の本体
  - `UIArrangementViewController.h` / `UIOverlayArrangement.h` / `UISplitArrangement.h` — 2 面レイアウト
  - `UIViewReservedRegion.h` — 折り目・カメラの領域
  - `*.diff` — iOS 27.0 → 27.1 のヘッダ差分（27.1 で追加された部分）
  - `AVCaptureDeviceDirectionCoordinator.h` / `AVCaptureDevice-additions.diff` — 内外カメラの方向追跡

## 事実の二系統

- **【SDK】** = この Mac の Xcode 27.1 の SDK ヘッダを実読した一次情報（最も確実）
- **【web】** = Apple 公式 Tech Talk / newsroom / 仕様ページ等（各主張の末尾に URL）

次のステップ: サンプルアプリ（このリポジトリに Xcode プロジェクトを追加する予定）。
