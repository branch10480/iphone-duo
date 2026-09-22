# seed 専用の指示（AGENTS.md は Claude Code / Codex と共有。seed にだけ効くことはここ）

- ビルド・起動・シミュレータ・UI 操作は `xcb_*`、プロジェクト生成は `xcg_generate_project`。
  tool 名・引数は公開中の schema で確認し、無い tool を推測して呼ばない。
- `xcb_screenshot` の画像はそのまま見える（引数なしで呼ぶ）。ただし **pose が open / book のときは
  外側ディスプレイのミラーなので全面黒**が正常。内側の描画を見るときは `xcrun simctl io <UDID> screenshot --display=primary-1`
  と `.tmpx/axtest/inkmap` で画素を読む（2026-09-22 に 2 turn で実測）。
- UI の値の読み取りは `xcb_wait_for_ui {"predicate":"textContains","text":"…"}`（sim 本体の axtree）が
  DeviceHub ミラーより安定。`xcb_snapshot_ui` → `xcb_tap` は**同じ反復で続けて**呼ぶ（間に長考が入ると snapshot が失効する）。
- `xcb_install_app_sim` は `appPath` を渡す（`xcb_get_sim_app_path` の結果）。
- 詰まってから抜けた手順は `note_learned` で `SEED.learned.md` に残す（読み込まれた learned の手順は試す前にまず使う）。
