import SwiftUI

struct GraphColumnView: View {
    let row: GraphRow
    let maxColumn: Int
    let rowHeight: CGFloat
    let isFirstRow: Bool
    let hasParents: Bool

    private let columnWidth: CGFloat = 16
    private let nodeRadius: CGFloat = 4
    private let lineWidth: CGFloat = 1.5

    var totalWidth: CGFloat {
        CGFloat(maxColumn + 1) * columnWidth + 8
    }

    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2

            // Draw lines first (behind nodes)
            for line in row.lines {
                drawLine(line, context: &context, size: size, centerY: centerY)
            }

            // Draw the main vertical line through this node (connecting to parent)
            drawMainLine(at: row.column, context: &context, size: size, centerY: centerY)

            // Draw node last (on top)
            drawNode(at: row.column, context: &context, centerY: centerY)
        }
        .frame(width: totalWidth, height: rowHeight)
    }

    private func drawMainLine(at column: Int, context: inout GraphicsContext, size: CGSize, centerY: CGFloat) {
        let x = columnX(column)
        var path = Path()

        // Line from top of cell to node (only if not first row)
        if !isFirstRow {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: centerY - nodeRadius))
        }

        // Line from node to bottom of cell (only if has parents and not last row with no continuation)
        if hasParents {
            path.move(to: CGPoint(x: x, y: centerY + nodeRadius))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        context.stroke(path, with: .color(.secondary.opacity(0.5)), lineWidth: lineWidth)
    }

    private func columnX(_ column: Int) -> CGFloat {
        CGFloat(column) * columnWidth + columnWidth / 2 + 4
    }

    private func drawLine(_ line: GraphLine, context: inout GraphicsContext, size: CGSize, centerY: CGFloat) {
        let startX = columnX(line.fromColumn)
        let endX = columnX(line.toColumn)

        var path = Path()

        switch line.type {
        case .vertical:
            // Vertical continuation line for other columns (not the main node column)
            if !isFirstRow {
                path.move(to: CGPoint(x: startX, y: 0))
                path.addLine(to: CGPoint(x: startX, y: size.height))
            } else {
                // First row: only draw from center down
                path.move(to: CGPoint(x: startX, y: centerY))
                path.addLine(to: CGPoint(x: startX, y: size.height))
            }

        case .mergeFrom:
            // Merge line: comes from above in another column, curves to node
            path.move(to: CGPoint(x: startX, y: 0))
            path.addLine(to: CGPoint(x: startX, y: centerY - 4))
            path.addQuadCurve(
                to: CGPoint(x: endX, y: centerY),
                control: CGPoint(x: startX, y: centerY)
            )

        case .branchTo:
            // Branch line: goes from node to another column below
            path.move(to: CGPoint(x: startX, y: centerY))
            path.addQuadCurve(
                to: CGPoint(x: endX, y: centerY + 4),
                control: CGPoint(x: endX, y: centerY)
            )
            path.addLine(to: CGPoint(x: endX, y: size.height))
        }

        context.stroke(path, with: .color(.secondary.opacity(0.5)), lineWidth: lineWidth)
    }

    private func drawNode(at column: Int, context: inout GraphicsContext, centerY: CGFloat) {
        let x = columnX(column)
        let nodeRect = CGRect(
            x: x - nodeRadius,
            y: centerY - nodeRadius,
            width: nodeRadius * 2,
            height: nodeRadius * 2
        )

        let color: Color
        switch row.nodeType {
        case .workingCopy:
            color = .accentColor
        case .merge:
            color = .orange
        case .normal:
            color = .secondary
        }

        // Draw filled circle
        context.fill(Circle().path(in: nodeRect), with: .color(color))

        // Draw ring for merge nodes
        if row.nodeType == .merge {
            let ringRect = nodeRect.insetBy(dx: -2, dy: -2)
            context.stroke(
                Circle().path(in: ringRect),
                with: .color(color.opacity(0.5)),
                lineWidth: 1
            )
        }

        // Draw ring for working copy
        if row.nodeType == .workingCopy {
            let ringRect = nodeRect.insetBy(dx: -2, dy: -2)
            context.stroke(
                Circle().path(in: ringRect),
                with: .color(color.opacity(0.7)),
                lineWidth: 1.5
            )
        }
    }
}
