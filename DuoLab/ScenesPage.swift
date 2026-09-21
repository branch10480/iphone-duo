import SwiftUI

/// §6: 複数シーン / Scene Accessory。
/// - 複数インスタンス対応 iPhone: 副ウィンドウ（`WindowGroup(id:)`）を `openWindow` で要求。
///   **iOS では `openWindow(id:)` は非 throw**（`sharingBehavior` 付きの throw 版は macOS 15+ のみ）。
///   外側ディスプレイでは新ウィンドウを作れないため、要求は**サイレントに無視**される。
///   明示的な fallback（`UIWindowScene.ActivationAction` の `alternate`）は UIKit タブで実演。
/// - `CameraCaptureAccessory` + `onAvailabilityChange`: カメラ撮影中の外側ディスプレイへ副コンテンツ。
@available(iOS 27.1, *)
struct ScenesPage: View {
    @Environment(\.openWindow) private var openWindow
    @State private var prompterEnabled = true
    @State private var prompterAvailable = false
    @State private var lastRequestNote: String = "（未要求）"

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                GroupBox("Multi-window") {
                    Button("Open companion window") {
                        // 非 throw：外側ディスプレイでは何も起こらない（エラーは投げられない）。
                        openWindow(id: "companion")
                        lastRequestNote = "openWindow(id: \"companion\") を要求。外側ディスプレイでは新ウィンドウ不可 → サイレント無視（UIKit タブの ActivationAction が明示 fallback の例）"
                    }

                    Text(lastRequestNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    KeyValue2("scene 可用性", prompterAvailable ? "available" : "unavailable")
                }

                // Scene Accessory: カメラ撮影 UI（内側）→ テレプロンプタ（外側）
                PrompterPreview(enabled: $prompterEnabled, available: $prompterAvailable)
                    .padding()

                Spacer()
            }
            .padding()
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $prompterEnabled) {
                    TeleprompterView(enabled: prompterEnabled)
                }
                .onAvailabilityChange { prompterAvailable = $0 }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Prompter: \(prompterEnabled ? "on" : "off")") {
                        prompterEnabled.toggle()
                    }
                    .disabled(!prompterAvailable)
                }
            }
            .navigationTitle("Scenes")
        }
    }
}

@available(iOS 27.1, *)
private struct PrompterPreview: View {
    @Binding var enabled: Bool
    @Binding var available: Bool
    var body: some View {
        GroupBox("Scene Accessory（テレプロンプタ）") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Camera capture", isOn: $enabled)
                KeyValue2("accessory available", available ? "yes" : "no")
                KeyValue2("content", enabled && available ? "TeleprompterView → outer display" : "—")
            }
        }
    }
}

@available(iOS 27.1, *)
private struct KeyValue2: View {
    let k: String, v: String
    init(_ k: String, _ v: String) { self.k = k; self.v = v }
    var body: some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v)
        }
        .font(.callout)
    }
}

/// 外側ディスプレイに表示されるテレプロンプタ（副シーンの中身）。
@available(iOS 27.1, *)
struct TeleprompterView: View {
    let enabled: Bool
    var body: some View {
        if enabled {
            let text = (0..<5).map { "The quick brown fox \($0) jumps over the lazy dog." }.joined(separator: "\n\n")
            ScrollView(.vertical) {
                Text(text)
                    .font(.title3)
                    .padding()
            }
        } else {
            Text("prompter off")
                .foregroundStyle(.secondary)
        }
    }
}
