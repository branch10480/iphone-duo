import SwiftUI
import UIKit

final class DuoLabDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // orientation 変化通知の有効化（OverviewPage が safeArea の依存軸として観測用）
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        return true
    }
}

@main
@available(iOS 27.1, *)
struct DuoLabApp: App {
    @UIApplicationDelegateAdaptor(DuoLabDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // 複数シーン（§6）: 副ウィンドウ。`Window` は iOS で利用不可（macOS/visionOS のみ）なので、
        // `WindowGroup(id:)` を使って複数インスタンスにする。外側ディスプレイでは新ウィンドウを作れないため、
        // 要求が無効な場所では無視される（ScenesPage が明記。UIKit 側の `UIWindowScene.ActivationAction` は、
        // 利用不可ならアクション自体を非表示にする）。
        WindowGroup("Companion", id: "companion") {
            CompanionView()
        }
    }
}

@available(iOS 27.1, *)
struct RootView: View {
    var body: some View {
        TabView {
            OverviewPage()
                .tabItem { Label("Overview", systemImage: "info.circle") }
            HingePage()
                .tabItem { Label("Hinge", systemImage: "arrow.turn.up.left") }
            TwoPanePage()
                .tabItem { Label("Two Pane", systemImage: "rectangle.split.2x1") }
            ReservedRegionsPage()
                .tabItem { Label("Regions", systemImage: "rectangle.split.3x1") }
            VerticalBarPage()
                .tabItem { Label("Bar", systemImage: "line.3.horizontal.toplefttobottomright.circle") }
            ScenesPage()
                .tabItem { Label("Scenes", systemImage: "rectangle.on.rectangle") }
            UIKitDemoPage()
                .tabItem { Label("UIKit", systemImage: "wrench.and.screwdriver") }
        }
    }
}

@available(iOS 27.1, *)
struct CompanionView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                Text("Companion Window")
                    .font(.title2.bold())
                Text("This is a second scene (multi-instance iPhone). New windows can only be created on the inner display.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Companion")
        }
    }
}
