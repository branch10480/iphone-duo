# seed が学んだこと（note_learned が追記。人の規約は SEED.md）

- 2026-09-22: DeviceHub は Dock に無く NSWorkspace.open も -13056 で失敗する。`.tmpx/axtest/probe2 shell '<DeviceHub.app>/Contents/MacOS/DeviceHub &'` で直接起動し、子の DevicesTrampoline が T（停止）なら `kill -CONT <pid>`、ウィンドウが無ければ `probe2 reopen <pid>`
- 2026-09-22: pose 切替は `probe2 axpress <DeviceHub pid> "Open|Book|Closed|Rotate Right" one`。成功は Hinge タブの rad 値（open 3.142 / book 2.226）で二重確認する
- 2026-09-22: `probe2 click` は座標を 2 引数（`click 535 311`）で渡す。カンマ 1 引数だと nil unwrap で落ちる
- 2026-09-22: DeviceHub ミラーの app 領域（@82,636）は app 再起動後に空になることがある。そのときは sim 本体の axtree（`xcb_wait_for_ui textContains`）で値を読む。数分で復帰する
- 2026-09-22: `xcb_tap` は open 時に外側（全黒）ミラーへ落ちて app に届かないことがある。タブ切替は `probe2 axpress <pid> "Two Pane" one` の方が確実
- 2026-09-22: SwiftUI の swiftinterface は `$SDK/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/`（Cryptexes 配下には無い）。UIKit ヘッダは `artifacts/ios27.1-sdk/` に抽出済み
- 2026-09-23: sandbox 内の `swiftc` は `TMPDIR=$PWD/tmpdir -module-cache-path $PWD/tmpdir/mcache` を付ければ通る（`sandbox-exec: sandbox_apply` の警告は無害、exit 0）。docs/development.md の記述どおり。09-22 の「通らない」は module cache の既定パスが拒否されただけだった
- 2026-09-22: `xcrun` の「couldn't create cache file /var/folders/…」は sandbox の TMPDIR 拒否で無害
- 2026-09-23: UIMenu popup は app コンテンツとは別レイヤー（sim ミラー越しの CGEvent click は項目にも外側にも不感。27点 sweep で idle 不変）。メニュー開閉の検証はスクショ上の blob 増減でやる
