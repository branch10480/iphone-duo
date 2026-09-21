# iPhone Duo サンプルアプリ —— 引き継ぎ書（2026-09-21 更新）

## 状態（2026-09-21 時点）

- **サンプルアプリ「DuoLab」は完成・ビルド成功・シミュレータ起動確認済み**。push も済み（remote `origin/main`）。
- §6 の 14 項目を網羅する 7タブ構成（Overview / Hinge / Two Pane / Regions / Bar / Scenes / UIKit）。
- iPhone Duo シミュレータ（iOS 27.1、`6B8C075B…`）で起動し全タブを巡回。クラッシュなし（`openWindow` 要求・UIKit デモ生成を含む）。

## このセッションでやったこと

1. **`@State` マクロ不解決の根本原因を特定・解消**
   - 症状: `SwiftUIMacros.StateMacro could not be found … swift-plugin-server produced malformed response`（`@State` 全箇所）。各コンパイル直前に `sandbox-exec: sandbox_apply: Operation not permitted` がログに出る。
   - 原因: seed の sandbox 内で xcodebuild がコンパイラ subprocess（`swift-plugin-server`）を `sandbox-exec` で spawn するのに失敗 → 外部マクロが解決できない。**アプリコードのバグではない**。
   - 解決: build setting `OTHER_SWIFT_FLAGS=-disable-sandbox`（swift-frontend の `-disable-sandbox` = subprocess sandbox を無効化）。素の swiftc での A/B プローブ（sandbox ON=FAIL / OFF=OK）で確定。xcb の `extraArgs` に恒久設定済み（`.xcodebuildmcp/config.yaml` に persist）。
   - 副産物: `-SWIFT_FLAGS=…` / `-GCC_SWIFT_FLAGS=…` は効かない（Swift コンパイルに渡らない）のは確認済み。`OTHER_SWIFT_FLAGS` が正。
2. **UIKitDemo.swift の本来のバグ修正**
   - `self.setNeedsLayout()`（`self` は UIViewController）→ `view.setNeedsLayout()`。
   - `UIHingeInteraction` の handler を保存プロパティの初期化子で持っていた → `self` が `() -> UIKitDemo` の thunk に解決（`'(UIKitDemo) -> () -> UIKitDemo' has no member 'hingeStatus'`）。`viewDidLoad` 内で生成する SDK doc の公式パターンに変更。
   - `navigationItem.rightBarButtonItems` は non-optional のため optional chaining なし（`navigationItem` は guaranteed-optional 変換で `UINavigationItem?` に見えるが、`rightBarButtonItems` 自体は optional 配列。`[item]` 直接代入で OK）。
   - `registerForTraitChanges(_ traits:handler:)` は generic（`Self.TraitChangeHandler<Self>`）→ クロージャ引数を `(env: UIViewController, previous: UITraitCollection)` と明示。
   - `AVCaptureDevice.DeviceType` の `builtInOuterUltraWideCamera` / `builtInInnerUltraWideCamera` は SDK 実読で存在確認（27.1 に追加）。
3. **その他のコード修正**
   - `HingeGlowView.intensity` の getter が 2 文なのに末尾式が返却されなかった → 明示 `return`。
   - `ToolbarItemGroup` の子に `ToolbarItem.axisBehavior(...)`（`some ToolbarContent`）を置くと group の `View` 制約を満たさない → 各 item を素の Button 化し **group 本体に** `axisBehavior(.verticalPreferred)` を付与（`axisBehavior` は `ToolbarContent` 拡張、ToolbarItem/ToolbarItemGroup が conform）。
4. **実機相当の動作確認**（sim `6B8C075B`、iOS 27.1）
   - 起動 OK、7タブ表示、UIKit タブ（`UIHingeInteraction` 生成＋trait 登録＋`AVCaptureDeviceDirectionCoordinator`）でクラッシュなし、`openWindow(id:"companion")` 要求後に生存（外側ディスプレイではサイレント無視の想定どおり）。
   - 注: seed の sandbox 内 `ps -p <pid>` は見かけ上 GONE になりうる（sandbox のプロセス表示制限）。生存確認は `pgrep -f DuoLab` を使う。

## 残作業（次のセッション）

1. **§6 の各ポーズを実際に観測する**: Device Hub で open/close/rotate/fold を切り替えて、`onHingeChange`（status/angle）の遷移・`ArrangementView` の split⇄overlay 切替・`reservedRegions` の幅変化を目視確認。現状は「起動してクラッシュしない」まで。
2. **内側ディスプレイの論理解像度をシミュレータ実測**（§2、推測で残っている唯一の数字）。OverviewPage に `displayScale` 表示があるので、シミュレータの Duo の内側表示で確認。
3. **StandBy・アプリエクステンション系は実機**（シミュレータ既知の問題: StandBy 不可、アプリエクステンション大半が実行・デバッグ不可）。
4. `CameraCaptureAccessory` / テレプロンプタ（外側ディスプレイ）の動作も実機で。

## 次のセッションの注意点（ハマり所・確定済み）

- **ビルドは必ず `OTHER_SWIFT_FLAGS=-disable-sandbox`**（上の 1 を参照）。効かなくなったらまずこの build setting を確認。xcb の extraArgs に設定済みなので通常はそのまま `xcb_build_sim`。
- **この Mac に 2 つの Xcode がある。** `xcode-select` の既定は `/Applications/Xcode_27_1.app`（Duo 対応）。「無い」と結論しない。SDK パスは必ず `Xcode_27_1.app` 配下。xcb の env に `DEVELOPER_DIR` を設定済み。
- **素の bash の `xcodebuild` はこの sandbox では使えない**（`/var/folders` への書き込み拒否で workspace arena を作れず、`-derivedDataPath build/DerivedData` を付けても LogStore 等が `Operation not permitted`）。ビルドは xcb（XcodeBuildMCP）を使う。`xcrun` の cache ファイル（`/var/folders/…/xcrun_db-*`）も同様に拒否（warning として出るが無害）。
- **`swiftc -typecheck` の単体プローブは効く**（module cache を `build/probe/modcache` 等 cwd 配下へ `-module-cache-path`、TMPDIR も cwd 配下へ）。plugin 動作の切り分けに便利。
- **シミュレータ 2 台**（iOS 27.1）: `6B8C075B-…`（主に使用）、`0F5B43CE-…`。他は iOS 27.0（DuoLab DT 27.1 と非互換）。
- 内側 `size class` は regular×regular、`supportedInterfaceOrientations` に従わない（orientation 判定は size class に置換）。
- ヒンジデータ（angle/status）は**インタラクション用**。レイアウトは Arrangement / Reserved Region。
- push は seed の git-network 転送（単独 `git push`）。`gh --source/--push` は allowlist 外。

## API 早見（詳細・コード例は docs/iphone-duo-support.md §4、実装は DuoLab/*.swift）

| 群 | SwiftUI | UIKit |
|---|---|---|
| ヒンジ | `.onHingeChange { old, ctx in }`（`DeviceHinge.status/.angle`。Status は struct → `==` 比較） | `UIHingeInteraction { interaction, update in }`（`UIHinge.Status` は enum、`unknown` 含む） |
| 2 面レイアウト | `ArrangementView { } secondary: { }` + `.arrangementViewStyle(.split.axes(.vertical) / .overlay.axes(.vertical))`（別型） | `UIArrangementViewController` + `UISplitArrangement().axes(_)` |
| 折り目・カメラ | `GeometryProxy.reservedRegions(kind:options:)` | `view.reservedRegions(kind: .division)`（`UIViewReservedRegion.margins`） |
| 縦バー | `.toolbarVerticalBehavior(.disabled)`、`.toolbarVerticalCompressionBehavior(.prefersTabBar)`、`ToolbarContent.axisBehavior(.verticalPreferred)` | `UITraitCollection.systemTraitsAffectingVerticalBarEdge` + `registerForTraitChanges` |
| 複数ディスプレイ | `openWindow(id:)`（iOS は非 throw）、`CameraCaptureAccessory` + `.sceneAccessory` + `.onAvailabilityChange` | `UIWindowScene.ActivationAction`（alternate 付き）、`UISceneAccessory` |
| カメラ方向 | — | `AVCaptureDeviceDirectionCoordinator`（`.builtInOuterUltraWideCamera` 等） |
