import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let variants = [(16, "icon_16x16.png"), (32, "icon_16x16@2x.png"), (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"), (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"), (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"), (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")]
for (size, name) in variants {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.94, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 50, y: 50, width: 924, height: 924), xRadius: 215, yRadius: 215).fill()
    NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.19, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 175, y: 310, width: 674, height: 470), xRadius: 70, yRadius: 70).fill()
    NSColor(calibratedRed: 0.93, green: 0.34, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 215, y: 350, width: 594, height: 390), xRadius: 38, yRadius: 38).fill()
    NSColor.white.setStroke()
    let arrow = NSBezierPath(); arrow.lineWidth = 48; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 512, y: 645)); arrow.line(to: NSPoint(x: 512, y: 457))
    arrow.move(to: NSPoint(x: 426, y: 535)); arrow.line(to: NSPoint(x: 512, y: 449)); arrow.line(to: NSPoint(x: 598, y: 535)); arrow.stroke()
    let stand = NSBezierPath(); stand.lineWidth = 36; stand.lineCapStyle = .round
    NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.19, alpha: 1).setStroke()
    stand.move(to: NSPoint(x: 512, y: 310)); stand.line(to: NSPoint(x: 512, y: 245))
    stand.move(to: NSPoint(x: 386, y: 236)); stand.line(to: NSPoint(x: 638, y: 236)); stand.stroke()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(name))
}
