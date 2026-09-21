import SwiftUI

/// §6: 2 面レイアウト。`ArrangementView`（split / overlay）で primary・secondary を並べる。
/// 内側（regular×regular）では split、外側（narrow）では overlay に切り替える。
@available(iOS 27.1, *)
struct TwoPanePage: View {
    @State private var useSplit = true

    var body: some View {
        NavigationStack {
            Group {
                // `.split` / `.overlay` は別型（Any* の型を束ねる型は無い）→ if/else で分岐
                if useSplit {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(useSplit ? "Switch to overlay" : "Switch to split") {
                        withAnimation { useSplit.toggle() }
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
            ForEach(titles, id: \.self) { t in
                Label(t, systemImage: "music.note")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.orange.opacity(0.10))
    }
}
