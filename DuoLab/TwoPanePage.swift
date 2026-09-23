import SwiftUI

/// §6: 2 面レイアウト。`ArrangementView`（split / overlay）で primary・secondary を並べる。
///
/// **2026-09-22 巡回修正（docs/audit-2026-09-22.md #1）**:
/// - 実測: 内側（regular×regular）で `.split.axes(.vertical)` は **pane が収まらなければ secondary を非表示にする**。
///   video box（16:9・幅 835pt → 高 470pt）が 2 段 slot（276pt）を超過する landscape（867×553）では secondary 消滅、
///   portrait（669×734）では表示 → 既定が split だと「分割されるのにされていない」状態が orientation で出る。
/// - 修正: primary の video box に高さ上限 200 を置く（pane の理想高を有界に）＋ コンテナ高の実測（閾値 600）で
///   2 段に収まらない場合は `.overlay`（secondary は常に前面表示）へ自動切替。手動切替も保持。
@available(iOS 27.1, *)
struct TwoPanePage: View {
    enum PaneStyle: String, CaseIterable, Hashable {
        case automatic = "auto"
        case split = "split"
        case overlay = "overlay"
    }

    @State private var manualStyle: PaneStyle = .automatic
    @State private var containerSize: CGSize = .zero

    /// 両 pane の必要高の下限（primary: video 上限 200 + タイトル ≈ 252 / secondary: ヘッダ + 4 行 ≈ 234、合計 486 + パディング）。
    /// 実測 2 値: landscape 867×553 / portrait 669×734 → 553 < 600 なら overlay、734 ≥ 600 なら split。
    /// これ未満では `.split` は secondary を非表示にする（実測）→ `.overlay` に切替えて両方を残す。
    private static let minSplitHeight: CGFloat = 600

    private var effectiveStyle: PaneStyle {
        guard manualStyle == .automatic else { return manualStyle }
        return containerSize.height >= Self.minSplitHeight ? .split : .overlay
    }

    var body: some View {
        NavigationStack {
            Group {
                // `.split` / `.overlay` は別型（Any* の型を束ねる型は無い）→ if/else で分岐
                if effectiveStyle == .split {
                    ArrangementView {
                        PlayerPane()
                    } secondary: {
                        UpNextPane()
                    }
                    .arrangementViewStyle(.split.axes(.vertical))
                } else {
                    ArrangementView {
                        PlayerPane()
                    } secondary: {
                        UpNextPane()
                    }
                    .arrangementViewStyle(.overlay.axes(.vertical))
                }
            }
            // コンテナ高（safe area 済み）で自動スタイルを決定する
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                containerSize = size
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // auto → overlay → split → auto … と循環。auto の場合は実効スタイルも表示。
                    Button(manualStyle == .automatic
                           ? "Style: auto → \(effectiveStyle.rawValue)"
                           : "Style: \(manualStyle.rawValue)") {
                        withAnimation {
                            let all = PaneStyle.allCases
                            let next = (all.firstIndex(of: manualStyle)! + 1) % all.count
                            manualStyle = all[next]
                        }
                    }
                }
            }
            .overlayArrangementZIndexLabel()
            .navigationTitle("Two Pane")
        }
    }
}

/// overlay 時の Z 索引（折りたたまれると変化する）を画面隅に表示する。
@available(iOS 27.1, *)
extension View {
    func overlayArrangementZIndexLabel() -> some View {
        overlay(alignment: .bottomTrailing) {
            OverlayZIndexBadge()
                .padding(8)
        }
    }
}

@available(iOS 27.1, *)
private struct OverlayZIndexBadge: View {
    @Environment(\.overlayArrangementZIndex) private var zIndex
    var body: some View {
        Text("zIndex \(zIndex)")
            .font(.caption2.monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}

@available(iOS 27.1, *)
private struct PlayerPane: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.blue.gradient)
                .aspectRatio(16 / 9, contentMode: .fit)
                // 高さ上限なしだと理想高 = 幅×9/16（Duo 内側 landscape 835pt 幅 → 470pt）で
                // pane が slot に収まらず `.split` が secondary を非表示にしていた（実測）。
                // 上限 200 にすると pane の理想高は有界（≈252pt）→ 外側（landscape 350pt 級）でも 2 段が成立する。
                .frame(maxWidth: .infinity, maxHeight: 200)
                .overlay {
                    Image(systemName: "play.fill").font(.largeTitle).foregroundStyle(.white)
                }
            Text("Primary: Now Playing").font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blue.opacity(0.12))
    }
}

@available(iOS 27.1, *)
private struct UpNextPane: View {
    private let titles = ["Up Next 1", "Up Next 2", "Up Next 3", "Up Next 4"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Secondary: Up Next").font(.headline)
            // Spacer ではなくスクロール: pane が矮小（外側・landscape 等）でも一覧は到達可能
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(titles, id: \.self) { t in
                        Label(t, systemImage: "music.note")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.orange.opacity(0.10))
    }
}
