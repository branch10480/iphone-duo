import SwiftUI

/// §6: 縦バー（Vertical Bar）。上下のバーが側面に縦積みになる opt-in / opt-out の動作を確認。
/// - opt-in: 最新 SDK で再ビルド + 標準ナビゲーション（NavigationStack）のバーを使用
/// - `axisBehavior(.verticalPreferred)`: 項目が縦バーを好む（シンボル単体が向く）
///   ※ `axisBehavior` は **ToolbarContent**（ToolbarItem / ToolbarItemGroup）への modifier。
/// - `toolbarVerticalBehavior(.disabled)`: 縦バー全体を opt-out（全画面再生のような UI）
@available(iOS 27.1, *)
struct VerticalBarPage: View {
    @State private var disableBar = false
    @State private var optInAction: OptInAction?

    /// 押下記録（Identifiable 化して sheet へ）。縦バー側 toolbar ボタンの可視反応。
    struct OptInAction: Identifiable {
        let id = UUID()
        let name: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    GroupBox("Controls") {
                        Toggle("Disable vertical bar（opt-out）", isOn: $disableBar)
                    }
                    GroupBox("Layout") {
                        ForEach(0..<8, id: \.self) { i in
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                Text("Item \(i)")
                                Spacer()
                            }
                            .padding(10)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                // 縦バーを好むシンボル項目。
                // `axisBehavior` は `ToolbarContent` 拡張（ToolbarItem / ToolbarItemGroup が conform）。
                // ToolbarItemGroup の中身は `@ViewBuilder`（some View）なので、
                // 各 ToolbarItem に modifier 付けすると group 制約を満たさない → group 本体に付与。
                // 押下した opt-in 項目の名前だけ記録（sheet 可視反応。AX action 空の検証用の手）
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        optInAction = OptInAction(name: "gear")
                    } label: {
                        Image(systemName: "gear")
                    }
                    Button {
                        optInAction = OptInAction(name: "share")
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .axisBehavior(.verticalPreferred)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        optInAction = OptInAction(name: "Done")
                    } label: {
                        Text("Done")
                    }
                }
                .axisBehavior(.verticalPreferred)
            }
            // 非スクロール UI 向け opt-out（頻繁に切り替えない）
            .toolbarVerticalBehavior(disableBar ? .disabled : .automatic)
            .toolbarVerticalCompressionBehavior(.prefersTabBar)
            .navigationTitle("Vertical Bar")
            // 縦バーの opt-in ボタン（gear / share / Done）は AX action が空で tap の可視反応が
            // 観測できなかった（docs/handoff-next-session.md audit #5）。押下した項目名を
            // sheet で出して、反応したことを画面で確認できるようにする。
            .sheet(item: $optInAction) { action in
                VStack(spacing: 12) {
                    Text("opt-in pressed")
                        .font(.headline)
                    Text("\(action.name)（縦バー toolbar ボタン）")
                        .foregroundStyle(.secondary)
                    Button("閉じる") { optInAction = nil }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .presentationDetents([.fraction(0.25)])
            }
        }
    }
}
