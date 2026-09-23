import SwiftUI
import UIKit
import AVFoundation
import AVKit

/// §6 の UIKit 側 API を1画面にまとめたデモ（SwiftUI の `UIHostingController` で提示）。
/// ヒンジ / Arrangement / ReservedRegion / 縦バー / 複数シーン / カメラ方向 / 角。
///
/// 注: `UIHingeInteraction` / `UIHinge` は `NS_SWIFT_UI_ACTOR`（= MainActor 分離）なので、
/// handler は main 上で実行される。interaction の生成と `view` への追加は `viewDidLoad`（main）で行う。
///
/// 落とし穴: interaction を「保存プロパティ」の初期化子で `self` を capture すると、
/// プロパティ初期化子では `self` が未形成（`() -> UIKitDemo` の thunk）に解決し
/// `self.hingeStatus` 等が見つからなくなる。だから `viewDidLoad` 内で生成する（SDK doc のパターン）。
@available(iOS 27.1, *)
final class UIKitDemo: UIViewController {

    // MARK: State

    private var hingeStatus: UIHinge.Status = .unknown
    private var hingeAngle: CGFloat = 0
    private var foldWidth: CGFloat = 0
    private var verticalBarEdge: UIVerticalBarEdge = .unspecified
    private var forwardCameras: [String] = []
    private var activationFallbackTriggered = false
    private var labelForInfo: UILabel?

    private let arrangementVC = UIArrangementViewController()
    private var directionCoordinator: AVCaptureDeviceDirectionCoordinator?

    // MARK: Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // primary / secondary にコンテンツを配置し、2 面を split で並べる
        let primary = UIHostingController(rootView: DemoPaneText("Primary", .blue))
        let secondary = UIHostingController(rootView: DemoPaneText("Secondary", .orange))
        arrangementVC.setViewController(primary, for: .primary)
        arrangementVC.setViewController(secondary, for: .secondary)
        let nav = UINavigationController(rootViewController: arrangementVC)
        let split = UISplitArrangement().axes(.horizontal)
        arrangementVC.updateArrangement(split)
        addChild(nav)
        nav.view.frame = view.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(nav.view)

        // ヒンジ: interaction を viewDidLoad（main）内で生成 → view に付与。
        // `self.setNeedsLayout()` ではなく `view.setNeedsLayout()`（setNeedsLayout は UIView のもの）。
        let hingeInteraction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            self.hingeStatus = update.hinge?.status ?? .unknown
            self.hingeAngle = update.hinge?.angle ?? 0
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
        view.addInteraction(hingeInteraction)

        // 縦バー: edge 変更を trait 変更通知で観測（leading / trailing は iOS 限定）。
        // `registerForTraitChanges(_ traits:handler:)` は generic（`Self.TraitChangeHandler<Self>`）。
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { [weak self] (env: UIViewController, previous: UITraitCollection) in
            guard let self else { return }
            self.verticalBarEdge = env.traitCollection.verticalBarEdge
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        // カメラ方向: 内外の前面カメラの「向き」を追跡（changeHandler は main queue）。
        let coordinator = AVCaptureDeviceDirectionCoordinator(
            view: view,
            deviceTypes: [.builtInOuterUltraWideCamera, .builtInInnerUltraWideCamera]) { [weak self] map in
            guard let self else { return }
            self.forwardCameras = map.forwardFacingDeviceDescriptors.map(\.localizedName)
            // 実際のアプリではここで AVCaptureSession を再構成する（descriptor は actor へ）
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
        directionCoordinator = coordinator

        // 複数シーン: UIWindowScene.ActivationAction（iOS 15+）。
        // 新ウィンドウが利用不可（外側ディスプレイ等）なら `alternate` に切替。
        let activation = UIWindowScene.ActivationAction(
            title: "Open Companion Window",
            image: UIImage(systemName: "rectangle.on.rectangle"),
            identifier: UIAction.Identifier("duolab.companion"),
            alternate: UIAction(title: "Window unavailable here", image: nil) { [weak self] _ in
                guard let self else { return }
                self.activationFallbackTriggered = true
                // フラグだけ立てても info ラベルは再描画されない（viewDidLayoutSubviews 駆動）。
                // hinge / trait の handler と同じく、layout pass を明示的に要求する。
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            },
        ) { action in
            let config = UIWindowScene.ActivationConfiguration(userActivity: NSUserActivity(activityType: "com.branch10480.duolab.companion"))
            return config
        }
        let menu = UIMenu(title: "Scenes", image: nil, identifier: UIMenu.Identifier("duolab.scenes"), children: [activation])
        let item = UIBarButtonItem(image: UIImage(systemName: "rectangle.on.rectangle"), primaryAction: nil, menu: menu)
        // 注意: self は `nav`（rootViewController = arrangementVC）の「子」なので、
        // self.navigationItem の title / button は可視の nav bar（arrangementVC 側）に出ない。
        // メニューボタン・タイトルは nav スタック内（root の arrangementVC）にセットする。
        arrangementVC.navigationItem.title = "UIKit Demo"
        arrangementVC.navigationItem.rightBarButtonItems = [item]

        // 角: Concentricity の UIKit 側（`UICornerConfiguration`、`containerConcentric`）
        let corner = UICornerConfiguration.corners(
            topLeftRadius: .containerConcentric(),
            topRightRadius: .containerConcentric(),
            bottomLeftRadius: .containerConcentric(),
            bottomRightRadius: .containerConcentric())
        view.cornerConfiguration = corner

        // 情報表示ラベルを最初に1回だけ貼る
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        labelForInfo = label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
        ])
    }

    // MARK: Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 折り目（division）の幅を取得（active な領域だけ計上）
        let folds = view.reservedRegions(kind: .division)
        foldWidth = folds.filter(\.isActive)
            .reduce(0) { $0 + $1.frame.width + $1.margins.left + $1.margins.right }

        // UIKit `UIHinge.Status` は 4 case の enum（unknown 含む）→ switch 可
        let statusText: String
        switch hingeStatus {
        case .unknown: statusText = "hinge: unknown"
        case .closed: statusText = "hinge: closed"
        case .partiallyOpen: statusText = "hinge: partially open"
        case .fullyOpen: statusText = "hinge: fully open"
        @unknown default: statusText = "hinge: ?"
        }
        let info = [
            statusText,
            String(format: "angle %.2f rad", hingeAngle),
            String(format: "fold width %.0f pt", foldWidth),
            "vBar edge: \(edgeName(verticalBarEdge))",
            "forward cameras: \(forwardCameras.isEmpty ? "none" : forwardCameras.joined(separator: ", "))",
            activationFallbackTriggered ? "activation: alternate（未対応場所）" : "activation: idle",
            "scale: \(traitCollection.displayScale)",   // UIScreen.main.scale の置換先
        ].joined(separator: "\n")
        labelForInfo?.text = info
    }

    private func edgeName(_ edge: UIVerticalBarEdge) -> String {
        switch edge {
        case .unspecified: return "unspecified"
        case .leading: return "leading"
        case .trailing: return "trailing"
        @unknown default: return "unknown"
        }
    }
}

@available(iOS 27.1, *)
private struct DemoPaneText: View {
    let text: String
    let color: Color
    init(_ text: String, _ color: Color) { self.text = text; self.color = color }
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.circle.fill").font(.system(size: 40))
            Text(text).font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.15))
    }
}
