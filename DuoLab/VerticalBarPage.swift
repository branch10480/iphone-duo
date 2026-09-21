import SwiftUI

/// §6: 縦バー（Vertical Bar）。上下のバーが側面に縦積みになる opt-in / opt-out の動作を確認。
/// - opt-in: 最新 SDK で再ビルド + 標準ナビゲーション（NavigationStack）のバーを使用
/// - `axisBehavior(.verticalPreferred)`: 項目が縦バーを好む（シンボル単体が向く）
///   ※ `axisBehavior` は **ToolbarContent**（ToolbarItem / ToolbarItemGroup）への modifier。
/// - `toolbarVerticalBehavior(.disabled)`: 縦バー全体を opt-out（全画面再生のような UI）
@available(iOS 27.1, *)
struct VerticalBarPage: View {
    @State private var disableBar = false

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
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                    } label: {
                        Image(systemName: "gear")
                    }
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .axisBehavior(.verticalPreferred)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
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
        }
    }
}
