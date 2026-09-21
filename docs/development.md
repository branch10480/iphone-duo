# DuoLab の開発手順

この手順はリポジトリの設定と、seed に公開されたMCPの構成に基づく。
過去の観測は [引き継ぎ記録](handoff-next-session.md) に分ける。

## プロジェクトの場所と設定

| 項目 | 値・確認先 |
|---|---|
| 作業ディレクトリ | このリポジトリのルート。絶対パスは `pwd` で確認 |
| 設定の正 | [`project.yml`](../project.yml) |
| Xcodeプロジェクト | `iphone-duo.xcodeproj` |
| アプリtarget / scheme | `DuoLab`。schemeは `xcb_list_schemes` で確認 |
| bundle ID | `com.branch10480.duolab` |
| Deployment target | iOS 27.1（`project.yml`） |
| Swift設定 | `SWIFT_VERSION: 5.10`（`project.yml`） |
| ソース | [`DuoLab/`](../DuoLab/) |
| ビルド成果物 | リポジトリ内の `build/DerivedData/` を指定（追跡外） |

現在の `project.yml` はアプリtargetのみ。テストtargetがあると仮定して `test_sim` を呼ばない。
ソース構成やtargetを変えたときは設定の正を直して再生成する。

## MCPで生成・ビルド・起動する

1. **公開中のtoolを確認する。** seedでMCPが見えなければ `/mcp` で状態を確認する。
   生成は `xcg_generate_project`、以後の操作は `xcb_*`。各toolの引数はそのschemaを正とする。
2. **必要な場合だけプロジェクトを再生成する。** `xcg_generate_project` に
   `specPath=<repo>/project.yml`、`projectDirectory=<repo>` を渡す。どちらも絶対パス。
   `project.yml` の `name: iphone-duo` から `iphone-duo.xcodeproj` が生成される。
   `tool/gen-project.py` は別名の `DuoLab.xcodeproj` を直接書く旧経路なので使わない。
3. **対象を確認する。** `xcb_list_schemes` と `xcb_list_sims` で、`DuoLab` と
   iOS 27.1以上の適切なシミュレータを選ぶ。ヒンジ検証には対応する機種を選び、過去のUDIDを流用しない。
4. **`xcb_session_show_defaults` → `xcb_session_set_defaults` で設定を揃える。**
   プロジェクトの絶対パス、scheme、実在するsimulator ID、リポジトリ内のDerivedDataを指定する。
   対応するXcodeを使うことも確認する。このMacでは `/Applications/Xcode_27_1.app/Contents/Developer`
   が存在することを2026-09-21に確認した。環境の指定方法はtoolのschemaに従う。
   部分更新で配列設定を失わないよう、既存設定を確認し必要な環境・追加引数も保持する。
5. **`xcb_build_sim` でビルドする。** 成功を確認してから `xcb_build_run_sim`、または
   `xcb_get_sim_app_path` → `xcb_install_app_sim` → `xcb_launch_app_sim` で起動する。
   アプリパスは取得結果を使い、DerivedData内のパスを推測しない。
6. **実際の表示を確認する。** `xcb_snapshot_ui` / `xcb_wait_for_ui` / `xcb_screenshot` と
   `xcb_tap` 等を使う。座標は現在のUI情報から決める。必要に応じて起動・ビルド設定を再確認する。

通常のbashによる `xcodebuild` / `simctl` や、独自のプロジェクト生成器への切り替えを
MCP失敗時の既定対応にしない。まず失敗した段階と理由を調べる。

## ビルドが失敗したら

| 症状 | 確認・対応 |
|---|---|
| `SwiftUIMacros.StateMacro` / `swift-plugin-server produced malformed response` と `sandbox_apply: Operation not permitted` が一緒に出る | 過去にコンパイラの子プロセスのsandbox衝突を観測。アプリ実装の修正を始める前に、MCPのビルド追加引数 `OTHER_SWIFT_FLAGS=-disable-sandbox` で解消した記録を参照する。現在のtool schemaと環境で適用できる範囲だけ試す |
| 一時ディレクトリの書き込み拒否 | MCPを経由しているか、DerivedDataがリポジトリ内か、対象Xcodeが正しいかを確認する。権限を広げる回避策へ進まない |
| target / scheme / simulator が見つからない | `project.yml`、生成先、`xcb_list_schemes`、`xcb_list_sims`、session defaultsを照合する |
| MCP toolが見えない・起動しない | seedの `/mcp` に出るサーバー名と理由を確認する。ユーザー設定や常駐の変更は別の作業として扱い、利用できないtool名を捏造しない |

`OTHER_SWIFT_FLAGS=-disable-sandbox` は、過去にseed環境で必要だった**Swiftコンパイラ向け**の設定。
seed全体のsandboxを解除する指示ではない。通常のXcodeに必須と決めつけず、共有の
`project.yml` / pbxprojへ恒久追加しない。再利用するならMCPのmachine-localな設定へ置く。
ハーネス側が注入する追加引数もあるため、既存引数を上書きして消さない。

検索や診断ではstderrと終了コードを残す。`rg` の一致なし、ファイル不在、起動失敗、
権限拒否は別の結果。エラーを捨てたコマンドのexit 0を成功の根拠にしない。

## UI・ヒンジの検証

入口は [`DuoLabApp.swift`](../DuoLab/DuoLabApp.swift)。7タブは次の実装へ辿れる。

| タブ | ソース |
|---|---|
| Overview | [`OverviewPage.swift`](../DuoLab/OverviewPage.swift) |
| Hinge | [`HingePage.swift`](../DuoLab/HingePage.swift) |
| Two Pane | [`TwoPanePage.swift`](../DuoLab/TwoPanePage.swift) |
| Regions | [`ReservedRegionsPage.swift`](../DuoLab/ReservedRegionsPage.swift) |
| Bar | [`VerticalBarPage.swift`](../DuoLab/VerticalBarPage.swift) |
| Scenes | [`ScenesPage.swift`](../DuoLab/ScenesPage.swift) |
| UIKit | [`UIKitDemoPage.swift`](../DuoLab/UIKitDemoPage.swift) / [`UIKitDemo.swift`](../DuoLab/UIKitDemo.swift) |

変更したタブの表示と操作を確認し、共通レイアウトを変えたら全タブを巡回する。
APIの意図と検証項目は [対応リサーチの§4・§6](iphone-duo-support.md) を読む。
表示値を記録するときは機種・runtime・姿勢・向き・確認方法を一緒に残す。

DeviceHubの姿勢切り替えをアプリ画面のtapで操作できるとは限らない。
公開中のMCPで必要な操作ができなければ、ユーザーに対象ウィンドウと操作を具体的に伝え、
操作後のアプリ表示をMCPで確認する。内部識別子の発見だけで操作成功と報告しない。
過去のAXプローブを再実行したり、同じ内部API探索を繰り返したりする前に、
[引き継ぎの観測結果](handoff-next-session.md) を読む。未確認は未確認として残す。

## 記録・一時成果物

- ビルド・起動・対象画面の確認結果と未確認項目を分けて報告する。アプリ変更がない資料編集ならリンクと設定の整合確認でよい。
- 新しい再利用可能な手順はこの文書へ、日時付きの観測や残作業は引き継ぎ記録へ書く。過去の観測を現在も保証される仕様へ書き換えない。
- `.tmpx/`、`build/`、`.xcodebuildmcp/` は追跡外。既存 `.tmpx/` には大きい調査資料がある。全量dumpの再生成や一括削除をせず、必要な範囲だけ読む。
- 一時成果物を新しく作るときは保存先と用途を記録する。後片付けは今回自分が作った不要なものだけを対象にし、残す資料は理由を引き継ぐ。
