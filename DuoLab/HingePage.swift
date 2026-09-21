import SwiftUI

/// §6: ヒンジ観測。`onHingeChange`（SwiftUI）で status / angle を観測し、
/// **インタラクション・エフェクト**に使う（レイアウトは ReservedRegion / Arrangement の担当）。
@available(iOS 27.1, *)
struct HingePage: View {
    @State private var hinge: DeviceHinge?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                GroupBox("Hinge Status") {
                    Text(statusText)
                        .font(.title3.weight(.semibold))
                        .contentTransition(.opacity)
                    Text(statusDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                GroupBox("Hinge Angle（live）") {
                    // エフェクト: 角度で動くゲージ（ラジアン → 0…180° に正規化）
                    HingeAngleGauge(angle: hinge?.angle ?? .zero)
                        .frame(maxWidth: .infinity)
                    Text(angleText)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GroupBox("Driven Effect") {
                    // ヒンジが半開のときにだけ発光する装飾（angle を駆動源にしたエフェクトの例）
                    HingeGlowView(hinge: hinge)
                        .frame(height: 80)
                }

                Spacer()
            }
            .padding()
            // 2 引数（old, new）のシグネチャ（SDK 実読で確認）
            .onHingeChange { _, context in
                hinge = context.hinge
            }
            .navigationTitle("Hinge")
        }
    }

    /// SwiftUI `DeviceHinge.Status` は struct（closed / partiallyOpen / fullyOpen の static var。
    /// `unknown` は UIKit `UIHinge.Status` にのみある）→ switch せず `==` 比較で判定する。
    private var statusText: String {
        guard let status = hinge?.status else { return "no hinge" }
        if status == .closed { return "closed" }
        if status == .partiallyOpen { return "partially open" }
        if status == .fullyOpen { return "fully open" }
        return "unknown"
    }

    private var statusDetail: String {
        hinge == nil
            ? "This hierarchy does not provide hinge updates (e.g. outer display / non-Duo device)."
            : "Hinge data is for interaction & effects. Use Arrangement / Reserved Regions for layout."
    }

    private var angleText: String {
        guard let hinge else { return "—" }
        return String(format: "%.3f rad  (≈ %.1f°)", hinge.angle.radians, hinge.angle.degrees)
    }
}

@available(iOS 27.1, *)
private struct HingeAngleGauge: View {
    let angle: Angle
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            // 0 = 閉（0°）… π = 開（180°）
            let t = min(max(angle.radians / .pi, 0), 1)
            ZStack {
                ArcPath(center: CGPoint(x: w / 2, y: h * 0.9),
                         radius: min(w, h * 1.8) / 2)
                    .stroke(.quaternary, lineWidth: 10)
                ArcPath(center: CGPoint(x: w / 2, y: h * 0.9),
                         radius: min(w, h * 1.8) / 2,
                         fraction: t)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                Circle().fill(.tint).frame(width: 8)
                    .offset(x: -cos(t * .pi) * min(w, h * 1.8) / 2,
                            y: -sin(t * .pi) * min(w, h * 1.8) / 2)
                    .position(x: w / 2, y: h * 0.9)
            }
        }
    }
}

@available(iOS 27.1, *)
private struct ArcPath: Shape {
    var center: CGPoint
    var radius: CGFloat
    var fraction: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(180),
                 endAngle: .degrees(180 - 180 * Double(fraction)),
                 clockwise: true)
        return p
    }
}

/// ヒンジの角度で明るさが変わる装飾。半開（live）のときだけ発光する。
@available(iOS 27.1, *)
struct HingeGlowView: View {
    let hinge: DeviceHinge?

    private var intensity: Double {
        guard let hinge else { return 0 }
        // 閉（0）→開（π）で 0…1（getter は複数文なので明示 return）
        return min(max(hinge.angle.radians / .pi, 0), 1)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink],
                           startPoint: .leading, endPoint: .trailing)
                .opacity(0.15 + 0.85 * intensity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if hinge == nil {
                Text("waiting for hinge…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(format: "intensity %.0f%%", intensity * 100))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
    }
}
