import Cocoa

/**
 @class MPPopoverWindowFrame
 The NSView subclass responsible for drawing the frame of the popover
 */

public class MTPopoverWindowFrame: NSView {
    
    // MARK: -
    // MARK: Accessors
    
    // Redraw the frame every time a property is changed
    
    var color: NSColor? = NSColor(calibratedWhite: 0.0, alpha: 0.8) {
        didSet {
            guard oldValue != color else { return }
            needsDisplay = true
        }
    }
    
    var borderColor: NSColor? {
        didSet {
            guard oldValue != borderColor else { return }
            needsDisplay = true
        }
    }
    
    var topHighlightColor: NSColor? {
        didSet {
            guard oldValue != topHighlightColor else { return }
            needsDisplay = true
        }
    }
    
    var borderWidth: CGFloat = 0.0 {
        didSet {
            guard oldValue != borderWidth else { return }
            needsDisplay = true
        }
    }
    
    var cornerRadius: CGFloat = 4.0 {
        didSet {
            guard oldValue != cornerRadius else { return }
            needsDisplay = true
        }
    }
    
    var arrowSize: NSSize = NSSize(width: 23.0, height: 12.0) {
        didSet {
            guard !NSEqualSizes(oldValue, arrowSize) else { return }
            needsDisplay = true
        }
    }
    
    var arrowDirection: MTPopoverArrowDirection = .left {
        didSet {
            guard oldValue != arrowDirection else { return }
            needsDisplay = true
        }
    }
    
    // MARK: -
    // MARK: Initializer
    
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: -
    // MARK: Public
    
    override public func draw(_ dirtyRect: NSRect) {
        var bounds = self.bounds
        if (Int(borderWidth) % 2) == 1 {
            // Remove draw glitch on odd border width
            bounds = bounds.insetBy(dx: 0.5, dy: 0.5)
        }
        
        let path = popoverBezierPath(with: bounds)
        if color != nil {
            color?.set()
            path?.fill()
        }
        if borderWidth > 0 {
            path?.lineWidth = borderWidth
            borderColor?.set()
            path?.stroke()
        }
        
        let arrowWidth = arrowSize.width
        let arrowHeight = arrowSize.height
        let radius = cornerRadius
        
        if topHighlightColor != nil {
            topHighlightColor?.set()
            let bounds = self.bounds.insetBy(dx: arrowHeight, dy: arrowHeight)
            let lineRect = NSRect(x: floor(bounds.minX + (radius / 2.0)), y: bounds.maxY - borderWidth - 1, width: bounds.width - radius, height: 1.0)
            
            if arrowDirection == .up {
                let width = floor((lineRect.size.width / 2.0) - (arrowWidth / 2.0))
                NSRect(x: lineRect.origin.x, y: lineRect.origin.y, width: width, height: lineRect.size.height).fill()
                NSRect(x: floor(lineRect.origin.x + (lineRect.size.width / 2.0) + (arrowWidth / 2.0)), y: lineRect.origin.y, width: width, height: lineRect.size.height).fill()
            } else {
                lineRect.fill()
            }
        }
    }
    
    // MARK: -
    // MARK: Private
    
    private func popoverBezierPath(with aRect: NSRect) -> NSBezierPath? {
        let radius = cornerRadius
        let arrowWidth = arrowSize.width
        let arrowHeight = arrowSize.height
        let inset = radius + arrowHeight
        let drawingRect = aRect.insetBy(dx: inset, dy: inset)
        let minX = drawingRect.minX
        let maxX = drawingRect.maxX
        let minY = drawingRect.minY
        let maxY = drawingRect.maxY
        
        // extra protection
        guard !minX.isNaN && !minX.isInfinite && !minY.isNaN && !minY.isInfinite else { return nil }
        
        let path = NSBezierPath()
        
        path.lineJoinStyle = .round
        
        // Bottom left corner
        path.appendArc(withCenter: CGPoint(x: minX, y: minY), radius: radius, startAngle: 180.0, endAngle: 270.0)
        if arrowDirection == .down {
            let midX = drawingRect.midX
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: floor(midX - (arrowWidth / 2.0)), y: minY - radius) // Starting point
            points[1] = CGPoint(x: floor(midX), y: points[0].y - arrowHeight) // Arrow tip
            points[2] = CGPoint(x: floor(midX + (arrowWidth / 2.0)), y: points[0].y) // Ending point
            
            path.appendPoints(points, count: 3)
        }
        
        // Bottom right corner
        path.appendArc(withCenter: CGPoint(x: maxX, y: minY), radius: radius, startAngle: 270.0, endAngle: 360.0)
        if arrowDirection == .right {
            let midY = drawingRect.midY
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: maxX + radius, y: floor(midY - (arrowWidth / 2.0)))
            points[1] = CGPoint(x: points[0].x + arrowHeight, y: floor(midY))
            points[2] = CGPoint(x: points[0].x, y: floor(midY + (arrowWidth / 2.0)))
            
            path.appendPoints(points, count: 3)
        }
        
        // Top right corner
        path.appendArc(withCenter: CGPoint(x: maxX, y: maxY), radius: radius, startAngle: 0.0, endAngle: 90.0)
        if arrowDirection == .up {
            let midX = drawingRect.midX
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: floor(midX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = CGPoint(x: floor(midX), y: points[0].y + arrowHeight)
            points[2] = CGPoint(x: floor(midX - (arrowWidth / 2.0)), y: points[0].y)
            
            path.appendPoints(points, count: 3)
        } else if arrowDirection == .upLeft {
            let arrowX = drawingRect.minX + arrowSize.width / 2 + 3
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: floor(arrowX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = CGPoint(x: floor(arrowX), y: points[0].y + arrowHeight)
            points[2] = CGPoint(x: floor(arrowX - (arrowWidth / 2.0)), y: points[0].y)
            
            path.appendPoints(points, count: 3)
        } else if arrowDirection == .upRight {
            let arrowX = drawingRect.maxX - arrowSize.width / 2 - 2
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: floor(arrowX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = CGPoint(x: floor(arrowX), y: points[0].y + arrowHeight)
            points[2] = CGPoint(x: floor(arrowX - (arrowWidth / 2.0)), y: points[0].y)
            
            path.appendPoints(points, count: 3)
        }
        
        // Top left corner
        path.appendArc(withCenter: CGPoint(x: minX, y: maxY), radius: radius, startAngle: 90.0, endAngle: 180.0)
        if arrowDirection == .left {
            let midY = drawingRect.midY
            let points = NSPointArray.allocate(capacity: 3)
            
            points[0] = CGPoint(x: minX - radius, y: floor(midY + (arrowWidth / 2.0)))
            points[1] = CGPoint(x: points[0].x - arrowHeight, y: floor(midY))
            points[2] = CGPoint(x: points[0].x, y: floor(midY - (arrowWidth / 2.0)))
            
            path.appendPoints(points, count: 3)
        }
        path.close()
        
        return path
    }
}
