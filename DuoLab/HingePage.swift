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
                        // 幅狭な外側 portrait では 1 行で収まらず端が…で
                        // 切り落ちる（2026-09-23 外側スクショで確認）。
                        // 既定は greedy 折り返しなので明示は不要だが、
                        // lineLimit(1) 等の追加時に 1 行固定に戻さないよう注記。
                        .fixedSize(horizontal: false, vertical: true)
                }

                GroupBox("Hinge Angle（live）") {
                    // エフェクト: 角度で動くゲージ（ラジアン → 0…180° に正規化）。
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
        guard hinge != nil else {
            return "この階層はヒンジ更新を提供していません（外側ディスプレイなど）。レイアウト判断は Arrangement / Reserved Regions を使います。"
        }
        return "ヒンジデータはインタラクション・エフェクト用です。レイアウト判断は Arrangement / Reserved Regions を使います。"
    }

    private var angleText: String {
        guard let hinge else { return "—" }
        return String(format: "%.3f rad  (≈ %.1f°)", hinge.angle.radians, hinge.angle.degrees)
    }
}

@available(iOS 27.1, *)
private struct HingeAngleGauge: View {
    let angle: Angle

    // 半円ゲージを固定テンプレート（220×128）の Canvas 局座標で描く。
    // 旧実装は GeometryReader の不定サイズに radius = min(w, h*1.8)/2 を乗せて
    // center.y = h*0.9 だったので、幅狭な面（外側 portrait など）だと radius 側が
    // h 依存になり弧の底が GroupBox 底からはみ出していた（2026-09-23 実スクショ）。
    // Shape の path(in rect) は frame 原点と座標が一致しないことがあり（実スクショで
    // 確認）、Canvas は frame 領域をクリップして canvas 座標で描くので、半円が
    // frame 内に完全に内包される。半円は中心から上下 ±55pt（r50 + stroke5）：
    // center=(110,60)、r=50 で弧は y=5..115・x=55..165、frame 高 128 の中に収まる。
    private static let size = CGSize(width: 220, height: 128)
    private static let center = CGPoint(x: 110, y: 60)
    private static let radius: CGFloat = 50

    var body: some View {
        // 0 = 閉（0°）… π = 開（180°）
        let t = min(max(angle.radians / .pi, 0), 1)
        Canvas { ctx, _ in
            let c = Self.center
            let r = Self.radius
            var track = Path()
            track.addArc(center: c, radius: r,
                          startAngle: .degrees(180), endAngle: .degrees(0),
                          clockwise: true)
            // Canvas 描画コンテキストでは .quaternary / .tint の解決が不確実なので、
            // 実装色の opacity 表現で同じ見た目（淡い軌道 + アクセント実測線）を再現する。
            ctx.stroke(track, with: .color(Color.primary.opacity(0.18)),
                       style: .init(lineWidth: 10))
            var prog = Path()
            prog.addArc(center: c, radius: r,
                         startAngle: .degrees(180),
                         endAngle: .degrees(180 - 180 * t), clockwise: true)
            ctx.stroke(prog, with: .color(Color.accentColor),
                       style: .init(lineWidth: 10, lineCap: .round))
            // ポインタ（端点 8pt）
            let p = CGPoint(x: c.x - cos(t * .pi) * r, y: c.y - sin(t * .pi) * r)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)),
                     with: .color(Color.accentColor))
        }
        .frame(width: Self.size.width, height: Self.size.height)
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
