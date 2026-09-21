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
        let activeFoldWidth = divisions
            .filter(\.isActive)
            .reduce(0) { $0 + $1.frame.width + $1.margins.leading + $1.margins.trailing }

        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.25), .purple.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { row in
                        DemoRow(row: row)
                            // 折り目が active なら領域の幅だけ横へ退避（displacement の最小実装）
                            .offset(x: activeFoldWidth)
                            .padding(.trailing, activeFoldWidth)
                    }
                }
                .padding()
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
