import UIKit
import Flutter

class ExternalDisplayManager: NSObject {
    static let shared = ExternalDisplayManager()

    private var externalWindow: UIWindow?
    private var externalEngine: FlutterEngine?
    private weak var mainChannel: FlutterMethodChannel?
    private var externalDataChannel: FlutterMethodChannel?

    private override init() { super.init() }

    func setup(channel: FlutterMethodChannel) {
        self.mainChannel = channel

        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidConnect(_:)),
            name: UIScreen.didConnectNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidDisconnect(_:)),
            name: UIScreen.didDisconnectNotification, object: nil
        )

        if #available(iOS 16.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let ws = scene as? UIWindowScene,
                   ws.session.role == .windowExternalDisplayNonInteractive ||
                   ws.screen != UIScreen.main {
                    setupExternalWindowScene(ws)
                    break
                }
            }
            NotificationCenter.default.addObserver(
                self, selector: #selector(sceneDidActivate(_:)),
                name: UIScene.didActivateNotification, object: nil
            )
        }
        if externalWindow == nil && UIScreen.screens.count > 1 {
            setupExternalScreen(UIScreen.screens[1])
        }
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        if #available(iOS 16.0, *) { return }
        setupExternalScreen(screen)
        mainChannel?.invokeMethod("externalDisplayStatus", arguments: ["connected": true])
    }

    @objc private func screenDidDisconnect(_ notification: Notification) {
        teardown()
        mainChannel?.invokeMethod("externalDisplayStatus", arguments: ["connected": false])
    }

    @available(iOS 16.0, *)
    @objc private func sceneDidActivate(_ notification: Notification) {
        guard let ws = notification.object as? UIWindowScene else { return }
        if ws.session.role == .windowExternalDisplayNonInteractive || ws.screen != UIScreen.main {
            setupExternalWindowScene(ws)
            mainChannel?.invokeMethod("externalDisplayStatus", arguments: ["connected": true])
        }
    }

    @available(iOS 16.0, *)
    private func setupExternalWindowScene(_ windowScene: UIWindowScene) {
        guard externalWindow == nil else { return }
        guard let mainWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let mirrorVC = MirrorViewController()
        mirrorVC.sourceWindow = mainWindow
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = mirrorVC
        window.isHidden = false
        self.externalWindow = window
        NSLog("[ExtDisplay] setupExternalWindowScene: mirror \(windowScene.screen.bounds.size)")
    }

    private func setupExternalScreen(_ screen: UIScreen) {
        guard externalWindow == nil else { return }
        if let best = screen.availableModes.max(by: { $0.size.width * $0.size.height < $1.size.width * $1.size.height }) {
            screen.currentMode = best
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let result = self?.createFlutterEngine() else { return }
            let (engine, vc) = result
            let window = UIWindow(frame: screen.bounds)
            window.screen = screen
            window.rootViewController = vc
            window.isHidden = false
            self?.externalWindow = window
            self?.externalEngine = engine
            self?.setupDataChannel(engine: engine)
            NSLog("[ExtDisplay] setupExternalScreen OK: \(screen.bounds.size)")
        }
    }

    private func createFlutterEngine() -> (FlutterEngine, FlutterViewController)? {
        let engine = FlutterEngine(name: "external_display")
        // Try custom entrypoint (works in release), falls back to main (debug mirror)
        engine.run(withEntrypoint: "externalDisplayMain")
        GeneratedPluginRegistrant.register(with: engine)
        let vc = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        return (engine, vc)
    }

    /// Fallback: mirror main screen to external display using snapshotting
    private func setupMirrorFallback(_ screen: UIScreen) {
        // Get main window's layer and mirror it
        guard let mainWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let mirrorVC = MirrorViewController()
        mirrorVC.sourceWindow = mainWindow

        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = mirrorVC
        window.isHidden = false
        self.externalWindow = window
        NSLog("[ExtDisplay] Mirror fallback setup")
    }

    private func setupDataChannel(engine: FlutterEngine) {
        let channel = FlutterMethodChannel(name: "com.zach.tacticsboard/external", binaryMessenger: engine.binaryMessenger)
        self.externalDataChannel = channel
    }

    func sendData(_ jsonString: String) {
        externalDataChannel?.invokeMethod("updateState", arguments: jsonString)
    }

    private func teardown() {
        externalWindow?.isHidden = true
        externalWindow = nil
        externalEngine = nil
        externalDataChannel = nil
    }

    var isConnected: Bool { externalWindow != nil }
}

// MARK: - Mirror ViewController (fallback for debug mode)
class MirrorViewController: UIViewController {
    weak var sourceWindow: UIWindow?
    weak var externalWindow: UIWindow?
    private var displayLink: CADisplayLink?
    private var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        displayLink = CADisplayLink(target: self, selector: #selector(updateMirror))
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 30, preferred: 20)
        } else {
            displayLink?.preferredFramesPerSecond = 20
        }
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateMirror() {
        guard let source = sourceWindow else { return }

        let srcW = source.bounds.width
        let srcH = source.bounds.height
        let scale = source.screen.scale

        // Capture full screen
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: srcW, height: srcH))
        let captured = renderer.image { ctx in
            source.layer.render(in: ctx.cgContext)
        }
        guard let cgFull = captured.cgImage else { return }

        // Determine if landscape (toolbar on right side)
        let isLandscape = srcW > srcH

        // Crop out UI controls, keep only court area
        var cropRect: CGRect
        if isLandscape {
            let sidebarWidth: CGFloat = 190 * scale
            cropRect = CGRect(x: 0, y: 0, width: CGFloat(cgFull.width) - sidebarWidth, height: CGFloat(cgFull.height))
        } else {
            let toolbarHeight: CGFloat = 140 * scale
            cropRect = CGRect(x: 0, y: 0, width: CGFloat(cgFull.width), height: CGFloat(cgFull.height) - toolbarHeight)
        }
        guard let cropped = cgFull.cropping(to: cropRect) else { return }

        // Draw to exact external display pixel size
        let extSize = view.bounds.size
        let outW = max(extSize.width, 960)
        let outH = max(extSize.height, 540)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: outW, height: outH), true, 1.0)
        defer { UIGraphicsEndImageContext() }

        if isLandscape {
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: outW, height: outH))
        } else {
            // Rotate portrait to landscape
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.translateBy(x: outW, y: 0)
            ctx.rotate(by: .pi / 2)
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: outH, height: outW))
        }
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }
}
