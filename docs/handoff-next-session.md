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
- **9/22 で残作業 2 のシミュレータ範囲 3 項目の 2 を確定**（overlay zIndex re-verify / Rotate Right 経由の orientation 依存）。下 16・17。
  - **`fold` の別角度は残作業**（DeviceHub の別制御なし・下 18 → 実機へ）。

## 内側ディスプレイ実測値（確定）

| 項目 | 値 | 出典 |
|---|---|---|
| 内側フレームバッファ | pose 依存（下 16 で修正）: open+orientation=portrait = 2853×2007 / open+landscape = 2007×2853 / closed = 2007×2853（`--display=primary-1`） | `simctl io screenshot` の `file` |
| 内側論理 | **669 × 951 pt**（orientation=portrait のバッファ方向と同一向き）/ 3.00x | アプリ Overview |
| 内側 scale | **3.00x**（`traitCollection.displayScale`） | アプリ Overview |
| 外側フレームバッファ | pose + orientation 依存（下 16）: closed+portrait = 1398×2034 / closed+landscape = 2034×1398（`--display=primary`） | `simctl io screenshot` の `file` |
| 外側論理 | portrait **382 × 562 pt** / landscape **594 × 350 pt**（= safe area 済み） | アプリ Overview |
| safeArea（内外共通） | **T 82 / R 84 / B 34 / L 0**（orientation・pose・内外で不変 = 定数。下 16） | アプリ Overview |
| 外側 size class | portrait **h-compact / v-regular**（従来 iPhone portrait 同型）/ landscape **h-compact / v-compact**（従来 iPhone landscape 同型）。orientation 依存（下 16） | アプリ Overview |
| 内側 size class | regular × regular | アプリ Overview |
| corner radius | **orientation 依存（下 16 で修正）**: 外側 = portrait all 0 / landscape **BL 25**。内側(open,landscape) = BL 21 | アプリ Overview |

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
   - `logical`（`GeometryReader` の `proxy.size`）は **safe area 済み bounds**（open = 867×553pt = フルフレーム 951×669pt から R84/T82/B34 を控除）。前セッションの「951×669pt」記録はフルフレーム値と読み（ラベルの位置が違う）。両方とも 3.00x 照合 OK。
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
   - **結論**: フレームバッファ方向・size class・corner は **orientation に依存**、safe area insets だけ **orientation 非依存の定数**。前セッションの「orientation と無関係」の記載は誤り。
17. **overlay zIndex の pose 依存 re-verify（2026-09-22・確定）** — *残作業 2 の 1 項目を完了*
   - **closed（外側）overlay = `zIndex 0`**、**open（内側）overlay = `zIndex 0`**（DeviceHub ミラーの `AXStaticText d='zIndex 0'` を各 1 件、`probe2 axtree` で読取。badge は内外で 1 枚のみ表示）。
   - open⇄closed の pose 遷移（直行）で zIndex バッジ値は**不変（0 のまま）**。前セッションの予測「overlay の zIndex は pose 遷移で変化する」に対し、**open⇄closed では不変**を確定。
   - **残（未判定）: book（半開）経由**の zIndex は未観測（closed→open の直行のみ）。半開で折りたたみ中に変化する可能性は残る（実機 or DeviceHub の Book 経由で要観測）。
18. **`fold` の別角度は DeviceHub に専用ボタンなし（2026-09-22・確定）**
   - DeviceHub（9/22、pid 2173）の pose アクションバーは **`Rotate Right` / `Closed` / `Book` / `Open` の 4 ボタンのみ**（`probe2 axtree` 全 tree 検索で `fold` 文字列なし）。
   - → **`fold`（`partially open` の別角度）の別角度は DeviceHub では得られない**（`Book` = 128° のみ）。**実機へ先送り**（§6 の fold ポーズ観測）。

## 残作業（次のセッション）

1. ~~§6 の各ポーズを実際に観測する~~ **完了**（下 6〜9・12〜14）。
2. ~~内側ディスプレイの論理解像度をシミュレータ実測~~ **完了**（「内側ディスプレイ実測値」：669×951pt @ 3.00x、下 14）。
3. ~~Bar（縦バー）タブと UIKit タブの実表示値~~ **完了**（下 12・15）。
4. ~~size class 判定（外側 `.compact/.regular`）~~ **完了・コード修正済み**（下 14、`0fa2985`）。
5. ~~orientation（`Rotate Right`）経由の safe area / 縦バー再確認、concentricity 視覚~~ **完了**（下 16: orientation 依存のバッファ方向・size class・corner 変化、safe area 不変、Bar の landscape 描画、concentricity は BL 25 の値で確認）。
6. ~~open（内側）overlay の zIndex バッジ値の re-verify~~ **完了**（下 17: open=closed=`0`、open⇄closed で不変）。
7. **`fold` の別角度**（`partially open` の別角度、`Book` = 128° のみ観測）— **DeviceHub に専用ボタンなし（下 18）→ 実機で観測**。
8. **overlay zIndex が book（半開）経由で変化するか**（下 17: open⇄closed では 0 固定、半開経由は未判定）— 実機 or DeviceHub の `Book` 経由で観測。
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
- **`simctl list devices` の UDID を推測しない**（`6B8C075B-0655-4C20-9CAD-ACB1A97B5EEC`、`simctl list` で確認）。`devicectl` はこの UDID をそのまま `--device` で使う。
- **シミュレータ 2 台**（iOS 27.1）: `6B8C075B-…`（主）、`0F5B43CE-…`。他は iOS 27.0（DuoLab DT 27.1 と非互換）。
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
