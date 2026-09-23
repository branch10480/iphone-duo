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
    //
    // 座標方向の注意（2026-09-24 修正）: Canvas は UIKit と同じ y 下向き座標。
    // addArc の clockwise は**その座標系**を基準に決まるので、
    // 上側半円（0°=右 … 180°=左）を描くには counterclockwise = true。
    // clockwise: true にすると下側半円を回り、ポインタ（y 上向き式）と弧の端点が
    // 約 2r ずれて「青丸が弧から浮く」実装になる（2026-09-24 実スクショ）。
    // ポインタの端点式は y 上向き数式（c.y - sin・r）なので、上側半円と一致する。
    private static let size = CGSize(width: 220, height: 128)
    private static let center = CGPoint(x: 110, y: 60)
    private static let radius: CGFloat = 50

    var body: some View {
        // 0 = 閉（0°）… π = 開（180°）
        let t = min(max(angle.radians / .pi, 0), 1)
        Canvas { ctx, _ in
            let c = Self.center
            let r = Self.radius
            // 軌道（上側半円）。Canvas は y 下向き座標なので、左端(180°)から
            // 右上端(0°)を「上」越えて回る = 角度増方向 = clockwise: false。
            // clockwise: true にすると「下」側半円を回り、knob（上側設計）と約 2r
            // ずれて「青丸が弧から浮く」実装だった（2026-09-24 実スクショ）。
            var track = Path()
            track.addArc(center: c, radius: r,
                          startAngle: .degrees(180), endAngle: .degrees(0),
                          clockwise: false)
            // Canvas 描画コンテキストでは .quaternary / .tint の解決が不確実なので、
            // 実装色の opacity 表現で同じ見た目（淡い軌道 + アクセント実測線）を再現する。
            ctx.stroke(track, with: .color(Color.primary.opacity(0.18)),
                       style: .init(lineWidth: 10))
            // 実測線: 左端(180°)から t だけ（= 角度の 180° 相当）上越えて進む。
            // endAngle = 180° + 180°·t（角度増方向で正しく 180°·t だけスウィープ）。
            var prog = Path()
            prog.addArc(center: c, radius: r,
                         startAngle: .degrees(180),
                         endAngle: .degrees(180 + 180 * t), clockwise: false)
            ctx.stroke(prog, with: .color(Color.accentColor),
                       style: .init(lineWidth: 10, lineCap: .round))
            // ポインタ = 弧の端点。addArc の端点 (c.x + r·cosθ, c.y + r·sinθ)
            // [θ = 180° + 180°·t] は三角関数の恒等式で
            // (c.x − cos(tπ)·r, c.y − sin(tπ)·r) に一致するので、この式で描く。
            // 16pt にする（旧 8pt は 10pt の round cap に隠れて見えなくなるため）。
            let p = CGPoint(x: c.x - cos(t * .pi) * r, y: c.y - sin(t * .pi) * r)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)),
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
