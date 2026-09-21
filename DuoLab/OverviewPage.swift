import SwiftUI

/// §6: size class 判定（orientation 非依存）/ UIScreen.main 非使用（traitCollection.displayScale）/
/// 非対称 safe area / Concentricity（concentricCornerRadii）。
@available(iOS 27.1, *)
struct OverviewPage: View {
    @Environment(\.horizontalSizeClass) private var hClass
    @Environment(\.verticalSizeClass) private var vClass
    @Environment(\.displayScale) private var displayScale   // UIScreen.main.scale の置換先
    @State private var deviceOrientation = UIDevice.current.orientation
    @State private var interfaceOrientation = "n/a"

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
                        // safeArea の依存軸の分離用（orientation の報告値）
                        KeyValue("orientation", deviceOrientation.rawValueLabel)
                        KeyValue("ifaceOrient", interfaceOrientation)
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
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
        .onAppear { updateOrientation() }
    }

    /// 現在の orientation を報告値に反映する。
    private func updateOrientation() {
        deviceOrientation = UIDevice.current.orientation
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            interfaceOrientation = scene.interfaceOrientation.label
        } else {
            interfaceOrientation = "no-scene"
        }
    }

    /// 実測（2026-09-21、sim）:
    /// - 内側（open）= regular×regular → wide
    /// - 外側（closed）= **h-compact / v-regular**（従来 iPhone の portrait 同型。orientation ではなく size class で判断 = §5.2）
    /// orientation 判定に置換する（内側は `supportedInterfaceOrientations` に従わない）。
    private var layoutJudgement: String {
        switch (hClass, vClass) {
        case (.regular, .regular):
            return "wide / inner-like（2 面レイアウト可用）"
        case (.compact, .regular):
            return "narrow / outer-like（閉じた外側 = 従来 iPhone portrait）"
        case (.regular, .compact), (.compact, .compact):
            return "従来 iPhone（landscape 側。Duo では未観測）"
        default:
            return "other"
        }
    }
}

extension UIDeviceOrientation {
    var rawValueLabel: String {
        switch self {
        case .unknown: return "unknown"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        @unknown default: return "raw(\(rawValue))"
        }
    }
}

extension UIInterfaceOrientation {
    var label: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        @unknown default: return "raw(\(rawValue))"
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
