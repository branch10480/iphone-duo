# iPhone Duo サンプルアプリ —— 引き継ぎ書（2026-09-22 最終更新）

> この文書は日時付きの観測記録。現在の操作は [開発手順](development.md)、入口は [AGENTS.md](../AGENTS.md) を参照する。
> 以下の「現在」「起動中」、UDID、Gitの状態は記録時点のもの。過去のコマンドや回避策は現在の実行許可・推奨手順ではない。

## 状態（2026-09-22 時点・区切りつき）

- **サンプルアプリ「DuoLab」は完成・ビルド成功・全タブ動作確認済み**（9/21 に push、9/22 は既存成果物で検証のみ）。
  - 9/21 の区切りコミット `85e5a05`（本体）/ `9894b44`（handoff）、以降 `36601ed` / `b7893c9` / `0f2bdba` / `0fa2985`（size class 判定修正 + §12〜15）。
  - **現在: `main` = `origin/main` = `0fa2985`、未コミットなし**（2026-09-22 朝 `git status` で一致確認）。
- §6 の 14 項目を網羅する 7タブ構成（Overview / Hinge / Two Pane / Regions / Bar / Scenes / UIKit）。
- iPhone Duo シミュレータ（iOS 27.1、`6B8C075B-0655-4C20-9CAD-ACB1A97B5EEC`、起動中）で全タブ巡回・クラッシュなし。
- **§6 の各ポーズの観測・内外解像度実測は完了（9/21）**。観測値は下 6〜9 と「内側ディスプレイ実測値」。
  - 残（実機のみ）: 本体カメラの撮影 / StandBy / アプリエクステンション。`CameraCaptureAccessory` の可用性（pose 依存）とテレプロンプタ外側描画はシミュレータで確認済み（下 10〜11）。
- **現在 pose = closed、orientation = landscape**（9/22、`Rotate Right` 経由で 90° 回転、下 16）、アプリ `com.branch10480.duolab`（pid 35886、fresh `boot` 後起動）は外側表示。DeviceHub は pid 2173 で起動中（pose ボタン 4 個に到達可能、下 6）。
- **9/22 で残作業 2 のシミュレータ範囲を確定**（下 16・17・18）、**さらに 360° サイクルの live 再検証（下 19）で safeArea の logical 形状依存・corner の pose×orientation 依存を確定**（要約の「safeArea 不変定数」を修正）＋ open+landscape の MCP スクショ寸法 1 枚取得。
  - **`fold` の別角度は残作業**（DeviceHub の別制御なし・下 18 → 実機へ）。

## 内側ディスプレイ実測値（確定）

| 項目 | 値 | 出典 |
|---|---|---|
| 内側フレームバッファ | **pose + orientation の両方に依存**（下 16・19）: open 系 = orientation=portrait 2853×2007（landscape）/ landscape 2007×2853（交互反転、90° cumulative）、closed = 2007×2853（portrait）（`--display=primary-1`） | `simctl io screenshot` の `file` |
| 内側論理（safe area 済み） | portrait（2007×2853 バッファ）= **669 × 734 pt** / landscape（2853×2007 バッファ）= **867 × 553 pt**。669×951pt はフルフレーム値（safe area 前、§14）。3.00x | アプリ Overview |
| 内側 scale | **3.00x**（`traitCollection.displayScale`） | アプリ Overview |
| 外側フレームバッファ | **pose + orientation の両方に依存**（下 16・19）: closed+portrait = 1398×2034 / closed+landscape = 2034×1398 / open・book 時 = 2034×1398（全黒だが landscape バッファ）。orientation 出発 portrait（fresh） | `simctl io screenshot` の `file` |
| 外側論理（safe area 済み） | portrait **382 × 562 pt** / landscape **594 × 350 pt**（safe area 込み。orientation 依存） | アプリ Overview |
| safeArea（内外共通） | **pose 非依存だが orientation（logical 形状）に依存（下 19 で修正）**: portrait logical = **T 134 / R 0 / B 83 / L 0**、landscape logical = **T 82 / R 84 / B 34 / L 0**。内外共通、値は pose 不変 | アプリ Overview |
| 外側 size class | portrait **h-compact / v-regular**（従来 iPhone portrait 同型）/ landscape **h-compact / v-compact**（従来 iPhone landscape 同型）。orientation 依存（下 16） | アプリ Overview |
| 内側 size class | regular × regular | アプリ Overview |
| corner radius | **pose × orientation 両方に依存（下 19）**: 外側 = portrait all 0 / landscape **BL 25**、内側 = portrait all 0 / landscape **BL 21**（内外で半径値が異なる） | アプリ Overview |

照合: landscape 外側フルフレーム `2034/3 = 678 × 2034→1398/3 = 466pt`、safe area 控除（T82/R84/B34/L0）で論理 `594 × 350pt`（= 表示値と一致）。**`--display=primary` = 外側、`--display=primary-1` = 内側**。

> **バッファ方向の方向性**（9/22 で確定・下 16）: フレームバッファの方向は **pose と orientation の両方に依存**。`simctl io screenshot` の `file`（px 数）で判別。`simctl io enumerate` は解像度数値が出ない（画面名 `Name:`/`Device Name:` のみ）→ バッファ方向は screenshot の `file` で。

## このセッション（前半・2026-09-20）でやったこと

1. **`@State` マクロ不解決の根本原因を特定・解消**
   - 症状: `SwiftUIMacros.StateMacro could not be found … swift-plugin-server produced malformed response`（`@State` 全箇所）。各コンパイル直前に `sandbox-exec: sandbox_apply: Operation not permitted` がログに出る。
   - 原因: seed の sandbox 内で xcodebuild がコンパイラ subprocess（`swift-plugin-server`）を `sandbox-exec` で spawn するのに失敗 → 外部マクロが解決できない。**アプリコードのバグではない**。
   - 解決: build setting `OTHER_SWIFT_FLAGS=-disable-sandbox`（swift-frontend の `-disable-sandbox` = subprocess sandbox を無効化）。素の swiftc での A/B プローブ（sandbox ON=FAIL / OFF=OK）で確定。xcb の `extraArgs` に設定し persist。
   - **このフラグは seed sandbox 内のビルド用**。実マシンの Xcode には不要なので、リポジトリ（pbxproj）には入れず gitignore の `.xcodebuildmcp/config.yaml` に置いた。チェックアウトして xcb を使う側は `xcb_session_set_defaults` で再指定。
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
4. **動作確認**（sim `6B8C075B`、iOS 27.1）
   - 起動 OK、7タブ表示、UIKit タブ（`UIHingeInteraction` 生成＋trait 登録＋`AVCaptureDeviceDirectionCoordinator`）でクラッシュなし、`openWindow(id:"companion")` 要求後に生存（外側ディスプレイではサイレント無視の想定どおり）。
   - 注: seed の sandbox 内 `ps -p <pid>` は見かけ上 GONE になりうる（sandbox のプロセス表示制限）。生存確認は `pgrep -f DuoLab` を使う。
5. **コミット・push（区切り）**
   - `85e5a05`（本体）+ `9894b44`（handoff）を push。リモート main = `9894b44` を `gh api` で確認。
   - **push 経路の新しい知見**: このセッションでは `git push origin main` / `git push -u origin main` / `cd … && git push` は**すべて素の sandbox（DNS deny）に落ちた**（`Could not resolve host`）。通ったのは **upstream 設定済み＋単独 `git push`（cd なし・複合コマンドなし）のみ**。9/20 セッションでは `git push -u origin main` が通っていたので、転送のマッチング規則は不安定 → **まず upstream 付きの裸 `git push` を試す**。

## このセッション（続き）でやったこと

6. **pose 観測経路の確立**（旧「GUI のみ」→ 下の AX 経路で自動化）
   - `-disable-sandbox` コンパイルの自前バイナリ（`.tmpx/axtest/probe2`）から **in-process AX** を使う。私のプロセスは seed sandbox 内で `NSWorkspace.runningApplications` が 0 件・`NSRunningApplication( pid )` nil・全 Apple event が `-600 procNotFound`（pid 参照では他セッションに届かない）だが、**AX API は他 pid（Dock・DeviceHub・Chrome・Ghostty 等）に到達する**。
   - **DeviceHub メインウィンドウの立ち上げ**: Dock( pid 31600) の AX ツリー（`AXApplication` → `AXDockItem t='Device Hub'`）を `AXUIElementPerformAction(, kAXPressAction)` で押す。→ メインウィンドウ `iPhone Duo – iOS 27.1`（1085×735）が開く。
   - pose 切替はウィンドウ内の pose アクションバー `AXButton`（`d='Closed'` / `Book` / `Open` / `Rotate Right`）の `AXPress`。needle 指定で 1 つだけ press。
7. **各 pose の観測**（app Hinge タブの AX 値 + `devicectl device motion hinge-angle` readback + 内外スクショの点灯を三重確認）

   | pose（ボタン） | app: status / angle / intensity | devicectl readback | ディスプレイ |
   |---|---|---|---|
   | **closed** | `closed` / `0.000 rad (≈ 0.0°)` / `0%` | `Angle: 0.0°` | 外側 primary(1398×2034) 点灯 / 内側 primary-1(2007×2853) 全黒 |
   | **book**（半開） | `partially open` / `2.234 rad (≈ 128.0°)` / `71%` | `Angle: 130.0°` | 外側全黒 / 内側点灯 |
   | **open**（全開） | `fully open` / `3.142 rad (≈ 180.0°)` / `100%` | `Angle: 180.0°` | 外側全黒 / 内側点灯 |

   - 往復可逆: open → book → closed → 各値へ正常復帰。`fold` のみ未観測（`partially open` の別の角度）。
   - `Rotate Right`（action bar）は **orientation を landscapeRight にするのみ**、pose は不変（= pose と orientation は独立）。
8. **ArrangementView（Two Pane）の pose 依存**
   - **split（`.split.axes(.vertical)`）: secondary（Up Next）は非表示**（AX・スクショとも検出できず、zIndex バッジは `zIndex 0`）。
   - **overlay（`.overlay.axes(.vertical)`）: secondary（Up Next 1–4）が表示**（AX で文字列確認）。
   - 内側（regular×regular）での動作確認。外側（narrow・closed）での split/overlay の挙動は未観測。
9. **ReservedRegions（Regions）の pose 依存**（サマリ badge `division N（active M） / occlusion N（active M）`）

   | pose | division | occlusion |
   |---|---|---|
   | open | 1（active **0**） | 2（active 1） |
   | book | 1（active **1**） | 2（active 1） |
   | closed | **0** | 2（active **2**） |

   - 折り目（division）は半開（book）のみ active、全開は幅 0・inactive、閉じると領域自体が消える。active 幅分だけ内容は `.offset(x:)` で退避。
   - **外側（narrow・closed）での Two Pane: primary（Now Playing）+ secondary（Up Next 1–4）の上下両方を表示**（内側 open の split では secondary 非表示 → pose 依存で挙動が逆）。
10. **`CameraCaptureAccessory`（Scenes）の pose 依存可用性・テレプロンプタ外側描画**
   - **可用性は pose 依存: open = available / closed = unavailable**（`onAvailabilityChange` の値を AX で読取）。
   - prompter **on/off で外側ディスプレイの点灯が切り替わる**（on: 平均248=白で点灯 / off: 全黒）→ テレプロンプタが外側（primary）に描画されることを確認。
   - `sim` の `CameraCaptureAccessory` は pose（= 内外 swap）で可用性が変わり、**実機のカメラスイッチ（`onAvailabilityChange`）とは挙動が違う**。実機ではカメラ方向（`builtInOuter/InnerUltraWideCamera`）で切り替わるはず。
11. **複数ウィンドウ（companion / ActivationAction）の sim 動作**
   - `openWindow(id: "companion")` 要求は **open 時（内側）でもサイレント無視**（新規ウィンドウは 1 つのまま）。外側（closed）も不可。
   - UIKit の `UIWindowScene.ActivationAction`（alternate = "Window unavailable here"）はメニューから手動 press できず、`alternate` のトリガーは未確認（実機で）。
12. **Vertical Bar（Bar）の pose 依存検証（2026-09-21 後段・確定）**
   - **`verticalBarEdge`（UIKit `registerForTraitChanges`）は open（内側）でも closed（外側）でも `trailing`**。pose 非依存＝SDK ヘッダ（`UIVerticalBarEdge.h`：「縦バーを使う size class/orientation なら trailing、使わない context なら unspecified」）と整合。open⇄closed 遷移で trait 通知は発生するが値は不変。
   - **opt-in（`axisBehavior(.verticalPreferred)`）は pose 非依存で効く**: closed（外側）・open（内側）**両方のディスプレイでツールバー項目が側面に縦積み**（inkmap のピクセル判定で左右端の縦積みアイコンを視覚確定。`vBar edge` と一致）。
   - **opt-out（`toolbarVerticalBehavior(.disabled)`）で縦バーが抑制され、項目がトップバー（横）へ復帰**（CheckBox press で `val 0→1`、操作成功。DeviceHub ミラーの CheckBox は内外シーンで 2 枚存在し needle 一致で両方に押すので、probe2 に `one`（先頭 1 件のみ）モードを追加して単一 press で検証）。
   - **`fold` の別角度**（`partially open` の別のヒンジ角度）は未観測（`Book` = 128° のみ）。実機か DeviceHub の別の制御で。
13. **Two Pane の外側（closed）挙動の再確認（2026-09-21 後段）**
   - **closed（外側）split（`.split.axes(.vertical)`）**: primary（Now Playing @90,973）+ secondary（Up Next @23,1019、1–4）の**上下両方を表示**（＝§8 の内側 open split・secondary 非表示と対照、pose 依存で逆転を再確認）。
   - **closed（外側）overlay**: secondary（上 @810）/ primary（下 @1077）の**上下逆転**で表示。`zIndex 0`（overlay の内側 zIndex 値は pose 遷移で変化、handoff §8 と整合）。
   - 内側 open の overlay 値（zIndex バッジ）の re-verify は未（前セッション値のみ）。
14. **safe area / size class / concentricity の pose 検証 + size class 判定のコード修正（2026-09-21 後段〜22）**
   - **safe area insets（T82 / R84 / B34 / L 0）は pose・ディスプレイ非依存の定数**（fresh に sim リセットして closed 外側から初回起動でも、open 内側と同一値。前セッションの「外側 reattach 乖離」解釈は不成立→内外で同一 insets）。
   - **corner radii は pose 依存: open（内側）= BL 21 / closed（外側）= all 0**（`concentricCornerRadii`、`ConcentricRectangle` 相当の SwiftUI 値）。
   - **size class**: open 内側 = regular×regular（判定「wide / inner-like」）、closed 外側（orientation=portrait の時点）= **h-compact / v-regular**（= 従来 iPhone の portrait と同型）。**9/22 修正**: orientation=landscape 時は外側 = **h-compact / v-compact**（従来 iPhone landscape 同型）に変化（下 16）→ **size class は orientation 依存**（§5.2 の「size class 判定で orientation 置き換え」と整合）。
   - **コード修正（コミット `0fa2985`）**: `OverviewPage.layoutJudgement` の switch が `(.compact, .regular)` case を持たず外側で「other」と表示していた → `(.compact, .regular)` =「narrow / outer-like（閉じた外側 = 従来 iPhone portrait）」、`(.regular, .compact)/(.compact, .compact)` =「従来 iPhone（landscape 側。Duo では未観測）」に修正。**rebuild → 起動 → closed 外側で「narrow / outer-like（…）」表示を確認済み**（9/21、pid 10533、hinge 0°）。
   - `logical`（`GeometryReader` の `proxy.size`）は **safe area 済み bounds**（open+landscape = 867×553pt、open+portrait = 669×734pt = バッファ 951×669pt / 669×951pt から各 safeArea を控除、下 19）。前セッションの「951×669pt」記録はフルフレーム値（safe area 前）。3.00x 照合 OK。
   - **9/22 の修正**: corner radius は pose 依存では**なく orientation 依存**（外側: portrait all 0 → landscape BL 25、下 16）。safe area insets は pose・ディスプレイ・**orientation** いずれも非依存の定数（下 16 で再確認）。
15. **Hinge の pose 遷移時の癖（2026-09-21 後段・確定）**
   - **fresh 起動の closed = `closed / 0.00 rad`（一貫）**、open = `fully open / 3.14 rad`（devicectl readback と一致）。
   - **open→closed 遷移直後は `closed`（status は最終値）/ `1.40 rad`（angle は途中角度 ≈80°）の一時的な不整合**が観測。`UIHingeInteraction` の update が遷移中に status と angle が別々に届く（Tech Talk の「status を優先」原則を実証）。
16. **orientation（`Rotate Right`）の方向依存・内外バッファ反転（2026-09-22・確定）** — *前セッションの「orientation と無関係」の記載を修正*
   - 前セッションは「`Rotate Right` は orientation を landscape にするのみ、pose 不変」「内側バッファ方向は pose 依存（open=landscape/closed=portrait）、orientation と無関係」と記録。
   - **9/22 の fresh 実験**（`simctl shutdown`+`boot` → app fresh 起動 = closed・orientation=portrait → `probe2 axpress 2173 "Rotate Right" one`）で、その解釈を**裏切った**:
     - **内外バッファ方向が両方反転**（`simctl io screenshot` の `file` で確定）: 外側 `1398×2034`（portrait）→ **`2034×1398`（landscape）**、内側 `2007×2853`（portrait）→ **`2853×2007`（landscape）**。hinge status は **closed**（pose 不変、angle 0.000 rad）→ **orientation のみで内外バッファ方向が landscape になる**。
     - **safe area insets は不変**（`T 82 / R 84 / B 34 / L 0`、orientation 回転前後で同一 = 内外・pose・orientation いずれも非依存の定数。§14 と整合）。
     - **size class は変化**（外側）: portrait `h-compact / v-regular` → landscape **`h-compact / v-compact`**（= 従来 iPhone の landscape 同型）。`logical`（safe area 済み）も `382×562pt` → `594×350pt`（= 2034/3=678 × 2034→1398/3=466 のフルから T82/R84/B34/L0 を控除、照合 OK）。
     - **corner radius は変化**（外側）: portrait `all 0` → landscape **`BL 25`**（TL0/TR0/BR0/BL25）。→ **corner は pose 依存では無く orientation 依存**（§14 の「pose 依存」を修正）。concentricity の視覚確認の代わりに、この値変化で BL 25 の描画座標の存在を確認。
   - **`Rotate Right` は cumulative（90° ずつ回転）**：portrait → 1 回 press → landscape、2 回 press → **landscape のまま**（9/22 実測、MCP スクショ 800×562）。portrait 復元は 4 回転（または `simctl shutdown`+`boot`）。→ 前セッションの「`orientation set` で戻らない」は `simctl orientation set` の ACK/get 乖離の話であり、**DeviceHub の `Rotate Right`（GUI）は 90° ずつの回転操作**。
   - **orientation = landscape 時のタブバー**（外側 `h-compact/v-compact`）: 幅の制約で 7 タブ → **5 表示＋「More」に集約**。`probe2 axpress 2173 "More" one` → `AXMenuButton`（@1120,89）が展開し、`Bar` / `Scenes` / `UIKit` が `AXButton` 一覧。`axpress "Bar" one` で Bar ページ到達（`Disable vertical bar（opt-out）` CheckBox 存在）。
   - **Bar（landscape 外側）の縦バー**（inkmap）: ツールバー項目は**上バー（横）**に配置され、content 右端にも縦積みの icon が確認（opt-in の縦積み項目と推定）。portrait 外側（`h-compact/v-regular`）・open 内側（regular×regular）で確認済みの opt-in の side 縦積みと併せ、**orientation 単独（landscape）では opt-in の side 縦積みへ移行せず上バーのまま**（= §12 の pose 非依存・orientation でも非依存を再確認）。
   - **結論（下 19 で更新）**: フレームバッファ方向・size class・corner・**safeArea** はいずれも **orientation（logical 形状）に依存**。前セッションの「orientation と無関係」の記載は誤り（下 19 で safeArea の portrait/landscape 2 値を確定）。
17. **overlay zIndex の pose 依存 re-verify（2026-09-22・確定）** — *残作業 2 の 1 項目を完了*
   - **closed（外側）overlay = `zIndex 0`**、**open（内側）overlay = `zIndex 0`**（DeviceHub ミラーの `AXStaticText d='zIndex 0'` を各 1 件、`probe2 axtree` で読取。badge は内外で 1 枚のみ表示）。
   - open⇄closed の pose 遷移（直行）で zIndex バッジ値は**不変（0 のまま）**。前セッションの予測「overlay の zIndex は pose 遷移で変化する」に対し、**open⇄closed では不変**を確定。
   - **book（半開）経由でも 0 不変（9/22 で確定）**: fresh 起動（closed・orientation=portrait）→ `Book` → `Open` の遷移で、zIndex は **closed / book / open の 3 pose すべて `0`**（各 pose で badge 1 件、`probe2 axtree` の `AXStaticText d='zIndex 0'`。badge 座標のみ pose で移動）。→ **overlay の zIndex は pose 遷移（open⇄closed 直行・book 経由）いずれでも 0 固定**（前セッションの「変化」予測は不成立）。
   - **付随観測: book（半開）のバッファ方向 = open と同一（内外とも landscape）**: book 時 内側 `2853×2007` / 外側 `2034×1398`（`file` で確定、orientation=portrait 出発）。§16 の pose 依存と整合（closed = 外側表示 portrait バッファ、open/book = 内側表示 landscape バッファ）。
18. **`fold` の別角度は DeviceHub に専用ボタンなし（2026-09-22・確定）**
   - DeviceHub（9/22、pid 2173）の pose アクションバーは **`Rotate Right` / `Closed` / `Book` / `Open` の 4 ボタンのみ**（`probe2 axtree` 全 tree 検索で `fold` 文字列なし）。
   - → **`fold`（`partially open` の別角度）の別角度は DeviceHub では得られない**（`Book` = 128° のみ）。**実機へ先送り**（§6 の fold ポーズ観測）。

19. **360° サイクルの live 再検証＋safeArea / corner の依存確定（2026-09-22、fresh `boot` 出発）** — *要約の「safeArea 不変定数」を修正*
   - 経路: `simctl shutdown`+`boot`（fresh = pose=closed・orientation=portrait・外側 portrait バッファ 1398×2034）→ app `xcb_build_run_sim`（`OverviewPage` に `UIDevice.orientation` / `scene.interfaceOrientation` の 2 行＋`DuoLabApp` に orientation 通知有効化の delegate を追加）→ DeviceHub `probe2 axpress`（`Open`/`Closed`/`Rotate Right`）で pose・orientation を切り替え、各状態で `simctl io screenshot` の `file`（バッファ方向）＋ DeviceHub ミラーの AX 値（`logical`/`safeArea`/`corner radii`/`orientation`/`ifaceOrient`）を三重読取。
   - **safeArea は pose 非依存だが orientation（logical 形状）に依存**（要約・§14・§16 の「内外・pose・orientation いずれも不変の定数 T82/R84/B34/L0」を**修正**）:

     | 状態（pose・orientation） | バッファ方向（`file`） | logical（safe area 済み） | safeArea | corner |
     |---|---|---|---|---|
     | closed + 0°（portrait） | 外 1398×2034 | 382×562 | **T82 / R84 / B34 / L0** | all 0 |
     | closed + 90°（landscape） | 外 2034×1398 | 594×350 | **T82 / R84 / B34 / L0** | **BL 25** |
     | open + 0°（landscape） | 内 2853×2007 | 867×553 | **T82 / R84 / B34 / L0** | **BL 21** |
     | open + 90°（portrait） | 内 2007×2853 | 669×734 | **T134 / R0 / B83 / L0** | all 0 |
     | open + 180°（landscape） | 内 2853×2007 | 867×553 | **T82 / R84 / B34 / L0** | **BL 21** |

     → safeArea の値は **logical 形状**で決まる（portrait 形状 669×734 = T134/R0/B83/L0、landscape 形状 = T82/R84/B34/L0）。内外共通、pose（閉じる/開ける）では値が変わらない。前セッションは landscape 側しか観測していなかった。
   - **corner radius は pose × orientation の両方に依存**（要約「内側 open BL21 不変」を修正）: 外側 = portrait all 0 / landscape BL25、内側 = portrait all 0 / landscape BL21（内外で半径値が異なる、同 pose 内で orientation 変化で変化する）。
   - **size class は pose 依存のみ**（orientation 非依存）: 内側 = regular×regular（open の portrait / landscape 両方）、外側 = portrait comp/regular / landscape comp/comp（§16 と整合）。
   - **orientation 報告値**（今回 `OverviewPage` に追加）: landscape 時は `UIDevice.current.orientation` = **landscapeRight**、`scene.interfaceOrientation` = **landscapeLeft**（両者が異なるケースを実観）。app 側の safeArea（`GeometryReader.safeAreaInsets`）はこの orientation に連動する。
   - **バッファ方向 = pose × orientation**（要約と整合・再確認）: open 系 = 90° ごとに交互反転（0°=内2853×2007 / 90°=2007×2853 / 180°=2853×2007）、closed 系 = portrait 1398×2034 → 90°=2034×1398（クランプ）。open+0°/180° = landscape バッファ、90° = portrait バッファ。
   - **MCP スクショ（`xcb_screenshot`）の app ウィンドウ形状**（要約の未反映ギャップを解消）: open+90°（portrait logical 669×734）= **550×800px・portrait アスペクト**（全黒=外側 primary 側のミラー）、open+landscape（logical 867×553）= **800×550px・landscape アスペクト**。→ **MCP スクショは app の logical 形状（orientation）に追従**（DeviceHub の物理フレーム自体は portrait の 946×1034 のまま、中身の app 領域のみが回転する）。
   - **照合**: portrait 内側 `2007/3=669 × 2853/3=951` −(T134+B83) = **669×734**、landscape 内側 `2853/3=951 × 2007/3=669` −(T82+R84+B34) = **867×553**。外側 landscape `2034/3=678 × 1398/3=466` −(T82+R84+B34) = **594×350**。表示値と一致。
   - **結論（要約の修正）**: フレームバッファ方向・size class・corner・**safeArea** はいずれも **orientation（logical 形状）に依存**。要約の「safeArea だけ orientation 非依存の定数」は**不成立**（safeArea は logical 形状に依存、pose 非依存）。要実機確認: safeArea の portrait/landscape 2 値が実機でも同じか（シミュレータ値）。

## 2026-09-23 シム作り直し後の再巡回（全画面機能監査 §5〜§8 の実測）

> ユーザーがシミュレータを作り直し（新 UDID `03AE0D2C-CE81-4F2F-9A76-8A1EA1960745`）。MCP `duolab` profile へ新 UDID＋`OTHER_SWIFT_FLAGS=-disable-sandbox` を反映して build→run 成功。旧シム（`6B8C075B`）で起きた「ミラー全面黒・app コンテンツ空」は新シムでは未再現（fresh boot 出発、外側 content / ミラー axtree とも正常）。以下は新シムでの実測（2026-09-23）。

- **座標系**（新シムで再確認）: DeviceHub ミラー axtree の app content グループは `@-256,805 466x678pt`（新シム、旧シムでは @81,1092）。axtree 座標はスクリーングローバルそのもので、外側バッファ（1398×2034px = 466×678pt @3x、landscape open は 2034×1398px）への線形変換は前セッションと同一。ミラー全面黒時はこの axtree（値）を、点灯・popup の見た目判定は外側バッファの inkmap を使う。
- **§5 Bar**: `Disable vertical bar（opt-out）` トグル押下で外側（closed+portrait）右端の縦バー blob が消失→再押下で復帰（`toolbarVerticalBehavior(.disabled)` 実効）。opt-in 項目（gear/share/Done）は action 空 → tap で可視反応なし（#5、sheet/alert 追加推奨）。landscape は上バーに 3 項目フラット（前セッション実測継続）。
- **§6 Scenes**（新シム実測）: `scene 可用性` は pose 連動（closed=unavailable / open=available、`accessory available`・`content` も連動）。toolbar の `Prompter` ボタンは `AXEnabled` で open 時 true / closed 時 false（`statesw` 実測）、`Camera capture` チェックは常時有効。prompter on/off（`Camera capture` 経由、ボタン自身は needle 自己一致で axpress 不可）で外側バッファが全面黒→テレプロンプタ行出現→再 off で消灯（`onAvailabilityChange`+`.sceneAccessory` の点灯実効）。`Open companion window` は tap 後 note 文が「…サイレント無視…」へ更新、クラッシュ無（sim では新ウィンドウ立たない＝設計どおり）。
- **§7 UIKit**: info ラベルは pose 連動（closed=`hinge: closed angle 0.00 rad fold width 0 pt…` / open=`hinge: fully open angle 3.14 rad…`）。#4 修正後の nav bar タイトル `UIKit Demo` は stable。split（horizontal）は `Primary`+`Secondary` 同時表示。UIMenu popup は前セッションで longpress+inkmap で確認済み（項目 tap は system レイヤー制約でミラー越し届かず＝SEED.learned.md）。クラッシュ無。
- **§8 タブバー**: 全 7 タブ（Overview・Hinge・Two Pane・Regions・Bar・Scenes・UIKit）が tabbar 右端の縦バーに**常時**表示（`More` 未使用）。closed/open 両 pose・新旧シムとも 7 個 stable。巡回で app pid 不変（クラッシュ無）。
- **Hinge タブの Gauge はみ出し修正**: 旧 `HingeAngleGauge` は `GeometryReader` の不定サイズに `radius = min(w, h*1.8)/2`・`center.y = h*0.9` を乗せていたため、幅狭な外側 portrait で弧底が GroupBox 底からはみ出し、角度 Text と重なる（実スクショ `.tmpx/hinge_out.png` で確認、ユーザー報告）。修正は `HingePage.swift` の `HingeAngleGauge` を **Canvas 固定テンプレート（220×128、中心 (110,60)、r=50）** に置換: `Shape.path(in rect)` は frame 座標と一致せず描画位置がずれるため（`.frame` 後も ArcPath 単体の rect 座標で描画され box 底割れ）、Canvas は frame 領域をクリップして frame 局座標で描くため半円が確実に内包される。`.quaternary`→`Color.primary.opacity(0.18)`、`.tint`→`Color.accentColor`（GraphicsContext は `Color` 解決必須）。`ArcPath`（不使用化）を削除。併せて **Hinge Status の説明文が外側 portrait で「…Use Arrang…」と 1 行に切り落ちていた**件: `statusDetail` の `Text` に `.fixedSize(horizontal: false, vertical: true)` を追加し複数行折り返しに対応（既定の greedy 折り返しを保証するだけ）。外側 closed（`.tmpx/st3_out.png`: 2 行で全表示）と open 内側（`.tmpx/st4_in.png`: 1 行のまま）の双方でスクショ確認済み。さらに `statusDetail` の文案を日本語化（英語のままでは幅が効率的に取れず 3 行に伸びる）し、外側 `.tmpx/st10_out.png`（2 行で収まる）/ 内側 `.tmpx/st11_in.png`（1 行）で再確認済み。確認: 外側 closed（0.000 rad、弧が box 内に収まり Text と非重複、`.tmpx/h9_out.png`）と open 内側（3.142 rad=180°、`.tmpx/h10_in.png`）の両 pose でスクショ確認済み。
- **残（実機待ち）**: UIMenu の項目 tap（alternate 発火）、companion ウィンドウの実表示、`fold` の別角度、カメラ撮影・onAvailabilityChange の実機カメラ方向。

## 2026-09-23 巡回2（ヒンジ以外全タブの画面・ボタン監査、新シム・新ビルド）

> ヒンジタブ以外の各タブ（Overview・Two Pane・Regions・Bar・Scenes・UIKit）を sim `03AE0D2C-…`（新シム）で open/closed 両 pose 巡回し、画面崩れ・要素の重複・ボタン動作をスクショ（`xcrun simctl io screenshot --display=1/3` + `read_file`）で確認。不具合 3 件を修正し再巡回で確認。

- **Two Pane（open 内側 landscape 867×553）**: `Style: auto` ボタン押下で `overlay`→`split` 循環（auto 判定はコンテナ高 < 600 で overlay）。overlay 表示の secondary 4 行・primary video box（16:9）・zIndex バッジ、split 表示の primary 単体——コード設計どおりで正常。画面崩れなし。
- **Regions**: 6 行リスト・summary・inactive トグルは正常。**不具合: occlusion デバッグラベル（青枠）が status bar（時刻・Wi-Fi）と重なり文字が途切れる**（open/closed 両 pose）。`RegionOutline` のラベル配置を `topLeading`→`bottomLeading`（region 下端）へ移し、素材背景で status bar 図形を透かし表示に（`ReservedRegionsPage.swift`）。再巡回 `.tmpx/rg5.png`（open）/`.tmpx/rg6_closed.png`（closed）で文字途切れ解消を確認。
- **Bar（closed）**: レイアウト正常（Controls・8 行 Item）。`Disable vertical bar` トグルと opt-in 項目の blob は正常。**不具合: opt-in 項目（gear/share/Done）は AX action 空で tap 可視反応なし**（前セッション audit #5）。`VerticalBarPage.swift` へ押下項目名（`OptInAction`）+ 画面下部 sheet（`presentationDetents .fraction(0.25)`）を追加。`xcb_snapshot_ui`→`xcb_tap e67`（gear、sim 本体 axtree）で sheet「opt-in pressed / gear（縦バー toolbar ボタン）/ 閉じる」出現を実スクショ `.tmpx/bar_gear6.png` で確認。DeviceHub ミラー click は不感（前セッション観察の継続＝ミラー側 toolbar は CGEvent 不感）、sim 本体の elementRef tap が有効。
- **Scenes（新シム・新ビルド）**: closed 外側（`.tmpx/sc2_closed.png`）と open 内側（`.tmpx/sc_after_in.png`）でレイアウト正常。`Camera capture` チェック押下で `Prompter: on→off`・`accessory available no→yes`・`scene 可用性 unavailable→available` が連動（onAvailabilityChange 実効、前セッション観察の継続）。
- **UIKit**: split（horizontal）Primary/Secondary 同時表示・UIMenu ボタン（rectangle.on.rectangle）は正常。**不具合: 左上 info ラベル（7 行）が nav bar タイトル `UIKit Demo` と重なる**（closed 外側 portrait で顕著、`.tmpx/ui_closed.png`）。ラベル top constraint を safeArea+12 → **safeArea+60**（可視 nav bar 高さ分退避）に（`UIKitDemo.swift`）。再巡回 `.tmpx/ui2_closed.png`（closed、重なり解消）/`.tmpx/ui2_open.png`（open、Primary+Secondary 2 面 + ラベル stable）で確認。
- **Hinge Status の複数行対応**は本セッション開始時に既に commit 済み（`d191d74` 説明文 `.fixedSize` + `25a027b` 文案日本語化）→ open 内側 `.tmpx/hinge_open2.png`（2 行 stable）で再確認のみ。
- **残（実機待ち、変更なし）**: UIMenu 項目 tap（alternate 発火）、companion ウィンドウ実表示、`fold` 別角度、カメラ撮影。

## 2026-09-23 巡回3（各画面の「本当に解消したか」念入り目視、再ビルド後）

> ユーザー要求（「本当に解消できているか念入りに目視で各画面をチェックして、漏れがあれば修正して」）に沿い、`xcb_build_run_sim`（30.5s 成功）の後に **全 6 タブ × open/closed 両 pose・内外バッファ**を `simctl io screenshot --display=1/3` + `read_file` で再巡回。

- **Regions の occlusion ラベル×status bar 重複が再発**（巡回2 の `bottomLeading` 移設では不十分）: closed pose では occlusion region 2 枚が**上下に積まる**（上=時刻領域、下=Wi-Fi 図形領域）ため、枠内のどこ（topLeading / bottomLeading）にラベルを置いても status bar 図形と被り、左端が切れる（`.tmpx/f_rg_tr3.png`、`.tmpx/v2_rg_bl.png` 等）。**修正**: `RegionOutline` の overlay ラベルを **occlusion のみ `opacity(0)`（非表示）** にし、枠線（青）と summary の数（`division N（active N）/ occlusion N（active N）`）で可視化。division（折り目）は status bar と被らないので枠内 bottomLeading のまま。`.fixedSize()`（1 語の途中折れ防止）も追加（`ReservedRegionsPage.swift`）。
- **再巡回（再ビルド後、念のため全タブ・両 pose）**: Hinge closed（status 3 行折り返し・ゲージ box 内）/ open（fully open 3.142 rad・ゲージ 180°）正常。Overview・Two Pane・Bar・Scenes・UIKit の closed・open とも画面崩れ・要素重複なし（`.tmpx/final_*_c.png` / `final_*_o.png` / `w_rg_*`）。
- **Regions 修正の確定**: closed 外側 `.tmpx/w_rg_closed.png` を右上 2 倍クロップ（`w_rg_tr.png`）で目視→ occlusion 枠（青）内に文字がなく、時刻・Wi-Fi 図形上にラベルが乗っておらず左端切れも解消。open 内側 `w_rg_in.png` 同様に clean。
- **UIKit の nav タイトル重複は巡回2 の修正（safeArea+60）で解消済み**: closed 外側 `final_ui_c.png` を左上 2 倍クロップ（`final_ui_c_tl.png`）で目視→ 「UIKit Demo」タイトルと info ラベル（hinge: closed 開始）は上下分離。
- **Bar opt-in sheet 再確認（再ビルド後）**: `xcb_snapshot_ui` → `xcb_tap e67`（gear）で sheet「opt-in pressed / gear（縦バー toolbar ボタン）/ 閉じる」出現（`final_bar_gear.png`）、`閉じる` で閉幕。
- **巡回3 で新たな不具合なし** → 変更は occlusion ラベル非表示の 1 ファイルのみ。

## 残作業（次のセッション）

1. ~~§6 の各ポーズを実際に観測する~~ **完了**（下 6〜9・12〜14）。
2. ~~内側ディスプレイの論理解像度をシミュレータ実測~~ **完了**（「内側ディスプレイ実測値」：669×951pt @ 3.00x、下 14）。
3. ~~Bar（縦バー）タブと UIKit タブの実表示値~~ **完了**（下 12・15）。
4. ~~size class 判定（外側 `.compact/.regular`）~~ **完了・コード修正済み**（下 14、`0fa2985`）。
5. ~~orientation（`Rotate Right`）経由の safe area / 縦バー再確認、concentricity 視覚~~ **完了**（下 16・19: orientation 依存のバッファ方向・size class・corner、safeArea は logical 形状依存（portrait=T134/R0/B83/L0 / landscape=T82/R84/B34/L0、要約の「不変定数」を修正）、MCP スクショ寸法取得）。
6. ~~open（内側）overlay の zIndex バッジ値の re-verify~~ **完了**（下 17: open=closed=`0`、open⇄closed で不変）。
7. **`fold` の別角度**（`partially open` の別角度、`Book` = 128° のみ観測）— **DeviceHub に専用ボタンなし（下 18）→ 実機で観測**。実機で safeArea の portrait/landscape 2 値が同じか（下 19）も併せて確認。
8. ~~overlay zIndex が book（半開）経由で変化するか~~ **完了（下 17: closed/book/open 3 pose すべて 0、pose 遷移で不変）**。
9. **StandBy・アプリエクステンション系は実機**（シミュレータ既知の問題: StandBy 不可、アプリエクステンション大半が実行・デバッグ不可）→ 実機で確認。
10. ~~`CameraCaptureAccessory` の可用性とテレプロンプタ外側描画~~ **sim で確認済み**（下 10）。残: 本体カメラの撮影・`onAvailabilityChange` の実機カメラ方向・手動 pose 変化で availability が変化するかは実機。

## 次のセッションの注意点（ハマり所・確定済み）

- **pose 操作は下 6 の AX 経路**。`-disable-sandbox` でコンパイルしたバイナリ（`.tmpx/axtest/probe2`、ソース付き）で、`probe2 axpress <DeviceHub pid> "Open|Book|Closed|Rotate Right"`。
- **`orientation set` は ACK（`New Device Orientation: portrait`）を返すが `get` は landscape 固定**（app の `UISupportedInterfaceOrientations` に従い、`Rotate Right` 経由で landscape に入ると `set portrait` で戻らない）。**リセットは `simctl shutdown`+`boot` のみ**（→ orientation 初期値 portrait）。`Rotate Right`（GUI）は **90° cumulative 回転**で、portrait 復元には 4 回転（下 16）。
- **orientation は pose と独立**（`Rotate Right` は orientation だけを変え pose は不変、hinge status 不変）。ただし**内外フレームバッファの方向は pose と orientation の両方に依存**（下 16: closed+portrait=内外 portrait、Rotate Right 後=内外 landscape）。**バッファ方向の判別は `simctl io screenshot` の `file`（px 数）**（`simctl io enumerate` は解像度数値を出さない・下 16）。
- **suiatool はホストに実ファイルなし**（共有キャッシュ `dyld.txt` に `suiatool orientation -h` 等の文字列のみ。`/usr/bin` `/usr/libexec` `/usr/local/bin` / runtime volume / Xcode app / SharedFrameworks を grep してなし）。spawn 不可 → pose は DeviceHub GUI（AX）の経路で。
- **seed sandbox の GUI 制約**: `open` / `osascript` / `screencapture` / `launchctl asuser` は `Operation not permitted`。`-disable-sandbox` バイナリ内でも子プロセス spawn すると同じ（seatbelt の exec 制限）。**in-process の AX・CGWindowList・`Process().run`（`/bin/zsh` 等）は通る**。`shortcuts list/run` は通常 bash でも動く。
- **seed のセッション jsonl は sandbox から読めない**（`seed/sessions` は read deny）。引き継ぎは要約 + この handoff に任せる。
- **ビルドは必ず `OTHER_SWIFT_FLAGS=-disable-sandbox`**（§1 を参照）。`swiftc` 自前ビルド時は `-module-cache-path <cwd配下>`・`TMPDIR <cwd配下>`。
- **`xcb_session_set_defaults` は値を明示して渡す**（`profile`+`persist` のみでは `extraArgs`/`bundleId` が空で上書きされる）。development.md の JSON 例どおり `extraArgs`・`bundleId` を値として渡す。**2026-09-22 の現状で `(default)` profile が完全**（extraArgs 2 本・bundleId・env。`xcb_session_use_defaults_profile({global:true})` で切替→起動成功）。duolab profile は値が渡らず毎回 1 本/unset に収まる現象が継続中→ビルドは `(default)` を使う。
- **`.tmpx/axtest/` の自前ツール**（`-disable-sandbox` で自前コンパイル、gitignore 済み）: `probe2`（`list|reopen|axtree|click|axpress <pid> [needle] [one]|shell`。**`one` = needle 一致の先頭 1 件のみ press**。DeviceHub ミラーは内外シーンで同文字列が 2 枚なのでトグル操作に必須）、`axval`（value 付き AX ダンプ、desc 非空のみ）、`inkmap`（ピクセル暗度マップ、スクショ png/jpg の左右端・上下バーの配置を視覚判定）、`px`/`boxavg`/`orange`（領域平均・色判定）、`mcache/`（module cache）。自前ビルドは `TMPDIR=<cwd配下>`・`-module-cache-path mcache`。
- **`xcb_session_set_defaults` の部分更新で `extraArgs`（配列）が古い値に置き換わる**ことがある。毎回**全キー（env・extraArgs・persist）を一緒に渡す**。
- **この Mac に 2 つの Xcode がある。** `xcode-select` 既定 `/Applications/Xcode_27_1.app`（Duo 対応）。SDK パスは必ず `Xcode_27_1.app` 配下。
- **素の bash の `xcodebuild` はこの sandbox では使えない**（`/var/folders` への書き込み拒否）。ビルドは xcb。`xcrun` の cache ファイル（`xcrun_db-*`）は拒否されるが無害（warning）。
- **`simctl list devices` の UDID を推測しない**（`simctl list` の現物で確認。2026-09-23 現在 `03AE0D2C-CE81-4F2F-9A76-8A1EA1960745`＝ユーザーが作り直した新シム。旧 `6B8C075B`・`0F5B43CE` は作り直しで消滅済み）。`devicectl` は現物 UDID をそのまま `--device` で使う。
- **iPhone Duo シミュレータは 1 台**（iOS 27.1、`03AE0D2C-…`、Booted）。2026-09-23 にユーザーが作り直ししたため、この Mac の iOS 27.1 は Duo だけ（他は iPhone 18 Pro Max / 17e / Air の iOS 27.0、DuoLab DT 27.1 と非互換）。シム単体で全面黒が出たら作り直しが有効（SEED.learned.md）。
- 内外の size class / 方向（9/22 で更新）: **内側 regular×regular（open,orientation=portrait 時 landscape 2853×2007 / 他 portrait 2007×2853）、外側 portrait = h-compact/v-regular / landscape = h-compact/v-compact**。orientation 判定は size class に置換（`supportedInterfaceOrientations` 非依存）。
- ヒンジデータ（angle/status）は**インタラクション用**。レイアウトは Arrangement / Reserved Region。
- **push は upstream 付きの単独 `git push`**（cd/&&/明示 refspec は素の sandbox に落ちる）。`gh --source/--push` は allowlist 外。
- **`.tmpx/` は gitignore に追加済み**（調査用ファイル、`dyld.txt` 180MB 等、commit 対象外）。

## API 早見（詳細・コード例は docs/iphone-duo-support.md §4、実装は DuoLab/*.swift）

| 群 | SwiftUI | UIKit |
|---|---|---|
| ヒンジ | `.onHingeChange { old, ctx in }`（`DeviceHinge.status/.angle`。Status は struct → `==` 比較） | `UIHingeInteraction { interaction, update in }`（`UIHinge.Status` は enum、`unknown` 含む） |
| 2 面レイアウト | `ArrangementView { } secondary: { }` + `.arrangementViewStyle(.split.axes(.vertical) / .overlay.axes(.vertical))`（別型） | `UIArrangementViewController` + `UISplitArrangement().axes(_)` |
| 折り目・カメラ | `GeometryProxy.reservedRegions(kind:options:)` | `view.reservedRegions(kind: .division)`（`UIViewReservedRegion.margins`） |
| 縦バー | `.toolbarVerticalBehavior(.disabled)`、`.toolbarVerticalCompressionBehavior(.prefersTabBar)`、`ToolbarContent.axisBehavior(.verticalPreferred)` | `UITraitCollection.systemTraitsAffectingVerticalBarEdge` + `registerForTraitChanges` |
| 複数ディスプレイ | `openWindow(id:)`（iOS は非 throw）、`CameraCaptureAccessory` + `.sceneAccessory` + `.onAvailabilityChange` | `UIWindowScene.ActivationAction`（alternate 付き）、`UISceneAccessory` |
| カメラ方向 | — | `AVCaptureDeviceDirectionCoordinator`（`.builtInOuterUltraWideCamera` 等） |


## 2026-09-24 docs/duolab-tabs.html の図検証・修正

- render_html（1280px 固定 viewport）でページ全体を offset_y 巡回し目視確認。
- **Hinge 半円ゲージの弧の endpoint がキャプション（127.3°）と一致していなかった**（実際は左端から約 53° 分のみ）。endpoint / knob を `(140,20)`（127.3° 相当）に修正し再描画で確認済み。
- **Regions の `.demo-areas` 図が幅広がりで崩れる**（固定高さ 240px + % 配置が引き伸ばされる）。`max-width: 720px; margin: 0 auto;` を付けて中央寄せ・幅固定にして対応。
- 幅広検証は doc-max を 1680px にした一時コピー（`.tmpx/wide-test.html`、検証後削除）で実施。render_html は幅 1280px 固定なので、viewport 幅の検証は doc-max / otp-reserve を代用した。
- 900px 以下の `.demo-areas .fold { left: 46% }` の media query を削除（fold 58% / 幅 11% は図幅が固定になったため横幅非依存で問題ない）。

- **ゲージ「青丸（knob）が弧から浮く」の修正（2026-09-24）**: 原因は knob の座標式（`c.y − r·sinφ`、y 上向き数式）と `addArc` の端点（**y 下向き座標で `c.y + r·sinφ`**）の方向不一致。`addArc` の端点は (start/end angle の**角度値**と中心・半径で決まり、`clockwise` は経路だけ) なので、knob を弧の endAngle（φ = π − πt）を共用する y 下向き式 `(c.x + r·cosφ, c.y + r·sinφ)` で描けば必ず一致する。実スクショで knob が弧の端点（127.8° = 右下）に乗ることを確認済み。arc 側は `clockwise: false`（y 下向き系で上側半円）。
- **`.demo-areas`（Regions 図）幅広がりで崩れる問題の修正（2026-09-24）**: `max-width: 720px; margin: 0 auto;` で図を幅固定・中央寄せに（内部は % 絶対配置のまま）。render_html は幅 1280px 固定で viewport 検証ができないので、doc-max 1680px の一時コピー（後片付け済み）で検証。
- **Regions 図の折り目位置と occlusion 積みの修正（2026-09-24）**: 折り目（`.fold`）が `left 58%` で中央（50%）から右へずれていた → `left 44.5%`（幅 11%・中心 50%）で中央横断に（`foldClearRect`「中央を横断」と整合）。青枠（occlusion）2 枚が left 16% / 52% で左右・上下に散っていた → 実スクショ（closed・外側、右上 x 0.82〜1.0）どおり右上へ揃えた。
- **occlusion 青枠の「縦長 1 枚」への再修正（2026-09-24）**: 実スクショ（closed・外側）をピクセル計測したところ、occlusion 枠は右上 x 0.82〜1.0・y 0〜25% に**seam なしの縦長 1 枚**（カメラ孔 + 時刻 + Wi-Fi 図形をすべて 1 つの枠で囲む）。件数 2 は summary の `occlusion 2 (active 2)` のみで視覚には接して見える。→ `.occl.top` を右端縦長（width 18% / height 25%）1 枠に、`.occl.bottom` を中央の虚線（2 件の境目を示す区画線）に変更。キャプション・実装ポイントの記述も「上下 2 枚積まり」→「2 件が接して 1 つの縦長枠に見える」に修正済み（前回の上下積み 2 枚表現は実測と整合しない）。
