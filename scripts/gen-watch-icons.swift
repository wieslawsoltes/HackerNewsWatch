import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let size: CGFloat
}

let specs: [IconSpec] = [
    // notificationCenter
    .init(filename: "watch-notificationCenter-24@2x.png", size: 24 * 2),
    .init(filename: "watch-notificationCenter-27.5@2x.png", size: 27.5 * 2),
    .init(filename: "watch-notificationCenter-29@2x.png", size: 29 * 2),
    // companionSettings
    .init(filename: "watch-companionSettings-29@2x.png", size: 29 * 2),
    .init(filename: "watch-companionSettings-29@3x.png", size: 29 * 3),
    // appLauncher
    .init(filename: "watch-appLauncher-40@2x.png", size: 40 * 2),
    .init(filename: "watch-appLauncher-44@2x.png", size: 44 * 2),
    // quickLook
    .init(filename: "watch-quickLook-86@2x.png", size: 86 * 2),
    .init(filename: "watch-quickLook-98@2x.png", size: 98 * 2),
    .init(filename: "watch-quickLook-108@2x.png", size: 108 * 2),
]

let fs = FileManager.default
let cwd = URL(fileURLWithPath: fs.currentDirectoryPath)
let iconsDir = cwd.appendingPathComponent("Sources/WatchApp/Assets.xcassets/AppIcon.appiconset")
let base = iconsDir.appendingPathComponent("Icon-1024.png")

guard let baseImg = NSImage(contentsOf: base) else {
    fputs("Base icon not found at \(base.path). Run scripts/gen-icon.swift first.\n", stderr)
    exit(1)
}

func resize(_ image: NSImage, to pixelSize: CGFloat) -> NSImage? {
    let newSize = NSSize(width: pixelSize, height: pixelSize)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(pixelSize),
                               pixelsHigh: Int(pixelSize),
                               bitsPerSample: 8,
                               samplesPerPixel: 4,
                               hasAlpha: true,
                               isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0,
                               bitsPerPixel: 0)
    rep?.size = newSize
    guard let rep else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.set()
    NSBezierPath(rect: NSRect(origin: .zero, size: newSize)).fill()
    image.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    let out = NSImage(size: newSize)
    out.addRepresentation(rep)
    return out
}

for spec in specs {
    guard let resized = resize(baseImg, to: spec.size),
          let tiff = resized.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to generate \(spec.filename)\n", stderr)
        exit(1)
    }
    let out = iconsDir.appendingPathComponent(spec.filename)
    do {
        try png.write(to: out)
        print("Wrote \(out.lastPathComponent)")
    } catch {
        fputs("Write failed for \(out.path): \(error)\n", stderr)
        exit(1)
    }
}

print("Done generating watch icon variants.")
