// shape_text.swift — render one App Store preview caption band to a PNG.
//
// The bundled Pillow on this Mac has no libraqm, so it cannot shape complex
// scripts (Thai vowels / tone marks render as detached dotted circles). This
// helper uses CoreText, which shapes every script correctly and falls back
// across system fonts automatically. finalize_preview.py calls it for the
// locales Pillow can't render.
//
// Usage: shape_text <out.png> <width> <height> <text>
// Draws a translucent dark rounded band with centred white bold text,
// auto-shrinking the font until the caption fits in the band.

import AppKit
import CoreText
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 5, let W = Int(args[2]), let H = Int(args[3]) else {
    FileHandle.standardError.write(
        "usage: shape_text <out.png> <width> <height> <text>\n".data(using: .utf8)!)
    exit(1)
}
let outPath = args[1]
let text = args[4]

// Band geometry — must match the Pillow path in finalize_preview.py.
let bandInsetX: CGFloat = 40
let bandInsetY: CGFloat = 30
let cornerRadius: CGFloat = 24
let textPad: CGFloat = 60

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    exit(1)
}

// Translucent dark rounded band.
let bandRect = CGRect(x: bandInsetX, y: bandInsetY,
                      width: CGFloat(W) - 2 * bandInsetX,
                      height: CGFloat(H) - 2 * bandInsetY)
ctx.addPath(CGPath(roundedRect: bandRect, cornerWidth: cornerRadius,
                   cornerHeight: cornerRadius, transform: nil))
ctx.setFillColor(CGColor(red: 13.0 / 255, green: 13.0 / 255,
                         blue: 26.0 / 255, alpha: 220.0 / 255))
ctx.fillPath()

// Lay the caption out, shrinking the font until it fits the band.
let maxTextW = CGFloat(W) - 2 * textPad
let maxTextH = bandRect.height - 40

func layout(_ size: CGFloat) -> (CTFrame, CGSize) {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let font = NSFont.systemFont(ofSize: size, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
    ]
    let astr = NSAttributedString(string: text, attributes: attrs)
    let fs = CTFramesetterCreateWithAttributedString(astr)
    let fit = CTFramesetterSuggestFrameSizeWithConstraints(
        fs, CFRange(location: 0, length: 0), nil,
        CGSize(width: maxTextW, height: 100_000), nil)
    let path = CGPath(rect: CGRect(x: 0, y: 0, width: maxTextW,
                                   height: max(fit.height, 10)), transform: nil)
    let frame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0),
                                         path, nil)
    return (frame, fit)
}

var size: CGFloat = 96
var (frame, fit) = layout(size)
while (fit.width > maxTextW || fit.height > maxTextH) && size > 40 {
    size -= 6
    (frame, fit) = layout(size)
}

// Centre the text block vertically in the band.
let ty = bandRect.minY + (bandRect.height - fit.height) / 2
ctx.saveGState()
ctx.translateBy(x: textPad, y: ty)
CTFrameDraw(frame, ctx)
ctx.restoreGState()

guard let image = ctx.makeImage() else { exit(1) }
let url = URL(fileURLWithPath: outPath) as CFURL
guard let dest = CGImageDestinationCreateWithURL(
    url, UTType.png.identifier as CFString, 1, nil) else {
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
if !CGImageDestinationFinalize(dest) {
    exit(1)
}
