# iPhone Duo 対応リサーチ

> 🔍 最新情報を web で確認しました（2026-09-20 時点）＋ローカル Xcode 27.1（27A9269）の SDK ヘッダを実際に読んだ一次情報。
> 更新: 2026-09-20 ／ 著: seed（作業アシスタント）

本ドキュメントは「iPhone Duo で必要になる対応」と「API（ヒンジ API など）」をまとめる。
事実の根拠は二系統。

- **【SDK】** = この Mac にインストール済みの Xcode 27.1（Build 27A9269）の iOS 27.1 SDK ヘッダ・swiftinterface を実際に読んだ一次情報。最も確実。
- **【web】** = Apple 公式（newsroom / 仕様ページ / Tech Talk / Developer News）や信頼できる報道。末尾の Sources に URL。

---

## 1. 結論（TL;DR）

- iPhone Duo は Apple 初の**折りたたみ** iPhone。2026-09-09 発表、10-16 予約開始、**10-23 発売**、**iOS 27.1** 搭載、$1,999 から【web】。
- 開発には **Xcode 27.1**（beta、2026-09-18 提供開始）が必要。iOS 27.1 SDK と「**iPhone Duo シミュレータ**」を含む【web+SDK】。
- 未再ビルドでも動きますが、**iOS 27.1 SDK でビルド**しないと画面端（status bar・カメラの下）まで広がりません【web】。
- 新しい能力は主に 4 群：**ヒンジ（角度・状態の監視）／ Arrangement（2 面レイアウト）／ Reserved Region（折り目・カメラの領域）／ Vertical Bar（側面バー）**、さらに複数シーンとカメラ系【SDK】。
- 既存の iPhone アプリに最も影響するのは **size class・safe area・画面参照**の扱いと、**バーが縦（側面）に移動**する点。
- **本リポジトリの成果物が「サンプルアプリ」を作るときの要件集**になる。

---

## 2. デバイス・ハードウェアの事実

### ディスプレイ（2 枚）

| | 内側ディスプレイ | 外側ディスプレイ |
|---|---|---|
| 対角 | 7.6-inch（規格では 7.58"） | 5.4-inch（規格では 5.36"） |
| 物理ピクセル（Apple 仕様） | 1878 × 2670 px、430 ppi | 1398 × 2034 px、460 ppi |
| シミュレータのフレームバッファ【SDK】 | 2007 × 2853 px @ 3x = **669 × 951 pt**（`primary-1`、nativeRotation 270） | 1398 × 2034 px @ 3x = **466 × 678 pt**（`primary`） |
| バッファ方向（実測・9/22） | **pose と orientation の両方に依存**: closed=2007×2853（portrait）、open+orientation=portrait=2853×2007（landscape）、open+landscape=2007×2853。DeviceHub `Rotate Right`（90° ずつ）で反転 | portrait=1398×2034 / landscape=2034×1398。内外とも `Rotate Right` で反転（[引き継ぎ §16](handoff-next-session.md)） |
| 特徴 | ナノテクスチャ・アンチグレア、画面下 FaceTime カメラ（under-display） | iPhone 18 Pro 画面の 90% 相当 |

> **方向の判別**: バッファ方向は `simctl io screenshot --display=primary[-1]` の出力を `file` で見る（px 数）。`simctl io enumerate` は解像度数値を出さない。pose（`probe2 axpress`）と orientation（`Rotate Right`）は独立操作だが、**バッファ方向・size class・corner radius は orientation に依存、safe area insets だけ非依存の定数**（9/22 実測、[引き継ぎ §16](handoff-next-session.md)）。

> ⚠️ **要実機確認**: 内側の論理解像度が「シミュレータ 669×951 pt」に対し「物理 1878×2670 px（3x 換算で 626×890 pt）」と**約 7% ずれる**。報道（blakecrosley）は「内側は 669×951 pt でレンダリングし、各辺約 6.4% スケールダウンして 1878×2670 になる（Plus 世代と同様の構成）」と推測。固定 px・pt での比較は避ける（§6 の原則）。

### その他のハードウェア

- **A20 Pro**（iPhone 18 Pro 同款、2nm）【web】
- **Touch ID**（サイドボタン内蔵、Face ID ではない）→ コードの「Face ID を使う」文言は誤り【web】
- **ヒンジ**: 100 以上の部品で構成、表示面の中央を支える【web】
- **カメラ**: 48MP Fusion Main（2x テレ）／ 48MP Fusion Ultra Wide ／ 外側 12MP Center Stage 前カメラ ／ 内側 under-display FaceTime カメラ【web】
- ProMotion / Always On / Dynamic Island（側面に縦置きで再設計）/ IP68 / eSIM のみ【web】
- シミュレータのデバイスプロファイル【SDK】: `modelIdentifier = iPhone19,4`、`productClass = V68`、`model A3447`、`minRuntimeVersion = 27.1`、`chromeIdentifier = phone15`

### 販売

- 予約 2026-10-16（金）/ 発売 **2026-10-23**（金）、iOS 27.1 搭載、$1,999〜（256/512GB/1/2TB）、日本は対象国【web】

---

## 3. ツールチェーン（開発環境）

| 項目 | 内容 | 根拠 |
|---|---|---|
| Xcode | **27.1 beta**（27A9269、2026-09-18 提供開始） | 【web】 |
| 対象 SDK | iOS **27.1**（iPhone Duo 対応の SDK。27.0 SDK では Duo の API はない） | 【web+SDK】 |
| シミュレータ | **iPhone Duo**（`com.apple.CoreSimulator.SimDeviceType.iPhone-Duo`） | 【SDK】 |
| ランタイム | iOS 27.1（`com.apple.CoreSimulator.SimRuntime.iOS-27-1`） | 【SDK】 |
| ポーズ操作 | **Device Hub** の画面下端コントロールで open / close / rotate / fold | 【web】 |
| 設計キット | Figma / Sketch の iPhone Duo デザインキット（Apple Design Resources） | 【web】 |

### シミュレータの既知の問題（Xcode 27.1 beta Known Issues）【web】

- **StandBy は iPhone Duo シミュレータでは利用不可**
- **アプリエクステンションの大部分は実行・デバッグ不可**
- **初回シミュレータ起動に数分かかることがある**

→ StandBy / エクステンションまわりは**実機でのテスト**が必要。

### Mac Catalyst での注意【web】

- iOS 27.1 専用 API を使うと **Catalyst ビルドでコンパイルエラー**（`undeclared identifier` 等）→ 対処: `#if !targetEnvironment(macCatalyst)`
- iOS 27.1 を target にすると **Catalyst の実行先が表示されない** → 対処: target 設定に Mac Catalyst 27.0 の最低デプロイを追加

---

## 4. 新 API 一覧（iOS 27.1 SDK を実読した一次情報）【SDK】

利用可能アノテーションの注意: ヒンジ／Arrangement／Reserved Region 系は `API_AVAILABLE(ios(27.1), tvos(27.1), visionos(27.1))`（watchOS 不可）。**バー軸の個別列挙値（`horizontalOnly` / `verticalPreferred` / `prefersBarItems` / `prefersTabBar`）と `UIVerticalBarEdge.leading/.trailing` は `API_AVAILABLE(ios(27.1))` のみ（iOS 限定）**。
→ deployment target は 27.1、あるいは `@available(iOS 27.1, *)` でガード。

### 4.1 ヒンジ（Hinge）—「ヒンジ API」の正体

ヒンジの**状態と角度**を観測して、インタラクション／エフェクトを駆動する。

| 型 | 主要メンバー | 備考 |
|---|---|---|
| `UIHingeStatus` | `unknown` `closed` `partiallyOpen` `fullyOpen` | 高レベルの状態 |
| `UIHinge` | `status`、`angle`（ラジアン、`CGFloat`） | 読み取り専用。`UIHingeInteraction` 経由で入手 |
| `UIHingeInteraction` | `initWithUpdateHandler:`、`enabled` | view に `addInteraction(_:)` で付与 |
| `UIHingeInteractionUpdate` | `hinge`（`UIHinge?`、nullable） | ハンドラ引数 |

```swift
// UIKit
override func viewDidLoad() {
    super.viewDidLoad()
    let interaction = UIHingeInteraction { [weak self] _, update in
        // nil hinge = ヒンジ無しのデバイス、またはヒンジ更新を提供する階層から外れた
        guard let hinge = update.hinge else { handleHingeUnavailable(); return }
        updateAngleDisplay(with: hinge.angle)      // ラジアン。更新頻度・粒度はシステム政策で変わる
        updateStatusDisplay(with: hinge.status)    // 頻度頼みたくないなら status を優先
    }
    view.addInteraction(interaction)
}
```

**SwiftUI 版**（`SwiftUICore`）:

```swift
// onHingeChange(isEnabled:_:) — DeviceHingeContext（hinge: DeviceHinge?）を返す
GuitarView(pitchBend: pitchBend)
    .onHingeChange { _, context in
        if let hinge = context.hinge, hinge.status == .partiallyOpen {
            pitchBend = calculatePitchBend(angle: hinge.angle) // Angle
        } else {
            pitchBend = 0
        }
    }
// 型: DeviceHinge { status: DeviceHinge.Status, angle: Angle }
//   DeviceHinge.Status { closed, partiallyOpen, fullyOpen }
```

> **設計原則（Tech Talk）**: ヒンジデータは「ライブで観測される」ので**インタラクション・エフェクト用**。**レイアウトに使うなら Arrangement / Reserved Region を使う**（§4.2・4.3）。

### 4.2 Arrangement — 2 面のレイアウト容器

ナビゲーション容器とコンテンツ容器の**間**に位置し、primary / secondary 2 面をルールで並べる。

| 型 | 主要メンバー |
|---|---|
| `UIArrangementViewController` | `updateArrangement(animated:)` / `updateArrangement(_:)`、`stateForPlacement:`、`viewControllerForPlacement:`、`placementForViewController:`、`setViewController:forPlacement:(animated:)` |
| `UIArrangementViewControllerViewPlacement` | `none` `primary` `secondary` |
| `UIArrangement`（基底） | — |
| `UIArrangementViewState` | `zIndex`、`splitAxis`、`hidden` |
| `UIOverlayArrangement` + `ViewProperties` | `edge`（`NSDirectionalRectEdge`） |
| `UISplitArrangement` + `ViewProperties` | `width`/`height`（`UISplitArrangementDimensionRange`）、`layoutPriority` |
| `UISplitArrangementDimension` | `automatic()` `intrinsic()` `fractional(_:)` `absolute(_:)` |

```swift
// SwiftUI
NavigationStack {
    ArrangementView { PlayerView() } secondary: { UpNextView() }
        .arrangementViewStyle(.split.axes(.horizontal))   // or .overlay
}
// overlay 時の Z 索引（折りたたまれると変化する）
@Environment(\.overlayArrangementZIndex) var zIndex: Int
```
```swift
// UIKit
let arrangementVC = UIArrangementViewController()
let nav = UINavigationController(rootViewController: arrangementVC)
arrangementVC.setViewController(PlayerVC(), for: .primary)
arrangementVC.setViewController(UpNextVC(), for: .secondary)
arrangementVC.updateArrangement(.split.axes(.horizontal))
let z = arrangementVC.state(for: .primary)?.zIndex ?? 0
```

> **使い分け（Tech Talk）**: 既存に HStack/VStack 型の分割がある → `split`、ZStack 型の重ね合わせ・明確な前景/背景 → `overlay`。主-詳細（main-detail）→ split、前景制御+背景スクロール → overlay。**NavigationSplitView を ArrangementView に入れず、ArrangementView を List/ScrollView 内にも入れない。**

### 4.3 Reserved Region — 折り目・カメラの領域

ハードウェア特徴（**折り目＝ヒンジ、内外カメラ**）が画面を占める領域をクエリして、レイアウトを寄せられる。

| 型 | 主要メンバー |
|---|---|
| `UIViewReservedRegion`（final） | `identifier`、`kind`、`frame`（CGRect、margin 込み）、`margins`（`UIEdgeInsets`）、`active` |
| `UIViewReservedRegionKind` | `occlusionRegionKind`（カメラ=遮蔽）、`divisionRegionKind`（折り目=分割） |
| `UIViewReservedRegionQueryOptions` | `none`、`includeInactive` |
| `UIView (ReservedRegion)` | `reservedRegions(ofKind:)` / `reservedRegions(ofKind:options:)` |

```swift
// SwiftUI — GeometryProxy（GeometryReader / onGeometryChange から）
GeometryReader { proxy in
    let fold = proxy.reservedRegions(kind: .division)                     // 折り目
    let cams = proxy.reservedRegions(kind: .occlusion)                    // カメラ
    let all  = proxy.reservedRegions(kind: .division, options: .includeInactive)
    // 各 region.frame / .margins / .isActive
}
// 型: ReservedRegion { id, kind(occlusion|division), frame, margins, isActive }
//   reservedRegions(kind:options:layoutDirectionBehavior:) — 既定 .mirrors
//   LayoutDirectionBehavior { fixed, mirrors, mirrors(in:) }（iOS 17.0~）
```
```swift
// UIKit
let fold = view.reservedRegions(ofKind: .division)          // 折りたためば active、フラット時は幅0・inactive
let cams = view.reservedRegions(ofKind: .occlusion)         // カメラ使用中のみ active
let frames = fold.map(\.frame)
```

> **要点（Tech Talk）**: 折り目の division region は**折りたたまれているときだけ active**（フラット時は幅ゼロ・inactive）。inactive も「列数を偶数にしたい」等の高レベル判断に使える。システムは alert / action sheet / メニュー / popover を予約領域を避けて自動で再配置する。自前で**displacement**（要素の frame を移動）を実装するなら API を使う。

### 4.4 Vertical Bar — バ・コントロールが側面に

広い外側ディスプレイで上下の余白を確保するため、**上下のバーが側面（leading/trailing）に縦積み**になる。

| 型 | 主要メンバー |
|---|---|
| `UIVerticalBarEdge` | `unspecified`、`leading`(iOS)、`trailing`(iOS) |
| `UITraitCollection (VerticalBar)` | `verticalBarEdge`、`systemTraitsAffectingVerticalBarEdge`（class） |
| `UIBarButtonItem.AxisBehavior` | `automatic`、`horizontalOnly`(iOS)、`verticalPreferred`(iOS) → `UIBarButtonItem.axisBehavior` |
| `UIVerticalBarCompressionBehavior` | `automatic`、`prefersBarItems`(iOS)、`prefersTabBar`(iOS) → `UINavigationItem (VerticalBar).verticalBarCompressionBehavior` |
| `UIVerticalBarBehavior` | `automatic`、`disabled` → `UIViewController.preferredVerticalBarBehavior`、`childForPreferredVerticalBarBehavior` |
| `UIViewLayoutRegion` | `layoutRegionForBarOnEdge:extent:`、`layoutRegionForBarOnDirectionalEdge:extent:` |

```swift
// SwiftUI
.toolbar { … }.axisBehavior(.verticalPreferred)              // ToolbarItemAxisBehavior
NavigationStack { … }.toolbarVerticalBehavior(.disabled)     // opt-out
NavigationStack { … }.toolbarVerticalCompressionBehavior(.prefersTabBar)
// 型: ToolbarItemAxisBehavior{automatic, horizontalOnly(iOS), verticalPreferred}
//   ToolbarVerticalBehavior{automatic, disabled}
//   ToolbarVerticalCompressionBehavior{automatic, prefersToolbarItems(iOS), prefersTabBar(iOS)}
```

> **opt-in の条件（Tech Talk）**: ①最新 SDK で再ビルド、②ナビゲーション容器（NavigationStack/NavigationSplitView、UINavigationController/UITabBarController）が持つバーを使う（自作 UIToolbar/UINavigationBar の中身は対象外）。**opt-out**: `preferredVerticalBarBehavior = .disabled`（全画面再生プレイヤー・電卓のような非スクロール UI に限定、頻繁に切り替えない）。
> **配置ルール**: 上部=主ナビゲーション（back/close）→ 目立つ操作（done）→ 残り。縦バーは**固定幅・可変高**なので**シンボル単体の項目**が向く（テキスト項目は水平に残る）。狭くなったら overflow メニューへ自動集約。RTL ではバーはハードウェア側に留まり中身が適応する。

### 4.5 複数シーン・Scene Accessory — 2 枚のディスプレイ同時

| 型 | 内容 |
|---|---|
| `UISceneAccessory.cameraCapture(sceneConfiguration:)` / `(…:userInfo:)` | カメラ撮影中のシーンに補助 UI |
| `UIWindowSceneSessionRoleCameraCaptureAccessory` | `windowCameraCaptureAccessory`（システムが割り当て、読取のみ） |
| `CameraCaptureAccessory<Content>`（SwiftUI、`SceneAccessoryContent`） | `init(content:)`、`init(isEnabled:content:)` |
| `.sceneAccessory { CameraCaptureAccessory { … } }` / `.onAvailabilityChange { … }` | 外側ディスプレイに副コンテンツ（テレプロンプタ等の例） |
| `UIWindowSceneActivationAction`（iOS 15.0~） | 新ウィンドウ/シーン要求。新ウィンドウが利用不可なら**自動で非表示** |

```swift
// SwiftUI — 内側にカメラ UI、外側にテレプロンプタ
CameraView(model: model)
    .sceneAccessory {
        CameraCaptureAccessory(isEnabled: $model.isEnabled) {
            TeleprompterView(model: model)
        }
        .onAvailabilityChange { model.isAvailable = $0 }
    }
    .toolbar { TeleprompterToggle(isEnabled: $model.isEnabled).disabled(!model.isAvailable) }
```

> **要点（Tech Talk）**: iPhone Duo は**初の複数インスタンス対応 iPhone**（iPad で対応済みならそのまま）。ただし**外側ディスプレイでは新ウィンドウを作れない**（内側のみ）→ 新シーンの要求は**エラーを必ず処理**し、`UIWindowSceneActivationAction` を使う。Scene Accessory の可用性はシステムが動的に制御 → `onAvailabilityChange`（observation）で追従。

### 4.6 カメラ（AVKit / AVFoundation）— 内外カメラ・方向

| 型 | 内容 |
|---|---|
| `AVCaptureDeviceTypeBuiltInOuterUltraWideCamera` | 外側前面カメラ（4K/120fps まで）【SDK】 |
| `AVCaptureDeviceTypeBuiltInInnerUltraWideCamera` | 内側前面カメラ（under-display、1080p/60fps）【SDK】 |
| **Virtual Front Camera** | 内外前面を自動切替する仮想 `AVCaptureDevice`（position `.front` + Wide/UltraWide で発見）【web】 |
| `AVCaptureDeviceDirectionCoordinator` | `initWithView:deviceTypes:changeHandler:`、`deviceDirections` |
| `AVCaptureDeviceDirectionMap` | `forwardFacingDeviceDescriptors`、`backwardFacingDeviceDescriptors` |
| `AVCaptureDeviceDescriptor` | `deviceType`、`mediaTypes`、`position`、`uniqueID`、`localizedName`（**main-actor safe・Sendable**。カメラ actor へ渡し、そこから AVCaptureDevice を生成） |

```swift
// どのカメラが view の「前」を向いているかを追跡（開閉・反転で変わる）
let coordinator = AVCaptureDeviceDirectionCoordinator(
    view: self, deviceTypes: [.builtInOuterUltraWide, .builtInInnerUltraWide],
    changeHandler: { map in
        // map.forwardFacingDeviceDescriptors から現在前面を向くカメラを特定
        // → AVCaptureSession をそのカメラに再構成、preview のミラー判定、UI 更新
        // changeHandler は main queue。AVFoundation API は直接呼ばず descriptor を actor へ
    })
```

> **要点（Tech Talk）**: 2 つの前面カメラは `position` が常に `front` だが、**ディスプレイが向きを異にするので「front = 自分の方」ではない**（開いた状態で外側前面が向いている場合等）。方向コーディネータで「今 view から見て前面を向くカメラ」を把握し、開閉に応じてセッションを再構成。**Virtual Front Camera を使うと両カメラ共通機能のみ（max 1080p/60fps）**、個別カメラ型を使うと全機能（depth など）だが切替は自前。preview は `AVCaptureVideoPreviewLayer.videoGravity` で配置。

---

## 5. 対応すべきレイアウト原則（Tech Talk 集約）【web】

1. **iOS 27.1 SDK でビルド**（画面端まで＋縦バーが有効になる）。
2. **size class を使う、interface orientation は使わない。**
   - 外側ディスプレイ: 従来 iPhone と同じ（portrait=compact×regular、landscape=compact×compact。9/22 実測で orientation 依存を確認、[引き継ぎ §16](handoff-next-session.md)）。
   - **内側ディスプレイ: regular×regular**（sidebar 等を表示できる余白。9/22 は open のみで確認、orientation 非依存かは未確定）。
   - **内側は `supportedInterfaceOrientations` に従わない** → 必ず size class で判断。
3. **main screen を参照しない。** 2 ディスプレイでは曖昧（将来非推奨予定）。
   - `environment` / `traitCollection` / シーンの bounds を使う。
   - 画面にアクセスが必要なら `window?.windowScene?.screen`。
   - `UIScreen.main.scale` → **`traitCollection.displayScale`** に置換。
4. **角に合わせる**: iOS 26 の Concentricity API（SwiftUI `ConcentricRectangle`、UIKit `UICornerConfiguration`）。9/22 実測: corner radius は **orientation 依存**（外側 portrait=all 0 → landscape=BL25）。pose 依存ではなく orientation 依存（[引き継ぎ §16](handoff-next-session.md)）。
5. **標準ナビゲーションを採用**: NavigationSplitView / UISplitViewController、TabView / UITabBarController は全ポーズで適応（閉じたとき列は折り畳み、開いたときタイル or 重ね合わせ）。内側で sidebar: `.defaultTabBarPlacement(.sidebar)` / `tabBarController.sidebar.preferredPlacement = .sidebar`。
6. **safe area を尊重し、非対称を扱う。**前景（操作系）は safe area 内、背景（アートワーク等）は `.ignoresSafeArea()` / `view.bounds` で延伸。**左右の inset が等しいと仮定しない（各辺を独立に処理）→ Split View でテスト。**9/22 実測では内外・pose・orientation いずれでも inset が不変の定数（T82/R84/B34/L0）だった → 各辺の非対称処理は引き続き必須（[引き継ぎ §16](handoff-next-session.md)）。
7. **ヒンジはインタラクション用、レイアウトは Arrangement/Reserved Region**（§4）。
8. **Split View（50/50）と複数ウィンドウ**を前提に（iPad リサイズ対応済みなら好調なスタート）。

---

## 6. サンプルアプリを作る場合の要件チェックリスト

- [ ] Xcode 27.1、iOS **27.1** deployment target（`@available(iOS 27.1, *)` ガード）
- [ ] iPhone Duo シミュレータで open/close/rotate/fold 各ポーズを Device Hub で確認
- [ ] size class 判定（内側 regular×regular、orientation 非依存）
- [ ] `UIScreen.main` 参照の除去（`traitCollection.displayScale` / `windowScene.screen`）
- [ ] 非対称 safe area / layout margin の処理 + Split View テスト
- [ ] ヒンジ: `UIHingeInteraction`（UIKit）/ `onHingeChange`（SwiftUI）で angle・status を観測しエフェクト駆動
- [ ] レイアウト: 折り目（division）・カメラ（occlusion）の `reservedRegions` をクエリし displacement
- [ ] 2 面: `ArrangementView`/`UIArrangementViewController`（split or overlay）
- [ ] バー: 縦バーへの opt-in / `axisBehavior` / overflow / 必要なら `preferredVerticalBarBehavior = .disabled`
- [ ] 複数シーン: 新ウィンドウ要求のエラー処理 + `UIWindowSceneActivationAction`
- [ ] （カメラ系）`AVCaptureDeviceDirectionCoordinator` で方向追跡・セッション再構成
- [ ] （副ディスプレイ）`CameraCaptureAccessory` + `onAvailabilityChange`
- [ ] Concentricity（`ConcentricRectangle` / `UICornerConfiguration`）で角対応
- [ ] StandBy / エクステンションはシミュレータ非対応 → 実機テスト
- [ ] Mac Catalyst なら `#if !targetEnvironment(macCatalyst)` ガード

---

## 7. 制約・既知の問題まとめ

| 項目 | 内容 |
|---|---|
| ヒンジ等の利用可アノテーション | `ios/tvos/visionos 27.1`（watchOS 不可）。バー軸の個別値と `UIVerticalBarEdge` の leading/trailing は **iOS 限定** |
| シミュレータ | StandBy 不可／アプリエクステンション（大半）実行・デバッグ不可／初回起動に数分 |
| 内側解像度 | シミュレータ 669×951 pt（2007×2853@3x）≠ 物理 1878×2670（430ppi）→ 約 7% 差、**実機で確認要** |
| Mac Catalyst | iOS 27.1 専用 API でコンパイルエラー・実行先なし → `#if !targetEnvironment(macCatalyst)`、最低デプロイ追加 |
| 提供状況 | Xcode 27.1 は **beta**。iOS 27.1 GA は 10-23 発売時 |

---

## 8. Sources

**【web】Apple 公式**
1. Apple Newsroom — *Apple unveils iPhone Duo*（2026-09-09。発売日・価格・A20 Pro・Touch ID・カメラ・ディスプレイ） — https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/
2. Apple — *iPhone Duo Technical Specifications*（1878×2670@430ppi / 1398×2034@460ppi・Touch ID・A20 Pro） — https://www.apple.com/iphone-duo/specs/
3. Apple Developer — *Get Ready for iPhone Duo*（workshop / Group Lab / Q&A） — https://developer.apple.com/iphone-duo/
4. Apple Developer — *Preparing your app for iPhone Duo*（Technology Overviews） — https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
5. Apple Developer Tech Talk 111461 — *Prepare your app for iPhone Duo*（SDK 段階、size class、safe area、reserved region） — https://developer.apple.com/videos/play/tech-talks/111461/
6. Apple Developer Tech Talk 111462 — *Raise the bar with iPhone Duo*（縦バー） — https://developer.apple.com/videos/play/tech-talks/111462/
7. Apple Developer Tech Talk 111463 — *Strike a pose with adaptive layouts on iPhone Duo*（displacement・Arrangement・reserved region） — https://developer.apple.com/videos/play/tech-talks/111463/
8. Apple Developer Tech Talk 111464 — *Leverage multiple displays and scenes on iPhone Duo*（hinge・複数シーン・scene accessory） — https://developer.apple.com/videos/play/tech-talks/111464/
9. Apple Developer Tech Talk 111465 — *Build a great camera experience for iPhone Duo*（Virtual Front Camera・方向コーディネータ） — https://developer.apple.com/videos/play/tech-talks/111465/
10. Apple Developer Tech Talk 111466 — *Design for iPhone Duo*（設計原則） — https://developer.apple.com/videos/play/tech-talks/111466/
11. Apple Developer News — *Get ready with the latest beta releases*（2026-09-16、iOS 27.1 = iPhone Duo、10-23） — https://developer.apple.com/news/?id=rfb1rooi
12. Apple Developer News — *Build for iPhone Duo with new resources*（2026-09-18、Xcode 27.1 beta・設計キット） — https://developer.apple.com/news/?id=nyuppv9r
13. Apple HIG — *Designing for iPhone Duo* — https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

**【web】報道・解説**
14. Blake Crosley — *iPhone Duo for Developers: The 1.42 Problem and the SDK Gap*（27.1 beta 27A9269 の 9/18 提供、SDK の型名、Catalyst 制約、内側解像度の推測） — https://blakecrosley.com/blog/iphone-duo-for-developers
15. MacRumors / 9to5Mac — *Xcode 27.1 Beta With iPhone Duo Support*（2026-09-18） — https://www.macrumors.com/2026-09-18/apple-releases-xcode-27-1-beta-iphone-duo-support/

**【SDK】ローカル Xcode 27.1（27A9269）の iOS 27.1 SDK（`/Applications/Xcode_27_1.app`）**
- `UIKit/UIHinge.h`、`UIKit/UIHingeInteraction.h`
- `UIKit/UIArrangementViewController.h`、`UIKit/UIOverlayArrangement.h`、`UIKit/UISplitArrangement.h`
- `UIKit/UIViewReservedRegion.h`、`UIKit/UIView.h`（`reservedRegionsOfKind:`）
- `UIKit/UIVerticalBarEdge.h`、`UIKit/UIBarButtonItem.h`、`UIKit/UINavigationItem.h`、`UIKit/UIViewController.h`、`UIKit/UIViewLayoutRegion.h`
- `UIKit/UISceneAccessory.h`、`UIKit/UIWindowScene.h`
- `AVKit/AVCaptureDeviceDirectionCoordinator.h`、`AVFoundation/AVCaptureDevice.h`
- `SwiftUI` / `SwiftUICore` swiftinterface（`onHingeChange`、`DeviceHinge(Context)`、`ReservedRegion`、`GeometryProxy.reservedRegions`、`ArrangementView`、`Toolbar*Behavior`、`CameraCaptureAccessory`）
- 27.0↔27.1 のヘッダ差分（`artifacts/ios27.1-sdk/`）
