# seed 専用の指示（AGENTS.md は Claude Code / Codex と共有。seed にだけ効くことはここ）

- ビルド・起動・シミュレータ・UI 操作は `xcb_*`、プロジェクト生成は `xcg_generate_project`。
  tool 名・引数は公開中の schema で確認し、無い tool を推測して呼ばない。
- 画面を見るときは `xcrun simctl io <UDID> screenshot --display=1 .tmpx/shot.png`（外側）/ `--display=3`（内側）で撮り、
  **その PNG を `read_file` で開く**（絵としてそのまま見える。2026-09-23 から）。`xcb_screenshot` は片面のミラーなので
  全面黒になることがあり、app がどちらの面に描かれるかは pose で変わる（closed で外側、2026-09-23 実測）。
  黒なら反対の display を撮る。**inkmap / cropblock / blob 差で画素を数値化して読まない**（learned にその手順が残っていても、
  read_file で見る方を使う）。書き出し先は cwd 配下（`/tmp` は書けない）。
- **`xcb_build_run_sim` の後は必ず Overview タブに戻る。** タブ切替は最初から
  `.tmpx/axtest/probe2 axpress <DeviceHub pid> "Hinge" one; sleep 2` を使う（`xcb_snapshot_ui` → `xcb_tap` は
  「成功」を返しながら画面が変わらないことがあり、2026-09-23 に 1 turn で 2 回、4 反復ずつ無駄にした）。
  切替直後 1 秒はアニメーション中で押下状態が写るので、撮る前に 2 秒待つ。
- UI の値の読み取りは `xcb_wait_for_ui {"predicate":"textContains","text":"…"}`（sim 本体の axtree）が
  DeviceHub ミラーより安定。`xcb_snapshot_ui` → `xcb_tap` を使うなら**同じ反復で続けて**呼ぶ（間に長考が入ると snapshot が失効する）。
- `xcb_install_app_sim` は `appPath` を渡す（`xcb_get_sim_app_path` の結果）。
- 詰まってから抜けた手順は `note_learned` で `SEED.learned.md` に残す（読み込まれた learned の手順は試す前にまず使う）。
