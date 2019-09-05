//  Converted to Swift 5 by Swiftify v5.0.30657 - https://objectivec2swift.com/
//
//  INPopoverWindowFrame.swift
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

import Cocoa

/**
 @class INPopoverWindowFrame
 The NSView subclass responsible for drawing the frame of the popover
 */

public class INPopoverWindowFrame: NSView {
    private var _color: NSColor?
    var color: NSColor? {
        get {
            return _color
        }
        set(newColor) {
            if _color != newColor {
                _color = newColor
                needsDisplay = true
            }
        }
    }
    
    private var _borderColor: NSColor?
    var borderColor: NSColor? {
        get {
            return _borderColor
        }
        set(newBorderColor) {
            if _borderColor != newBorderColor {
                _borderColor = newBorderColor
                needsDisplay = true
            }
        }
    }
    var topHighlightColor: NSColor?
    
    private var _borderWidth: CGFloat = 0.0
    var borderWidth: CGFloat {
        get {
            return _borderWidth
        }
        set(newBorderWidth) {
            if _borderWidth != newBorderWidth {
                _borderWidth = newBorderWidth
                needsDisplay = true
            }
        }
    }
    
    private var _cornerRadius: CGFloat = 0.0
    var cornerRadius: CGFloat {
        get {
            return _cornerRadius
        }
        set(cornerRadius) {
            if _cornerRadius != cornerRadius {
                _cornerRadius = cornerRadius
                needsDisplay = true
            }
        }
    }
    
    private var _arrowSize = NSSize.zero
    var arrowSize: NSSize {
        get {
            return _arrowSize
        }
        set(arrowSize) {
            if !NSEqualSizes(_arrowSize, arrowSize) {
                _arrowSize = arrowSize
                needsDisplay = true
            }
        }
    }
    
    private var _arrowDirection: INPopoverArrowDirection!
    var arrowDirection: INPopoverArrowDirection! {
        get {
            return _arrowDirection
        }
        set(newArrowDirection) {
            if _arrowDirection != newArrowDirection {
                _arrowDirection = newArrowDirection
                needsDisplay = true
            }
        }
    }
    
    override init(frame: NSRect) {
        
        super.init(frame: frame)
        
        color = NSColor(calibratedWhite: 0.0, alpha: 0.8)
        cornerRadius = 4.0
        arrowSize = NSMakeSize(23.0, 12.0)
        arrowDirection = .left
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        var bounds = self.bounds
        if (Int(borderWidth) % 2) == 1 {
            // Remove draw glitch on odd border width
            bounds = bounds.insetBy(dx: 0.5, dy: 0.5)
        }
        
        let path = _popoverBezierPath(with: bounds)
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
            var bounds = self.bounds.insetBy(dx: arrowHeight, dy: arrowHeight)
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
    func _popoverBezierPath(with aRect: NSRect) -> NSBezierPath? {
        let radius = cornerRadius
        let arrowWidth = arrowSize.width
        let arrowHeight = arrowSize.height
        let inset = radius + arrowHeight
        let drawingRect = aRect.insetBy(dx: inset, dy: inset)
        let minX = drawingRect.minX
        let maxX = drawingRect.maxX
        let minY = drawingRect.minY
        let maxY = drawingRect.maxY
        
        let path = NSBezierPath()
        path.lineJoinStyle = .round
        
        // Bottom left corner
        path.appendArc(withCenter: NSPoint(x: minX, y: minY), radius: radius, startAngle: 180.0, endAngle: 270.0)
        if arrowDirection == .down {
            let midX = drawingRect.midX
            let points = NSPointArray.allocate(capacity: 3)
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            points[0] = NSPoint(x: floor(midX - (arrowWidth / 2.0)), y: minY - radius) // Starting point
            points[1] = NSPoint(x: floor(midX), y: points[0].y - arrowHeight) // Arrow tip
            points[2] = NSPoint(x: floor(midX + (arrowWidth / 2.0)), y: points[0].y) // Ending point
            
            path.appendPoints(points, count: 3)
        }
        // Bottom right corner
        path.appendArc(withCenter: NSPoint(x: maxX, y: minY), radius: radius, startAngle: 270.0, endAngle: 360.0)
        if arrowDirection == .right {
            let midY = drawingRect.midY
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            let points = NSPointArray.allocate(capacity: 3)
            points[0] = NSPoint(x: maxX + radius, y: floor(midY - (arrowWidth / 2.0)))
            points[1] = NSPoint(x: points[0].x + arrowHeight, y: floor(midY))
            points[2] = NSPoint(x: points[0].x, y: floor(midY + (arrowWidth / 2.0)))
            path.appendPoints(points, count: 3)
        }
        // Top right corner
        path.appendArc(withCenter: NSPoint(x: maxX, y: maxY), radius: radius, startAngle: 0.0, endAngle: 90.0)
        if arrowDirection == .up {
            let midX = drawingRect.midX
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            let points = NSPointArray.allocate(capacity: 3)
            points[0] = NSPoint(x: floor(midX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = NSPoint(x: floor(midX), y: points[0].y + arrowHeight)
            points[2] = NSPoint(x: floor(midX - (arrowWidth / 2.0)), y: points[0].y)
            path.appendPoints(points, count: 3)
        } else if arrowDirection == .upLeft {
            let arrowX = drawingRect.minX + arrowSize.width / 2 + 3
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            let points = NSPointArray.allocate(capacity: 3)
            points[0] = NSPoint(x: floor(arrowX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = NSPoint(x: floor(arrowX), y: points[0].y + arrowHeight)
            points[2] = NSPoint(x: floor(arrowX - (arrowWidth / 2.0)), y: points[0].y)
            path.appendPoints(points, count: 3)
        } else if arrowDirection == .upRight {
            let arrowX = drawingRect.maxX - arrowSize.width / 2 - 2
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            let points = NSPointArray.allocate(capacity: 3)
            points[0] = NSPoint(x: floor(arrowX + (arrowWidth / 2.0)), y: maxY + radius)
            points[1] = NSPoint(x: floor(arrowX), y: points[0].y + arrowHeight)
            points[2] = NSPoint(x: floor(arrowX - (arrowWidth / 2.0)), y: points[0].y)
            path.appendPoints(points, count: 3)
        }
        // Top left corner
        path.appendArc(withCenter: NSPoint(x: minX, y: maxY), radius: radius, startAngle: 90.0, endAngle: 180.0)
        if arrowDirection == .left {
            let midY = drawingRect.midY
            //let points = [NSPoint](repeating: NSPoint.zero, count: 3)
            let points = NSPointArray.allocate(capacity: 3)
            points[0] = NSPoint(x: minX - radius, y: floor(midY + (arrowWidth / 2.0)))
            points[1] = NSPoint(x: points[0].x - arrowHeight, y: floor(midY))
            points[2] = NSPoint(x: points[0].x, y: floor(midY - (arrowWidth / 2.0)))
            path.appendPoints(points, count: 3)
        }
        path.close()
        
        return path
    }
    
    // MARK: -
    // MARK: Accessors
    
    // Redraw the frame every time a property is changed
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
