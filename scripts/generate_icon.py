#!/usr/bin/env python3
"""Generate app icon for jjstats using "jj" text with SF Font

Usage:
  python generate_icon.py              # Generate full icon with background
  python generate_icon.py --foreground # Generate foreground layer only (for Icon Composer)
"""

import argparse
from pathlib import Path

from AppKit import (
    NSBezierPath,
    NSBitmapImageRep,
    NSColor,
    NSCompositingOperationSourceOver,
    NSFont,
    NSFontWeightBold,
    NSGraphicsContext,
    NSImage,
    NSMakeRect,
    NSPNGFileType,
)
from Foundation import NSMakePoint, NSMakeSize, NSString


def create_squircle_path(x: float, y: float, width: float, height: float) -> NSBezierPath:
    """
    Create Apple's continuous curvature rounded rectangle (squircle).
    Based on PaintCode's reverse-engineering of iOS 7+ UIBezierPath.
    """
    from Foundation import NSPoint

    path = NSBezierPath.bezierPath()

    LIMIT_FACTOR = 1.52866483
    TOP_RIGHT_P1 = 1.52866483
    TOP_RIGHT_P2 = 1.08849323
    TOP_RIGHT_P3 = 0.86840689
    TOP_RIGHT_P4 = 0.66993427
    TOP_RIGHT_P5 = 0.63149399
    TOP_RIGHT_P6 = 0.37282392
    TOP_RIGHT_P7 = 0.16906013

    TOP_RIGHT_CP1 = 0.06549600
    TOP_RIGHT_CP2 = 0.07491100
    TOP_RIGHT_CP3 = 0.16905899
    TOP_RIGHT_CP4 = 0.37282401

    corner_radius = min(width, height) * 0.22
    max_radius = min(width, height) / 2
    limited_radius = min(corner_radius, max_radius / LIMIT_FACTOR)
    r = limited_radius

    left = x
    right = x + width
    top = y + height
    bottom = y

    path.moveToPoint_(NSPoint(left + r * TOP_RIGHT_P1, top))
    path.lineToPoint_(NSPoint(right - r * TOP_RIGHT_P1, top))

    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right - r * TOP_RIGHT_P4, top - r * TOP_RIGHT_CP1),
        NSPoint(right - r * TOP_RIGHT_P2, top),
        NSPoint(right - r * TOP_RIGHT_P3, top),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right - r * TOP_RIGHT_CP2, top - r * TOP_RIGHT_P5),
        NSPoint(right - r * TOP_RIGHT_P6, top - r * TOP_RIGHT_CP3),
        NSPoint(right - r * TOP_RIGHT_P7, top - r * TOP_RIGHT_CP4),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right, top - r * TOP_RIGHT_P1),
        NSPoint(right, top - r * TOP_RIGHT_P3),
        NSPoint(right, top - r * TOP_RIGHT_P2),
    )

    path.lineToPoint_(NSPoint(right, bottom + r * TOP_RIGHT_P1))

    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right - r * TOP_RIGHT_CP1, bottom + r * TOP_RIGHT_P4),
        NSPoint(right, bottom + r * TOP_RIGHT_P2),
        NSPoint(right, bottom + r * TOP_RIGHT_P3),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right - r * TOP_RIGHT_P5, bottom + r * TOP_RIGHT_CP2),
        NSPoint(right - r * TOP_RIGHT_CP3, bottom + r * TOP_RIGHT_P6),
        NSPoint(right - r * TOP_RIGHT_CP4, bottom + r * TOP_RIGHT_P7),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(right - r * TOP_RIGHT_P1, bottom),
        NSPoint(right - r * TOP_RIGHT_P3, bottom),
        NSPoint(right - r * TOP_RIGHT_P2, bottom),
    )

    path.lineToPoint_(NSPoint(left + r * TOP_RIGHT_P1, bottom))

    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left + r * TOP_RIGHT_P4, bottom + r * TOP_RIGHT_CP1),
        NSPoint(left + r * TOP_RIGHT_P2, bottom),
        NSPoint(left + r * TOP_RIGHT_P3, bottom),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left + r * TOP_RIGHT_CP2, bottom + r * TOP_RIGHT_P5),
        NSPoint(left + r * TOP_RIGHT_P6, bottom + r * TOP_RIGHT_CP3),
        NSPoint(left + r * TOP_RIGHT_P7, bottom + r * TOP_RIGHT_CP4),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left, bottom + r * TOP_RIGHT_P1),
        NSPoint(left, bottom + r * TOP_RIGHT_P3),
        NSPoint(left, bottom + r * TOP_RIGHT_P2),
    )

    path.lineToPoint_(NSPoint(left, top - r * TOP_RIGHT_P1))

    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left + r * TOP_RIGHT_CP1, top - r * TOP_RIGHT_P4),
        NSPoint(left, top - r * TOP_RIGHT_P2),
        NSPoint(left, top - r * TOP_RIGHT_P3),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left + r * TOP_RIGHT_P5, top - r * TOP_RIGHT_CP2),
        NSPoint(left + r * TOP_RIGHT_CP3, top - r * TOP_RIGHT_P6),
        NSPoint(left + r * TOP_RIGHT_CP4, top - r * TOP_RIGHT_P7),
    )
    path.curveToPoint_controlPoint1_controlPoint2_(
        NSPoint(left + r * TOP_RIGHT_P1, top),
        NSPoint(left + r * TOP_RIGHT_P3, top),
        NSPoint(left + r * TOP_RIGHT_P2, top),
    )

    path.closePath()
    return path


def create_icon(size: int = 1024, foreground_only: bool = False) -> NSImage:
    """Create the app icon using "jj" text with SF Font"""
    from AppKit import (
        NSFontManager,
        NSMutableParagraphStyle,
        NSAttributedString,
        NSForegroundColorAttributeName,
        NSFontAttributeName,
        NSParagraphStyleAttributeName,
    )
    from Foundation import NSPoint, NSDictionary

    image = NSImage.alloc().initWithSize_(NSMakeSize(size, size))
    image.lockFocus()

    ctx = NSGraphicsContext.currentContext()
    ctx.setShouldAntialias_(True)

    # macOS standard: 832x832 icon within 1024x1024 canvas
    icon_size = size * 0.8125
    margin = (size - icon_size) / 2

    if not foreground_only:
        from AppKit import NSGradient

        bg_path = create_squircle_path(margin, margin, icon_size, icon_size)
        top_gradient = NSGradient.alloc().initWithStartingColor_endingColor_(
            NSColor.colorWithCalibratedRed_green_blue_alpha_(1, 1, 1, 1.0),
            NSColor.colorWithCalibratedRed_green_blue_alpha_(0.95, 0.95, 0.95, 1.0),
        )
        top_gradient.drawInBezierPath_angle_(bg_path, 90)

    # Draw "jj" text
    text = "jj"

    # SF Pro Bold - larger size (70% of icon size)
    font_size = icon_size * 0.70
    font = NSFont.systemFontOfSize_weight_(font_size, NSFontWeightBold)

    # Dark gray color matching MeetsAudioRec style
    dark_gray = NSColor.colorWithCalibratedRed_green_blue_alpha_(0.27, 0.27, 0.27, 1.0)

    attributes = NSDictionary.dictionaryWithObjectsAndKeys_(
        font, NSFontAttributeName,
        dark_gray, NSForegroundColorAttributeName,
        None
    )

    attr_string = NSAttributedString.alloc().initWithString_attributes_(text, attributes)

    # Use NSLayoutManager to get actual glyph bounding box
    from AppKit import NSTextStorage, NSLayoutManager, NSTextContainer

    text_storage = NSTextStorage.alloc().initWithAttributedString_(attr_string)
    layout_manager = NSLayoutManager.alloc().init()
    text_container = NSTextContainer.alloc().initWithSize_(NSMakeSize(icon_size * 2, icon_size * 2))
    text_container.setLineFragmentPadding_(0)

    layout_manager.addTextContainer_(text_container)
    text_storage.addLayoutManager_(layout_manager)

    # Get the glyph range and bounding rect
    glyph_range = layout_manager.glyphRangeForTextContainer_(text_container)
    glyph_bounds = layout_manager.boundingRectForGlyphRange_inTextContainer_(glyph_range, text_container)

    glyph_width = glyph_bounds.size.width
    glyph_height = glyph_bounds.size.height

    # Center horizontally
    x = margin + (icon_size - glyph_width) / 2

    # Center vertically
    y = margin + (icon_size - glyph_height) / 2

    attr_string.drawAtPoint_(NSPoint(x, y))

    image.unlockFocus()
    return image


def save_png(image: NSImage, path: Path, size: int):
    """Save NSImage as PNG at specified size"""
    if size != 1024:
        resized = NSImage.alloc().initWithSize_(NSMakeSize(size, size))
        resized.lockFocus()
        NSGraphicsContext.currentContext().setImageInterpolation_(3)
        image.drawInRect_fromRect_operation_fraction_(
            NSMakeRect(0, 0, size, size),
            NSMakeRect(0, 0, 1024, 1024),
            NSCompositingOperationSourceOver,
            1.0,
        )
        resized.unlockFocus()
        image = resized

    tiff_data = image.TIFFRepresentation()
    bitmap = NSBitmapImageRep.imageRepWithData_(tiff_data)
    png_data = bitmap.representationUsingType_properties_(NSPNGFileType, None)

    png_data.writeToFile_atomically_(str(path), True)
    print(f"  Created: {path.name} ({size}x{size})")


def main():
    parser = argparse.ArgumentParser(description="Generate app icon for jjstats")
    parser.add_argument(
        "--foreground",
        action="store_true",
        help="Generate foreground layer only (transparent background, for Icon Composer)",
    )
    args = parser.parse_args()

    project_root = Path(__file__).parent.parent

    if args.foreground:
        output_dir = project_root / "Sources" / "jjstats" / "AppIcon.icon" / "Assets"
        output_dir.mkdir(parents=True, exist_ok=True)

        print("Creating foreground layer ('jj' text only) for Icon Composer...")
        icon = create_icon(1024, foreground_only=True)

        output_path = output_dir / "appicon_foreground.png"
        save_png(icon, output_path, 1024)

        print(f"\nForeground layer saved to: {output_path}")
    else:
        output_dir = project_root / "Sources" / "jjstats" / "Assets.xcassets" / "AppIcon.appiconset"
        output_dir.mkdir(parents=True, exist_ok=True)

        print("Creating icon with 'jj' text...")
        icon = create_icon(1024)

        sizes = [16, 32, 64, 128, 256, 512, 1024]

        print("\nGenerating PNG icons...")
        for size in sizes:
            output_path = output_dir / f"appicon_{size}.png"
            save_png(icon, output_path, size)

        print("\nAll icons generated successfully!")


if __name__ == "__main__":
    main()
