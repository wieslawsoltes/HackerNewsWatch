import AppKit
import Foundation

let size: CGFloat = 1024
let pixelSize = Int(size)

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: pixelSize,
                                 pixelsHigh: pixelSize,
                                 bitsPerSample: 8,
                                 samplesPerPixel: 4,
                                 hasAlpha: true,
                                 isPlanar: false,
                                 colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0,
                                 bitsPerPixel: 0) else {
    fatalError("Failed to create bitmap rep")
}
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let text = "HN" as NSString
let fontSize: CGFloat = 512
let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
let style = NSMutableParagraphStyle()
style.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: style
]
let textRect = NSRect(x: 0, y: (size - fontSize)/2 - 100, width: size, height: fontSize)
text.draw(in: textRect, withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()

let img = NSImage(size: NSSize(width: size, height: size))
img.addRepresentation(rep)

guard let tiff = img.tiffRepresentation,
      let outRep = NSBitmapImageRep(data: tiff),
      let png = outRep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Sources/WatchApp/Assets.xcassets/AppIcon.appiconset/Icon-1024.png")
try png.write(to: url)
print("Wrote \(url.path)")
