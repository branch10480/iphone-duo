import SwiftUI

/// §6: size class 判定（orientation 非依存）/ UIScreen.main 非使用（traitCollection.displayScale）/
/// 非対称 safe area / Concentricity（concentricCornerRadii）。
@available(iOS 27.1, *)
struct OverviewPage: View {
    @Environment(\.horizontalSizeClass) private var hClass
    @Environment(\.verticalSizeClass) private var vClass
    @Environment(\.displayScale) private var displayScale   // UIScreen.main.scale の置換先

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let size = proxy.size
                let safe = proxy.safeAreaInsets
                let radii = proxy.concentricCornerRadii

                VStack(alignment: .leading, spacing: 14) {
                    GroupBox("Size Class（orientation 非依存で判断）") {
                        KeyValue("horizontal", hClass == .regular ? "regular" : "compact")
                        KeyValue("vertical", vClass == .regular ? "regular" : "compact")
                        KeyValue("判定", layoutJudgement)
                    }
                    GroupBox("Display（UIScreen.main を参照しない）") {
                        KeyValue("logical", String(format: "%.0f × %.0f pt", size.width, size.height))
                        KeyValue("scale", String(format: "%.2fx（traitCollection.displayScale）", displayScale))
                        // 左右の inset が等しいと仮定しない（各辺を独立に処理 = §5.6）
                        KeyValue("safeArea", String(format: "T %.0f / R %.0f / B %.0f / L %.0f",
                                                    safe.top, safe.trailing, safe.bottom, safe.leading))
                    }
                    GroupBox("Concentricity（角の追従）") {
                        if let radii {
                            KeyValue("corner radii",
                                     String(format: "TL %.0f / TR %.0f / BR %.0f / BL %.0f",
                                            radii.topLeading, radii.topTrailing,
                                            radii.bottomTrailing, radii.bottomLeading))
                        } else {
                            KeyValue("corner radii", "none（直線コンテナ内）")
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Overview")
        }
    }

    /// 内側ディスプレイは regular×regular（閉じた外側は iPhone 18 Pro と同様の compact）。
    /// orientation ではなく size class で判断する（内側は supportedInterfaceOrientations に従わない）。
    private var layoutJudgement: String {
        switch (hClass, vClass) {
        case (.regular, .regular):
            return "wide / inner-like（2 面レイアウト可用）"
        case (.regular, .compact):
            return "portrait（従来 iPhone）"
        case (.compact, .compact):
            return "narrow / outer-like（閉じた外側）"
        default:
            return "other"
        }
    }
}

@available(iOS 27.1, *)
struct KeyValue: View {
    let key: String
    let value: String
    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }
    var body: some View {
        HStack(alignment: .top) {
            Text(key).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value).multilineTextAlignment(.trailing).monospacedDigit()
        }
        .font(.callout)
    }
}
