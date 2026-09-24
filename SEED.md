# seed 専用の指示（AGENTS.md は Claude Code / Codex と共有。seed にだけ効くことはここ）

- ビルド・起動・シミュレータ・UI 操作は `xcb_*`、プロジェクト生成は `xcg_generate_project`。
  tool 名・引数は公開中の schema で確認し、無い tool を推測して呼ばない。
- 画面を見るときは `xcrun simctl io <UDID> screenshot --display=1 .tmpx/shot.png`（外側）/ `--display=3`（内側）で撮り、
  **その PNG を `read_file` で開く**（絵としてそのまま見える。2026-09-23 から）。`xcb_screenshot` は片面のミラーなので
  全面黒になることがあり、app がどちらの面に描かれるかは pose で変わる（closed で外側、2026-09-23 実測）。
  黒なら反対の display を撮る。**inkmap / cropblock / blob 差で画素を数値化して読まない**（learned にその手順が残っていても、
  read_file で見る方を使う）。書き出し先は cwd 配下（`/tmp` は書けない）。
- **`xcb_build_run_sim` の後は必ず Overview タブに戻る。** ビルド直後は DeviceHub ミラーの axtree が未反映で
  `probe2 axpress` が pressed:0 になるので、`xcb_wait_for_ui {"predicate":"textContains","text":"<タブ名>"}` →
  `xcb_tap {"elementRef":…,"postDelay":2}` を**同じ反復で**呼ぶ。pose 切替（Open / Closed）の後は
  `.tmpx/axtest/probe2 axpress <DeviceHub pid> "<タブ名>" one; sleep 2` でよい。どちらも「成功」と言いながら
  画面が変わらないことがある（2026-09-23 に 1 turn で 2 回）ので、**撮って切り替わったかを絵で確認してから**次へ進む。
- **修正後の確認は、該当領域を切り出して 2 倍に拡大した画像も `read_file` で見る**
  （`read_file {"path":"x.png","crop":[x0,y0,x1,y1],"scale":2}`。PIL の自作 script は要らない。2026-09-24 から）。全体像だけだと小さい字の欠け（「oc… active」）を見落として「解消」と報告した（2026-09-23 に 2 回）。
- UI の値の読み取りは `xcb_wait_for_ui {"predicate":"textContains","text":"…"}`（sim 本体の axtree）が
  DeviceHub ミラーより安定。`xcb_snapshot_ui` → `xcb_tap` を使うなら**同じ反復で続けて**呼ぶ（間に長考が入ると snapshot が失効する）。
- `xcb_install_app_sim` は `appPath` を渡す（`xcb_get_sim_app_path` の結果）。
- 詰まってから抜けた手順は `note_learned` で `SEED.learned.md` に残す（読み込まれた learned の手順は試す前にまず使う）。
