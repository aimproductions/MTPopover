import AppKit
import QuartzCore

/** 
 @class MTPopoverWindow
 An NSWindow subclass used to draw a custom window frame (@class MTPopoverWindowFrame)
 **/

public class MTPopoverWindow: NSPanel, CAAnimationDelegate {
    private var zoomWindow: NSWindow!
    
    var frameView: MTPopoverWindowFrame? { return contentView as? MTPopoverWindowFrame }
    
    /// Equivalent to contentView
    var popoverController: MTPopover?
    
    private var _popoverContentView: NSView?
    var popoverContentView: NSView? {
        get {
            return _popoverContentView
        }
        set(aView) {
            if _popoverContentView?.isEqual(to: aView) ?? false {
                return
            }
            var bounds = frame
            bounds.origin = NSPoint.zero
            var frameView = self.frameView
            if frameView == nil {
                frameView = MTPopoverWindowFrame(frame: bounds)
                super.contentView = frameView // Call on super or there will be infinite loop
            }
            if let oldPopoverContentView = _popoverContentView {
                oldPopoverContentView.removeFromSuperview()
            }
            _popoverContentView = aView
            _popoverContentView?.frame = contentRect(forFrameRect: bounds)
            _popoverContentView?.autoresizingMask = [.width, .height]
            if let _popoverContentView = _popoverContentView {
                frameView?.addSubview(_popoverContentView)
            }
        }
    }
    
    /// Defines if this window can become key or not
    public var windowCanBecomeKey: Bool = false
    
    override public var canBecomeKey: Bool { return windowCanBecomeKey }
    
    func updateContentView() {
        var bounds = frame
        bounds.origin = NSPoint.zero
        popoverContentView?.frame = contentRect(forFrameRect: bounds)
    }
    
    func presentAnimated() {
        if isVisible {
            return
        }
        
        switch popoverController?.animationType {
        case .pop?:
            presentWithPopAnimation()
        case .fadeIn?, (.fadeInOut /* Fade in and out */)?:
            presentWithFadeAnimation()
        default:
            break
        }
    }
    
    func dismissAnimated() {
        zoomWindow?.animator().alphaValue = 0.0 // in case zoom window is currently animating
        animator().alphaValue = 0.0
    }
    
    // Borderless, transparent window
    override init(contentRect: NSRect, styleMask windowStyle: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer deferCreation: Bool) {
        super.init(contentRect: contentRect, styleMask: NSWindow.StyleMask.nonactivatingPanel, backing: bufferingType, defer: deferCreation)
        
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = true
        self.windowCanBecomeKey = true
    }
    
    // Leave some space around the content for drawing the arrow
    override public func contentRect(forFrameRect windowFrame: NSRect) -> NSRect {
        var windowFrame = windowFrame
        windowFrame.origin = NSPoint.zero
        let arrowHeight = frameView?.arrowSize.height
        return windowFrame.insetBy(dx: arrowHeight ?? 0.0, dy: arrowHeight ?? 0.0)
    }
    
    override public func frameRect(forContentRect contentRect: NSRect) -> NSRect {
        let arrowHeight = frameView?.arrowSize.height
        return contentRect.insetBy(dx: -(arrowHeight ?? 0.0), dy: -(arrowHeight ?? 0.0))
    }
    
    override public var canBecomeMain: Bool {
        return false
    }
    
    override public var isVisible: Bool {
        return super.isVisible || zoomWindow?.isVisible ?? false
    }
    
    override public var contentView: NSView? {
        get {
            return super.contentView
        }
        set(aView) {
            popoverContentView = aView
        }
    }
    
    func presentWithPopAnimation() {
        let endFrame = frame
        var startFrame: NSRect? = nil
        if let arrowDirection = frameView?.arrowDirection {
            startFrame = popoverController?.popoverFrame(with: START_SIZE, andArrowDirection: arrowDirection)
        }
        var overshootFrame: NSRect? = nil
        if let arrowDirection = frameView?.arrowDirection {
            overshootFrame = popoverController?.popoverFrame(with: NSMakeSize(CGFloat(Double(endFrame.size.width) * OVERSHOOT_FACTOR), CGFloat(Double(endFrame.size.height) * OVERSHOOT_FACTOR)), andArrowDirection: arrowDirection)
        }
        
        zoomWindow = _zoom(with: startFrame ?? NSRect.zero)
        zoomWindow.alphaValue = 0.0
        zoomWindow.orderFront(self)
        
        // configure bounce-out animation
        let anim = CAKeyframeAnimation()
        anim.delegate = self
        anim.values = [NSValue(rect: startFrame ?? NSRect.zero), NSValue(rect: overshootFrame ?? NSRect.zero), NSValue(rect: endFrame)]
        zoomWindow.animations = [
            "frame" : anim
        ]
        
        NSAnimationContext.beginGrouping()
        zoomWindow.animator().alphaValue = 1.0
        zoomWindow.animator().setFrame(endFrame, display: true)
        NSAnimationContext.endGrouping()
    }
    
    func presentWithFadeAnimation() {
        alphaValue = 0.0
        makeKeyAndOrderFront(nil)
        animator().alphaValue = 1.0
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        alphaValue = 1.0
        makeKeyAndOrderFront(self)
        zoomWindow.close()
        zoomWindow = nil
        
        // call the animation delegate of the "real" window
        let windowAnimation = animation(forKey: "alphaValue") as? CAAnimation
        windowAnimation?.delegate?.animationDidStop?(anim, finished: flag)
    }
    
    override public func cancelOperation(_ sender: Any?) {
        guard let popoverController = popoverController else { return }
        
        if popoverController.closesWhenEscapeKeyPressed {
            
            popoverController.closePopover(sender ?? self)
        }
    }
    
    // MARK: -
    // MARK: Private
    
    // The following method is adapted from the following class:
    // <https://github.com/MrNoodle/NoodleKit/blob/master/NSWindow-NoodleEffects.m>
    //  Copyright 2007-2009 Noodlesoft, LLC. All rights reserved.
    func _zoom(with rect: NSRect) -> NSWindow? {
        let isOneShot = self.isOneShot
        if isOneShot {
            self.isOneShot = false
        }
        
        if windowNumber <= 0 {
            // force creation of window device by putting it on-screen. We make it transparent to minimize the chance of visible flicker
            let alpha = alphaValue
            alphaValue = 0.0
            orderBack(self)
            orderOut(self)
            alphaValue = alpha
        }
        
        // get window content as image
        let frame = self.frame
        let image = NSImage(size: frame.size)
        displayIfNeeded() // refresh view
        let view = contentView
        let imageRep = view?.bitmapImageRepForCachingDisplay(in: view?.bounds ?? NSRect.zero)
        if let imageRep = imageRep {
            view?.cacheDisplay(in: view?.bounds ?? NSRect.zero, to: imageRep)
        }
        if let imageRep = imageRep {
            image.addRepresentation(imageRep)
        }
        
        // create zoom window
        let zoomWindow = NSWindow(contentRect: rect, styleMask: NSWindow.StyleMask.borderless, backing: .buffered, defer: false)
        zoomWindow.backgroundColor = NSColor.clear
        zoomWindow.hasShadow = hasShadow
        zoomWindow.level = level
        zoomWindow.isOpaque = false
        zoomWindow.isReleasedWhenClosed = false
        
        let imageView = NSImageView(frame: zoomWindow.contentRect(forFrameRect: frame))
        imageView.image = image
        imageView.imageFrameStyle = .none
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        
        zoomWindow.contentView = imageView
        
        // reset one shot flag
        self.isOneShot = isOneShot
        
        return zoomWindow
    }
}

let START_SIZE = NSMakeSize(20, 20)
let OVERSHOOT_FACTOR = 1.2

// A lot of this code was adapted from the following article:
// <http://cocoawithlove.com/2008/12/drawing-custom-window-on-mac-os-x.html>
