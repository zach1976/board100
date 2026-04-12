import UIKit
import Flutter

class ExternalDisplayManager: NSObject {
    static let shared = ExternalDisplayManager()

    private var externalWindow: UIWindow?
    private var mainChannel: FlutterMethodChannel?

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
            let scenes = UIApplication.shared.connectedScenes
            for scene in scenes {
                if let ws = scene as? UIWindowScene {
                    if ws.session.role == .windowExternalDisplayNonInteractive || ws.screen != UIScreen.main {
                        setupExternalWindowScene(ws)
                        break
                    }
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
            teardown()  // Recreate window to pick up any resolution change
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
        mirrorVC.captureChannel = mainChannel
        let screenBounds = windowScene.screen.bounds
        let window = UIWindow(windowScene: windowScene)
        window.frame = screenBounds
        window.rootViewController = mirrorVC
        window.isHidden = false
        self.externalWindow = window
        NSLog("[ExtDisplay] setupExternalWindowScene: \(screenBounds.size)")
    }

    private func setupExternalScreen(_ screen: UIScreen) {
        guard externalWindow == nil else { return }
        let mirrorVC = MirrorViewController()
        mirrorVC.captureChannel = mainChannel
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = mirrorVC
        window.isHidden = false
        self.externalWindow = window
        NSLog("[ExtDisplay] setupExternalScreen: \(screen.bounds.size)")
    }

    private func teardown() {
        externalWindow?.isHidden = true
        externalWindow = nil
    }

    var isConnected: Bool { externalWindow != nil }
}

// MARK: - Mirror ViewController
class MirrorViewController: UIViewController {
    weak var sourceWindow: UIWindow?
    weak var externalWindow: UIWindow?
    var captureChannel: FlutterMethodChannel?
    private var displayLink: CADisplayLink?
    private var imageView: UIImageView!
    private var isCapturing = false
    private var capturingFrames = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView = UIImageView(frame: view.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)

        displayLink = CADisplayLink(target: self, selector: #selector(updateMirror))
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 30, preferred: 20)
        } else {
            displayLink?.preferredFramesPerSecond = 20
        }
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateMirror() {
        if isCapturing {
            capturingFrames += 1
            if capturingFrames > 60 { // ~3s at 20fps — Flutter wasn't ready, retry
                isCapturing = false
                capturingFrames = 0
            }
            return
        }
        capturingFrames = 0
        guard let channel = captureChannel else { return }
        isCapturing = true
        channel.invokeMethod("captureCanvas", arguments: nil) { [weak self] result in
            guard let self = self else { return }
            self.isCapturing = false
            // nil result means nothing changed — keep showing last frame
            guard let bytes = result as? FlutterStandardTypedData,
                  let image = UIImage(data: bytes.data) else { return }

            // If image is portrait, rotate 90° CW so it fills landscape external display
            let imageIsPortrait = image.size.height > image.size.width
            if imageIsPortrait {
                let src = image.size
                let dstSize = CGSize(width: src.height, height: src.width)
                let fmt = UIGraphicsImageRendererFormat()
                fmt.scale = 1.0
                let rotated = UIGraphicsImageRenderer(size: dstSize, format: fmt).image { ctx in
                    ctx.cgContext.translateBy(x: dstSize.width, y: 0)
                    ctx.cgContext.rotate(by: .pi / 2)
                    image.draw(in: CGRect(origin: .zero, size: src))
                }
                self.imageView.image = rotated
            } else {
                self.imageView.image = image
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
    }

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }
}
