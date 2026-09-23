import SwiftUI

/// §6: 折り目（division）・カメラ（occlusion）の `reservedRegions` をクエリし、
/// 要素を**displacement**（領域から外す）でレイアウトする。
/// 折り目は折りたたまれているときだけ active（フラット時は幅 0・inactive）。
@available(iOS 27.1, *)
struct ReservedRegionsPage: View {
    @State private var includeInactive = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                page(proxy: proxy)
            }
            .overlay(alignment: .bottom) {
                summaryOverlay(proxy: summaryProxy)
                    .padding(8)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("inactive", isOn: $includeInactive)
                        .toggleStyle(.button)
                }
            }
            .navigationTitle("Reserved Regions")
        }
    }

    @State private var summaryProxy = GeometryProxyStub()

    @ViewBuilder
    private func page(proxy: GeometryProxy) -> some View {
        let divisions = proxy.reservedRegions(kind: .division,
                                             options: includeInactive ? [.includeInactive] : [])
        let occlusions = proxy.reservedRegions(kind: .occlusion,
                                               options: includeInactive ? [.includeInactive] : [])
        // 折り目バンドを避けた「クリア側」の矩形。縦バンド／横バンドの両方向に対応。
        let clear = foldClearRect(divisions: divisions, container: proxy.size)

        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.25), .purple.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { row in
                        DemoRow(row: row)
                    }
                }
                .padding()
            }
            // 折り目バンドを横断しないよう、大きいクリア側に丸ごと配置する（displacement）。
            .frame(width: max(clear.width, 0), height: max(clear.height, 0))
            .position(x: clear.midX, y: clear.midY)

            // デバッグ: 折り目の実 frame（view 座標）を表示して、どの辺に置かれるか確認用
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    ForEach(Array(divisions.enumerated()), id: \.offset) { i, region in
                        Text("fold\(i): x\(Int(region.frame.minX)) y\(Int(region.frame.minY)) \(Int(region.frame.width))x\(Int(region.frame.height)) mL\(Int(region.margins.leading)) mR\(Int(region.margins.trailing)) a\(region.isActive ? 1 : 0) contW\(Int(proxy.size.width))")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.red).padding(2).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 3))
                    }
                }.padding(4)
            }

            ForEach(divisions) { region in
                RegionOutline(region: region, color: .red, label: "division")
            }
            ForEach(occlusions) { region in
                RegionOutline(region: region, color: .blue, label: "occlusion")
            }
        }
        .onGeometryChange(for: RegionSummary.self) { geo in
            let d = geo.reservedRegions(kind: .division, options: [.includeInactive])
            let c = geo.reservedRegions(kind: .occlusion, options: [.includeInactive])
            return RegionSummary(
                divisionCount: d.count,
                activeDivisionCount: d.filter(\.isActive).count,
                occlusionCount: c.count,
                activeOcclusionCount: c.filter(\.isActive).count)
        } action: { summary in
            summaryProxy = GeometryProxyStub(summary: summary)
        }
    }

    /// 折り目（division）バンドは表示領域の**中央**を横切り、方向は orientation に依存する。
    ///  - 縦バンド（landscape）: 左右に分割 → 広い側（幅が大きい側）に content を収める
    ///  - 横バンド（portrait） : 上下に分割 → 高い側（高さが大きい側）に content を収める
    /// バンドが inactive / 存在しない場合は全領域を使う。
    private func foldClearRect(divisions: [ReservedRegion], container: CGSize) -> CGRect {
        guard let band = divisions.first(where: { $0.isActive }) else {
            return CGRect(origin: .zero, size: container)
        }
        let f = band.frame
        if f.height >= f.width {
            // 縦バンド → 横方向に退避（左右の広い側）
            let left = CGRect(x: 0, y: 0, width: max(0, min(f.minX, container.width)), height: container.height)
            let right = CGRect(x: max(0, f.maxX), y: 0, width: max(0, container.width - f.maxX), height: container.height)
            return left.width >= right.width ? left : right
        } else {
            // 横バンド → 縦方向に退避（上下の高い側）
            let top = CGRect(x: 0, y: 0, width: container.width, height: max(0, min(f.minY, container.height)))
            let bottom = CGRect(x: 0, y: max(0, f.maxY), width: container.width, height: max(0, container.height - f.maxY))
            return top.height >= bottom.height ? top : bottom
        }
    }

    @ViewBuilder
    private func summaryOverlay(proxy: GeometryProxyStub) -> some View {
        let s = proxy.summary
        Text("division \(s.divisionCount)（active \(s.activeDivisionCount)） / occlusion \(s.occlusionCount)（active \(s.activeOcclusionCount)）")
            .font(.caption2.monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}

/// onGeometryChange が要求する Equatable + Sendable なスナップショット。
@available(iOS 27.1, *)
struct RegionSummary: Equatable, Sendable {
    var divisionCount = 0
    var activeDivisionCount = 0
    var occlusionCount = 0
    var activeOcclusionCount = 0
}

/// 状態格納用のラップ（GeometryProxy 自体は Equatable ではない）。
@available(iOS 27.1, *)
struct GeometryProxyStub: Equatable {
    var summary = RegionSummary()
}

/// 領域の frame（view 座標）を線で囲む可視化レイヤ。
@available(iOS 27.1, *)
private struct RegionOutline: View {
    let region: ReservedRegion
    let color: Color
    let label: String
    var body: some View {
        Rectangle()
            .strokeBorder(color, lineWidth: 2)
            .overlay(alignment: .topLeading) {
                Text("\(label) \(region.isActive ? "active" : "inactive")")
                    .font(.caption2)
                    .foregroundStyle(color)
                    .padding(2)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(2)
            }
            .frame(width: max(region.frame.width, 2), height: max(region.frame.height, 2))
            .position(x: region.frame.midX, y: region.frame.midY)
            .allowsHitTesting(false)
            .opacity(region.isActive ? 1 : 0.35)
    }
}

@available(iOS 27.1, *)
private struct DemoRow: View {
    let row: Int
    var body: some View {
        HStack {
            Image(systemName: "rectangle.grid.2x2")
            Text("Content row \(row)")
            Spacer()
            Text("avoids the crease")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}
