import Flutter
import UIKit
import Vision
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SharePlugin") {
      setupShareChannel(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ExternalDisplayPlugin") {
      setupExternalDisplayChannel(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FaceDetectionPlugin") {
      setupFaceDetectionChannel(with: registrar)
    }
  }

  private func setupShareChannel(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.zach.tacticsboard/share", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { (call, result) in
      if call.method == "shareFile" {
        if let args = call.arguments as? [String: Any], let path = args["path"] as? String {
          self.shareFile(path: path)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing path", details: nil))
        }
      } else if call.method == "openUrl" {
        if let args = call.arguments as? [String: Any], let urlString = args["url"] as? String,
           let url = URL(string: urlString) {
          UIApplication.shared.open(url, options: [:]) { success in
            result(success)
          }
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing url", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Face Detection (Apple Vision)

  private func setupFaceDetectionChannel(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.zach.tacticsboard/faceDetection",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { (call, result) in
      if call.method == "detectFaces" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing path", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          self.detectFaces(at: path) { faces, error in
            DispatchQueue.main.async {
              if let error = error {
                result(FlutterError(code: "DETECT_FAILED", message: error.localizedDescription, details: nil))
              } else {
                result(faces ?? [])
              }
            }
          }
        }
      } else if call.method == "dedupeFacePaths" {
        guard let args = call.arguments as? [String: Any],
              let paths = args["paths"] as? [String] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing paths", details: nil))
          return
        }
        let threshold = (args["threshold"] as? Double).map(Float.init) ?? 18.0
        let sourceIds = (args["sourceIds"] as? [Int]) ?? Array(repeating: 0, count: paths.count)
        DispatchQueue.global(qos: .userInitiated).async {
          let keep = self.dedupeFacePaths(
            paths: paths, sourceIds: sourceIds, threshold: threshold
          )
          DispatchQueue.main.async { result(keep) }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// For a list of cropped face image files, returns a parallel array of
  /// booleans indicating whether each crop should be kept (true) or dropped
  /// as a near-duplicate of an earlier kept crop (false).
  ///
  /// `sourceIds[i]` is the index of the source photo crop `i` came from.
  /// Crops with the SAME source id are never compared — within a single
  /// source photo we trust the face detector's spatial separation.
  ///
  /// Matching is based on Vision's face LANDMARKS — for each crop we run
  /// `VNDetectFaceLandmarksRequest` and use the 76-point landmark layout
  /// (eyes, nose, mouth, jaw…). For two faces, average per-point distance
  /// in the face's normalised coordinate space is a far better same-person
  /// signal than a generic image feature print, which flagged unrelated
  /// face crops as duplicates because they shared crop-level lighting.
  private func dedupeFacePaths(
    paths: [String], sourceIds: [Int], threshold: Float
  ) -> [Bool] {
    var observations: [VNFaceObservation?] = []
    for p in paths {
      guard let img = UIImage(contentsOfFile: p)?.cgImage else {
        observations.append(nil); continue
      }
      let req = VNDetectFaceLandmarksRequest()
      if #available(iOS 15.0, *) {
        req.revision = VNDetectFaceLandmarksRequestRevision3
      }
      let h = VNImageRequestHandler(cgImage: img, options: [:])
      do {
        try h.perform([req])
        observations.append((req.results?.first) as? VNFaceObservation)
      } catch {
        observations.append(nil)
      }
    }

    func landmarkDistance(_ a: VNFaceObservation, _ b: VNFaceObservation) -> Float {
      guard let la = a.landmarks?.allPoints?.normalizedPoints,
            let lb = b.landmarks?.allPoints?.normalizedPoints,
            !la.isEmpty, la.count == lb.count else {
        return Float.greatestFiniteMagnitude
      }
      var total: Float = 0
      for i in 0..<la.count {
        let dx = Float(la[i].x - lb[i].x)
        let dy = Float(la[i].y - lb[i].y)
        total += (dx * dx + dy * dy).squareRoot()
      }
      return total / Float(la.count)
    }

    var keep: [Bool] = Array(repeating: true, count: paths.count)
    for i in 0..<paths.count {
      if !keep[i] { continue }
      guard let oi = observations[i] else { continue }
      for j in (i+1)..<paths.count {
        if !keep[j] { continue }
        if i < sourceIds.count, j < sourceIds.count, sourceIds[i] == sourceIds[j] {
          continue
        }
        guard let oj = observations[j] else { continue }
        let d = landmarkDistance(oi, oj)
        if d < threshold { keep[j] = false }
      }
    }
    return keep
  }

  /// Detect every face in the image at [path]. Returns a list of dicts with
  /// pixel-space bounding boxes (origin top-left) and the source image size,
  /// matching what the Dart side expects for cropping.
  private func detectFaces(
    at path: String,
    completion: @escaping ([[String: Any]]?, Error?) -> Void
  ) {
    guard let image = UIImage(contentsOfFile: path),
          let cgImage = image.cgImage else {
      completion(nil, NSError(
        domain: "FaceDetection", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Cannot load image at \(path)"]
      ))
      return
    }
    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)
    let orientation = self.cgOrientation(from: image.imageOrientation)

    // Hybrid detection. We run THREE Vision requests and merge:
    //  1. Face rectangles — fast, broad recall.
    //  2. Face landmarks — sometimes catches faces #1 misses (and vice
    //     versa). We dedupe by bbox IoU.
    //  3. Human rectangles — full-body detection. For any human whose
    //     head region isn't covered by a real face hit, we synthesise a
    //     face bbox from the body's top portion. This rescues people
    //     Vision's face model intermittently misses on group shots.
    let rectRequest = VNDetectFaceRectanglesRequest()
    let landmarksRequest = VNDetectFaceLandmarksRequest()
    let humansRequest = VNDetectHumanRectanglesRequest()
    if #available(iOS 15.0, *) {
      rectRequest.revision = VNDetectFaceRectanglesRequestRevision3
      landmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
    do {
      try handler.perform([rectRequest, landmarksRequest, humansRequest])
    } catch {
      completion(nil, error)
      return
    }

    let rectObs = (rectRequest.results ?? []) as [VNFaceObservation]
    let lmObs = (landmarksRequest.results ?? []) as [VNFaceObservation]
    let humanObs = (humansRequest.results ?? []) as [VNDetectedObjectObservation]

    func isFaceShaped(_ aspect: CGFloat) -> Bool {
      return aspect >= 0.5 && aspect <= 1.7
    }
    func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
      let inter = a.intersection(b)
      if inter.isNull { return 0 }
      let interArea = inter.width * inter.height
      let unionArea = (a.width * a.height) + (b.width * b.height) - interArea
      return unionArea > 0 ? interArea / unionArea : 0
    }

    // Pass 1: real face hits, deduplicated.
    var faceBoxes: [CGRect] = []
    for o in lmObs {
      let bb = o.boundingBox
      if o.confidence >= 0.3 && isFaceShaped(bb.width / bb.height) {
        faceBoxes.append(bb)
      }
    }
    for o in rectObs {
      let bb = o.boundingBox
      if o.confidence < 0.3 || !isFaceShaped(bb.width / bb.height) { continue }
      let dup = faceBoxes.contains { iou($0, bb) > 0.4 }
      if !dup { faceBoxes.append(bb) }
    }

    // Pass 2: rescue undetected faces using human-body detections. Empirical
    // ratios from the macOS sandbox: face is ~50 % of body width, ~22 % of
    // body height, with face centre about 7 % of body height below the
    // body's top.
    for h in humanObs where h.confidence >= 0.6 {
      let body = h.boundingBox
      let headRect = CGRect(
        x: body.minX, y: body.minY + body.height * 0.75,
        width: body.width, height: body.height * 0.25
      )
      let alreadyMatched = faceBoxes.contains { iou($0, headRect) > 0.05 }
      if alreadyMatched { continue }
      let fw = body.width * 0.5
      let fh = body.height * 0.22
      let cx = body.minX + body.width * 0.5
      let cy = body.minY + body.height - body.height * 0.07 - fh * 0.5
      let inferred = CGRect(x: cx - fw / 2, y: cy - fh / 2, width: fw, height: fh)
      faceBoxes.append(inferred)
    }

    let faces: [[String: Any]] = faceBoxes.map { bbox in
      // Vision returns normalized coords in the image's natural orientation
      // with origin at bottom-left. Convert to top-left pixel coords.
      let left = bbox.origin.x * imageWidth
      let widthPx = bbox.width * imageWidth
      let heightPx = bbox.height * imageHeight
      let topFromBottom = bbox.origin.y * imageHeight
      let topFromTop = imageHeight - topFromBottom - heightPx
      return [
        "left": Double(left),
        "top": Double(topFromTop),
        "right": Double(left + widthPx),
        "bottom": Double(topFromTop + heightPx),
        "imageWidth": Int(imageWidth),
        "imageHeight": Int(imageHeight),
      ]
    }
    completion(faces, nil)
  }

  private func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch uiOrientation {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }

  private func setupExternalDisplayChannel(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.zach.tacticsboard/externalDisplay", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "isConnected":
        result(ExternalDisplayManager.shared.isConnected)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    ExternalDisplayManager.shared.setup(channel: channel)
  }

  private func shareFile(path: String) {
    let url = URL(fileURLWithPath: path)
    guard let controller = self.topViewController() else { return }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = controller.view
      popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.maxY - 100, width: 0, height: 0)
    }
    controller.present(activityVC, animated: true)
  }

  private func topViewController() -> UIViewController? {
    var vc: UIViewController?
    if #available(iOS 15.0, *) {
      vc = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    } else {
      vc = UIApplication.shared.keyWindow?.rootViewController
    }
    while let presented = vc?.presentedViewController {
      vc = presented
    }
    return vc
  }
}
