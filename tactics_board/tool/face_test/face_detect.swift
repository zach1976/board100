// Face-detection sandbox. Runs the same Vision pipeline as
// ios/Runner/AppDelegate.swift on a local image so we can iterate on
// thresholds / requests without rebuilding the iOS app.
//
// Usage:
//   swift tool/face_test/face_detect.swift <image_path> [confidence] [aspectMin] [aspectMax]
//
// Defaults: confidence=0.30, aspectMin=0.50, aspectMax=1.70

import Foundation
import Vision
import AppKit
import ImageIO

guard CommandLine.arguments.count >= 2 else {
  print("usage: swift face_detect.swift <image_path> [confidence] [aspectMin] [aspectMax]")
  exit(2)
}
let path = CommandLine.arguments[1]
let confidenceMin: Float = CommandLine.arguments.count >= 3
  ? (Float(CommandLine.arguments[2]) ?? 0.30) : 0.30
let aspectMin: CGFloat = CommandLine.arguments.count >= 4
  ? (CGFloat(Double(CommandLine.arguments[3]) ?? 0.50)) : 0.50
let aspectMax: CGFloat = CommandLine.arguments.count >= 5
  ? (CGFloat(Double(CommandLine.arguments[4]) ?? 1.70)) : 1.70

guard let image = NSImage(contentsOfFile: path),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  print("ERROR: cannot load image at \(path)")
  exit(1)
}
let imageWidth = CGFloat(cgImage.width)
let imageHeight = CGFloat(cgImage.height)
print("image: \(Int(imageWidth)) x \(Int(imageHeight))")

// Try every available rectangle revision so the union catches faces that a
// particular model misses.
func runRect(_ revision: Int) -> [VNFaceObservation] {
  let req = VNDetectFaceRectanglesRequest()
  req.revision = revision
  let h = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
  do { try h.perform([req]) } catch { return [] }
  return (req.results ?? [])
}
func runLandmarks(_ revision: Int) -> [VNFaceObservation] {
  let req = VNDetectFaceLandmarksRequest()
  req.revision = revision
  let h = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
  do { try h.perform([req]) } catch { return [] }
  return (req.results ?? [])
}

let rectR2 = runRect(VNDetectFaceRectanglesRequestRevision2)
let rectR3 = runRect(VNDetectFaceRectanglesRequestRevision3)
let lmR2   = runLandmarks(VNDetectFaceLandmarksRequestRevision2)
let lmR3   = runLandmarks(VNDetectFaceLandmarksRequestRevision3)
print("rectangles: R2=\(rectR2.count)  R3=\(rectR3.count)")
print("landmarks:  R2=\(lmR2.count)   R3=\(lmR3.count)")

// Also try human-rectangles detection — faces it misses sometimes still
// register as human bodies, giving us 7 people in this photo's case.
func runHumans() -> [VNDetectedObjectObservation] {
  let req = VNDetectHumanRectanglesRequest()
  let h = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
  do { try h.perform([req]) } catch { return [] }
  return (req.results ?? [])
}
let humans = runHumans()
print("humans (full body): \(humans.count)")
for (i, o) in humans.enumerated() {
  let bb = o.boundingBox
  print(String(format: "  H[%d] conf=%.2f bbox=(%.3f,%.3f,%.3f,%.3f)",
    i, o.confidence, bb.minX, bb.minY, bb.width, bb.height))
}

// Also try detection on an upscaled image — sometimes the model needs
// faces above a minimum pixel size and 1.5x makes a borderline face hit.
func runOnScaled(_ factor: CGFloat) -> Int {
  let newW = Int(CGFloat(cgImage.width) * factor)
  let newH = Int(CGFloat(cgImage.height) * factor)
  let cs = CGColorSpaceCreateDeviceRGB()
  guard let ctx = CGContext(
    data: nil, width: newW, height: newH,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else { return -1 }
  ctx.interpolationQuality = .high
  ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: newW, height: newH))
  guard let scaled = ctx.makeImage() else { return -1 }
  let req = VNDetectFaceRectanglesRequest()
  req.revision = VNDetectFaceRectanglesRequestRevision3
  let h = VNImageRequestHandler(cgImage: scaled, orientation: .up, options: [:])
  do { try h.perform([req]) } catch { return -1 }
  return (req.results ?? []).count
}
print("upscaled rect: 1.5x=\(runOnScaled(1.5))  2.0x=\(runOnScaled(2.0))")

let rectObs: [VNFaceObservation] = rectR3
let lmObs:   [VNFaceObservation] = lmR3

func aspectOK(_ obs: VNFaceObservation) -> Bool {
  let aspect = obs.boundingBox.width / obs.boundingBox.height
  return aspect >= aspectMin && aspect <= aspectMax
}
func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
  let inter = a.intersection(b)
  if inter.isNull { return 0 }
  let interArea = inter.width * inter.height
  let unionArea = (a.width * a.height) + (b.width * b.height) - interArea
  return unionArea > 0 ? interArea / unionArea : 0
}

print("---")
print("rectangles raw: \(rectObs.count)")
for (i, o) in rectObs.enumerated() {
  let bb = o.boundingBox
  let ar = bb.width / bb.height
  print(String(format: "  R[%d] conf=%.2f ar=%.2f bbox=(%.3f,%.3f,%.3f,%.3f)",
    i, o.confidence, ar, bb.minX, bb.minY, bb.width, bb.height))
}
print("landmarks  raw: \(lmObs.count)")
for (i, o) in lmObs.enumerated() {
  let bb = o.boundingBox
  let ar = bb.width / bb.height
  print(String(format: "  L[%d] conf=%.2f ar=%.2f bbox=(%.3f,%.3f,%.3f,%.3f)",
    i, o.confidence, ar, bb.minX, bb.minY, bb.width, bb.height))
}

print("---")
print("filter: confidence>=\(confidenceMin), aspect in [\(aspectMin), \(aspectMax)]")

// Faces directly seen by Vision (high quality bboxes).
var faceBoxes: [CGRect] = lmObs
  .filter { $0.confidence >= confidenceMin && aspectOK($0) }
  .map { $0.boundingBox }
for r in rectObs {
  if r.confidence < confidenceMin || !aspectOK(r) { continue }
  let dup = faceBoxes.contains { iou($0, r.boundingBox) > 0.4 }
  if !dup { faceBoxes.append(r.boundingBox) }
}
let directlyDetected = faceBoxes.count
print("face detector hits: \(directlyDetected)")

// Each human body whose head region doesn't overlap any detected face is
// an unmatched person — infer a face bbox from the body's top portion so
// we don't lose them. Head is roughly the top 25% of the body bbox; face
// width ≈ 50% of body width, face height ≈ 22% of body height.
var inferredFromHumans = 0
for h in humans where h.confidence >= 0.6 {
  let body = h.boundingBox
  // Head region (top ~25% of body in bottom-left coords).
  let headRect = CGRect(
    x: body.minX, y: body.minY + body.height * 0.75,
    width: body.width, height: body.height * 0.25
  )
  let alreadyMatched = faceBoxes.contains { iou($0, headRect) > 0.05 }
  if alreadyMatched { continue }
  // Infer face bbox: centered horizontally on the body, sized as ~50% × 22%.
  let fw = body.width * 0.5
  let fh = body.height * 0.22
  let cx = body.minX + body.width * 0.5
  // Face center y: ~7% of body height below body top.
  let cy = body.minY + body.height - body.height * 0.07 - fh * 0.5
  let inferred = CGRect(x: cx - fw / 2, y: cy - fh / 2, width: fw, height: fh)
  faceBoxes.append(inferred)
  inferredFromHumans += 1
}
print("inferred from humans: \(inferredFromHumans)")
print("MERGED FACE COUNT:    \(faceBoxes.count)")
for (i, bb) in faceBoxes.enumerated() {
  let xPx = Int(bb.minX * imageWidth)
  let widthPx = Int(bb.width * imageWidth)
  let yPx = Int((1.0 - bb.minY - bb.height) * imageHeight)
  let heightPx = Int(bb.height * imageHeight)
  let kind = i < directlyDetected ? "detected" : "inferred"
  print(String(format: "  M[%d] %@ bbox=(x=%d,y=%d,w=%d,h=%d)",
    i, kind, xPx, yPx, widthPx, heightPx))
}
