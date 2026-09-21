import SwiftUI
import UIKit

/// §6: UIKit 側 API（`UIHingeInteraction` / `UIArrangementViewController` / `reservedRegions` /
/// 縦バー trait / `UIWindowSceneActivationAction` / `AVCaptureDeviceDirectionCoordinator` /
/// `UICornerConfiguration`）を1画面で確認するタブ。
@available(iOS 27.1, *)
struct UIKitDemoPage: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitDemo {
        UIKitDemo()
    }
    func updateUIViewController(_ uiViewController: UIKitDemo, context: Context) {}
}
