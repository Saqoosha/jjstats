#!/usr/bin/env swift

import AppKit
import CoreText

let size: CGFloat = 1024
let iconSize = size * 0.8125  // 832
let margin = (size - iconSize) / 2  // 96

// Font settings
let fontSize = iconSize * 0.70
let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
let text = "jj"

print("=== Debug Info ===")
print("Canvas size: \(size)")
print("Icon size: \(iconSize)")
print("Margin: \(margin)")
print("Font size: \(fontSize)")
print("")
print("Font metrics:")
print("  ascender: \(font.ascender)")
print("  descender: \(font.descender)")
print("  capHeight: \(font.capHeight)")
print("  xHeight: \(font.xHeight)")
print("  leading: \(font.leading)")
print("")

// Create attributed string
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
]
let attrString = NSAttributedString(string: text, attributes: attributes)

// Get size from NSAttributedString
let nsSize = attrString.size()
print("NSAttributedString.size():")
print("  width: \(nsSize.width), height: \(nsSize.height)")
print("")

// Use CoreText for actual glyph bounds
let line = CTLineCreateWithAttributedString(attrString)

// Typographic bounds
var ascent: CGFloat = 0
var descent: CGFloat = 0
var leading: CGFloat = 0
let typographicWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
print("CTLineGetTypographicBounds:")
print("  width: \(typographicWidth)")
print("  ascent: \(ascent), descent: \(descent), leading: \(leading)")
print("  total height: \(ascent + descent + leading)")
print("")

// Image bounds (actual glyph bounds) - NOTE: this misses the dots!
let imageBounds = CTLineGetImageBounds(line, nil)
print("CTLineGetImageBounds (actual glyph bounds - misses dots!):")
print("  origin: (\(imageBounds.origin.x), \(imageBounds.origin.y))")
print("  size: \(imageBounds.size.width) x \(imageBounds.size.height)")
print("")

// Get bounds for each glyph run to include dots
let runs = CTLineGetGlyphRuns(line) as! [CTRun]
var minX: CGFloat = .greatestFiniteMagnitude
var minY: CGFloat = .greatestFiniteMagnitude
var maxX: CGFloat = -.greatestFiniteMagnitude
var maxY: CGFloat = -.greatestFiniteMagnitude

for run in runs {
    let glyphCount = CTRunGetGlyphCount(run)
    var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
    var positions = [CGPoint](repeating: .zero, count: glyphCount)
    CTRunGetGlyphs(run, CFRange(location: 0, length: glyphCount), &glyphs)
    CTRunGetPositions(run, CFRange(location: 0, length: glyphCount), &positions)

    let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont

    for i in 0..<glyphCount {
        var boundingRect = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(runFont, .default, [glyphs[i]], &boundingRect, 1)

        let glyphMinX = positions[i].x + boundingRect.origin.x
        let glyphMinY = positions[i].y + boundingRect.origin.y
        let glyphMaxX = glyphMinX + boundingRect.size.width
        let glyphMaxY = glyphMinY + boundingRect.size.height

        minX = min(minX, glyphMinX)
        minY = min(minY, glyphMinY)
        maxX = max(maxX, glyphMaxX)
        maxY = max(maxY, glyphMaxY)

        print("  Glyph \(i): pos=(\(positions[i].x), \(positions[i].y)) bounds=\(boundingRect)")
    }
}

let glyphWidth = maxX - minX
let glyphHeight = maxY - minY
let glyphOriginX = minX
let glyphOriginY = minY

print("")
print("Combined glyph bounds (from CTFontGetBoundingRectsForGlyphs - still misses dots!):")
print("  origin: (\(glyphOriginX), \(glyphOriginY))")
print("  size: \(glyphWidth) x \(glyphHeight)")
print("")

// Render text to bitmap and scan for actual pixel bounds
func getActualGlyphBounds() -> CGRect {
    let tempSize: CGFloat = 1024
    let tempImage = NSImage(size: NSSize(width: tempSize, height: tempSize))
    tempImage.lockFocus()

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: NSSize(width: tempSize, height: tempSize)).fill()

    // Draw at known position
    let drawX: CGFloat = 100
    let drawY: CGFloat = 200
    attrString.draw(at: NSPoint(x: drawX, y: drawY))

    tempImage.unlockFocus()

    // Get bitmap data
    guard let tiffData = tempImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        return .zero
    }

    var minX = Int(tempSize)
    var minY = Int(tempSize)
    var maxX = 0
    var maxY = 0

    for py in 0..<Int(tempSize) {
        for px in 0..<Int(tempSize) {
            if let color = bitmap.colorAt(x: px, y: py) {
                if color.alphaComponent > 0.1 {
                    minX = min(minX, px)
                    minY = min(minY, py)
                    maxX = max(maxX, px)
                    maxY = max(maxY, py)
                }
            }
        }
    }

    // NSBitmapImageRep coordinate: Y=0 at top, increasing downward
    // NSImage/drawing coordinate: Y=0 at bottom, increasing upward
    // Convert bitmap Y to drawing Y: drawingY = imageHeight - bitmapY - 1

    let pixelMinY_bitmap = minY  // top of glyph in bitmap coords (smaller = higher on screen)
    let pixelMaxY_bitmap = maxY  // bottom of glyph in bitmap coords

    // Convert to drawing coordinates
    let pixelMinY_drawing = tempSize - CGFloat(pixelMaxY_bitmap) - 1  // bottom of glyph
    let pixelMaxY_drawing = tempSize - CGFloat(pixelMinY_bitmap) - 1  // top of glyph

    // Calculate bounds relative to draw position
    let boundsX = CGFloat(minX) - drawX
    let boundsY = pixelMinY_drawing - drawY  // offset from baseline
    let boundsWidth = CGFloat(maxX - minX + 1)
    let boundsHeight = pixelMaxY_drawing - pixelMinY_drawing + 1

    print("  Bitmap pixel range: X=\(minX)-\(maxX), Y=\(minY)-\(maxY)")
    print("  Drawing Y range: \(pixelMinY_drawing)-\(pixelMaxY_drawing)")

    return CGRect(x: boundsX, y: boundsY, width: boundsWidth, height: boundsHeight)
}

let actualBounds = getActualGlyphBounds()
print("Actual pixel bounds (from bitmap scan):")
print("  origin: (\(actualBounds.origin.x), \(actualBounds.origin.y))")
print("  size: \(actualBounds.size.width) x \(actualBounds.size.height)")
print("")

let visualWidth = actualBounds.size.width
let visualHeight = actualBounds.size.height
let visualOriginX = actualBounds.origin.x
let visualOriginY = actualBounds.origin.y

// Center in icon area
let x = margin + (iconSize - visualWidth) / 2 - visualOriginX
let y = margin + (iconSize - visualHeight) / 2 - visualOriginY

print("Calculated position:")
print("  x: \(x)")
print("  y: \(y)")
print("")

// Create image
func createIcon(foregroundOnly: Bool, debug: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // Clear
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: NSSize(width: size, height: size)).fill()

    if !foregroundOnly {
        // Draw squircle background
        let bgRect = NSRect(x: margin, y: margin, width: iconSize, height: iconSize)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: iconSize * 0.22, yRadius: iconSize * 0.22)

        let gradient = NSGradient(starting: NSColor(white: 1.0, alpha: 1.0),
                                   ending: NSColor(white: 0.95, alpha: 1.0))
        gradient?.draw(in: bgPath, angle: 90)
    }

    // Draw text at calculated position
    attrString.draw(at: NSPoint(x: x, y: y))

    if debug {
        // Draw debug: icon area border (green)
        NSColor.green.setStroke()
        let iconRect = NSRect(x: margin, y: margin, width: iconSize, height: iconSize)
        NSBezierPath(rect: iconRect).stroke()

        // Draw debug: center lines (blue)
        NSColor.blue.setStroke()
        let centerX = margin + iconSize / 2
        let centerY = margin + iconSize / 2
        NSBezierPath.strokeLine(from: NSPoint(x: centerX, y: margin), to: NSPoint(x: centerX, y: margin + iconSize))
        NSBezierPath.strokeLine(from: NSPoint(x: margin, y: centerY), to: NSPoint(x: margin + iconSize, y: centerY))

        // Draw debug: visual bounds (red) - where we expect the glyph to be
        NSColor.red.setStroke()
        let visualRect = NSRect(x: x + visualOriginX, y: y + visualOriginY, width: visualWidth, height: visualHeight)
        NSBezierPath(rect: visualRect).stroke()

        // Draw debug: text drawing point (magenta dot)
        NSColor.magenta.setFill()
        let dotRect = NSRect(x: x - 5, y: y - 5, width: 10, height: 10)
        NSBezierPath(ovalIn: dotRect).fill()
    }

    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to path: String, size targetSize: Int) {
    var outputImage = image
    if targetSize != 1024 {
        outputImage = NSImage(size: NSSize(width: targetSize, height: targetSize))
        outputImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: targetSize, height: targetSize),
                   from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
                   operation: .sourceOver,
                   fraction: 1.0)
        outputImage.unlockFocus()
    }

    guard let tiffData = outputImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG")
        return
    }

    try? pngData.write(to: URL(fileURLWithPath: path))
    print("Created: \(path) (\(targetSize)x\(targetSize))")
}

// Generate icons
let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

// Debug image first
let buildDir = projectRoot.appendingPathComponent("build")
try? FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
let debugIcon = createIcon(foregroundOnly: false, debug: true)
saveImage(debugIcon, to: buildDir.appendingPathComponent("appicon_debug.png").path, size: 1024)
print("Debug image saved to build/appicon_debug.png")

// Foreground only
let foregroundDir = projectRoot.appendingPathComponent("Sources/jjstats/AppIcon.icon/Assets")
try? FileManager.default.createDirectory(at: foregroundDir, withIntermediateDirectories: true)
let foregroundIcon = createIcon(foregroundOnly: true)
saveImage(foregroundIcon, to: foregroundDir.appendingPathComponent("appicon_foreground.png").path, size: 1024)

// Full icons
let iconsetDir = projectRoot.appendingPathComponent("Sources/jjstats/Assets.xcassets/AppIcon.appiconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
let fullIcon = createIcon(foregroundOnly: false)
for s in [16, 32, 64, 128, 256, 512, 1024] {
    saveImage(fullIcon, to: iconsetDir.appendingPathComponent("appicon_\(s).png").path, size: s)
}

print("\nDone!")
