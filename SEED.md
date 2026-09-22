# seed 専用の指示（AGENTS.md は Claude Code / Codex と共有。seed にだけ効くことはここ）

- ビルド・起動・シミュレータ・UI 操作は `xcb_*`、プロジェクト生成は `xcg_generate_project`。
  tool 名・引数は公開中の schema で確認し、無い tool を推測して呼ばない。
- `xcb_screenshot` の画像はそのまま見える（引数なしで呼ぶ）。引き継ぎ文書にある
  `.tmpx/axtest/` の `inkmap` / `boxavg` で画素を読む手順は、画像が届かなかった頃の回避策なので使わない。
