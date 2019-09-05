//  Converted to Swift 5 by Swiftify v5.0.30657 - https://objectivec2swift.com/
//
//  INPopoverController.swift
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

import Cocoa

class INPopoverController: NSObject {
    private var screenRect = NSRect.zero
    private var viewRect = NSRect.zero

// MARK: -
// MARK: Properties

    //* The delegate of the INPopoverController object (should conform to the INPopoverControllerDelegate protocol) *
    weak var delegate: INPopoverControllerDelegate?
    //* The background color of the popover. Default value is [NSColor blackColor] with an alpha value of 0.8. Changes to this value are not animated. *

    private var _color: NSColor?
    var color: NSColor? {
        get {
            return popoverWindow?.frameView._color
        }
        set(newColor) {
            popoverWindow?.frameView._color = newColor
        }
    }
    //* Border color to use when drawing a border. Default value: [NSColor blackColor]. Changes to this value are not animated. *

    private var _borderColor: NSColor?
    var borderColor: NSColor? {
        get {
            return popoverWindow?.frameView._borderColor
        }
        set(newBorderColor) {
            popoverWindow?.frameView._borderColor = newBorderColor
        }
    }
    //* Color to use for drawing a 1px highlight just below the top. Can be nil. Changes to this value are not animated. *

    private var _topHighlightColor: NSColor?
    var topHighlightColor: NSColor? {
        get {
            return popoverWindow?.frameView._topHighlightColor
        }
        set(newTopHighlightColor) {
            popoverWindow?.frameView._topHighlightColor = newTopHighlightColor
        }
    }
    //* The width of the popover border, drawn using borderColor. Default value: 0.0 (no border). Changes to this value are not animated. *

    private var _borderWidth: CGFloat = 0.0
    var borderWidth: CGFloat {
        get {
            return popoverWindow?.frameView._borderWidth ?? 0.0
        }
        set(newBorderWidth) {
            popoverWindow?.frameView._borderWidth = newBorderWidth
        }
    }
    //* Corner radius of the popover window. Default value: 4. Changes to this value are not animated. *

    private var _cornerRadius: CGFloat = 0.0
    var cornerRadius: CGFloat {
        get {
            return popoverWindow?.frameView._cornerRadius ?? 0.0
        }
        set(cornerRadius) {
            popoverWindow?.frameView.cornerRadius = cornerRadius
        }
    }
    //* The size of the popover arrow. Default value: {23, 12}. Changes to this value are not animated. *

    private var _arrowSize = NSSize.zero
    var arrowSize: NSSize {
        get {
            return popoverWindow?.frameView._arrowSize ?? NSSize.zero
        }
        set(arrowSize) {
            popoverWindow?.frameView.arrowSize = arrowSize
        }
    }
    //* The current arrow direction of the popover. If the popover has never been displayed, then this will return INPopoverArrowDirectionUndefined

    private var _arrowDirection: INPopoverArrowDirection!
    var arrowDirection: INPopoverArrowDirection! {
        return (popoverWindow?.frameView._arrowDirection)!
    }
    //* The size of the content of the popover. This is automatically set to contentViewController's size when the view controller is set, but can be modified. Changes to this value are animated when animates is set to YES *

    private var _contentSize = NSSize.zero
    var contentSize: NSSize {
        get {
            return _contentSize
        }
        set(newContentSize) {
            // We use -frameRectForContentRect: just to get the frame size because the origin it returns is not the one we want to use. Instead, -windowFrameWithSize:andArrowDirection: is used to  complete the frame
            _contentSize = newContentSize
            let adjustedRect = popoverFrame(with: newContentSize, andArrowDirection: arrowDirection)
            popoverWindow?.setFrame(adjustedRect, display: true, animate: animates)
        }
    }
    //* Whether the popover closes when user presses escape key. Default value: YES
    var closesWhenEscapeKeyPressed = false
    //* Whether the popover closes when the popover window resigns its key status. Default value: YES *
    var closesWhenPopoverResignsKey = false
    //* Whether the popover closes when the application becomes inactive. Default value: NO *
    var closesWhenApplicationBecomesInactive = false
    //* Enable or disable animation when showing/closing the popover and changing the content size. Default value: YES
    var animates = false
    /* If `animates` is `YES`, this is the animation type to use when showing/closing the popover.
       Default value: `INPopoverAnimationTypePop` **/
    var animationType: INPopoverAnimationType!
    //* The content view controller from which content is displayed in the popover *

    private var _contentViewController: NSViewController?
    var contentViewController: NSViewController? {
        get {
            return _contentViewController
        }
        set(newContentViewController) {
            if _contentViewController != newContentViewController {
                popoverWindow?.setPopoverContentView(nil) // Clear the content view
                _contentViewController = newContentViewController
                let contentView = _contentViewController?.view
                contentSize = contentView?.frame.size ?? NSSize.zero
                popoverWindow?.setPopoverContentView(contentView)
            }
        }
    }
    //* The view that the currently displayed popover is positioned relative to. If there is no popover being displayed, this returns nil. *
    private(set) var positionView: NSView?
    //* The window of the popover *
    private(set) var popoverWindow: NSWindow?
    //* Whether the popover is currently visible or not *

    var popoverIsVisible: Bool {
        return popoverWindow?.isVisible ?? false
    }
    //* Whether the window can become key or not. Default value: YES *

    var windowCanBecomeKey: Bool {
        get {
            return popoverWindow?.canBecomeKey ?? false
        }
        set(windowCanBecomeKey) {
            popoverWindow?.canBecomeKey = windowCanBecomeKey
        }
    }

// MARK: -
// MARK: Methods

    /**
     Initializes the popover with a content view already set.
     @param viewController the content view controller
     @returns a new instance of INPopoverController
     */
    init(contentViewController viewController: NSViewController?) {
        super.init() != nil
            _setInitialPropertyValues()
            contentViewController = viewController
    }

    /**
     Displays the popover.
     @param rect the rect in the positionView from which to display the popover
     @param positionView the view that the popover is positioned relative to
     @param direction the prefered direction at which the arrow will point. There is no guarantee that this will be the actual arrow direction, depending on whether the screen is able to accomodate the popover in that position.
     @param anchors Whether the popover binds to the frame of the positionView. This means that if the positionView is resized or moved, the popover will be repositioned according to the point at which it was originally placed. This also means that if the positionView goes off screen, the popover will be automatically closed. **/
    func presentPopover(from rect: NSRect, in positionView: NSView?, preferredArrowDirection direction: INPopoverArrowDirection, anchorsToPositionView anchors: Bool) {
        if popoverIsVisible {
            return
            // If it's already visible, do nothing
        }
        let mainWindow = positionView?.window
        self.positionView = positionView
        viewRect = rect
        screenRect = positionView?.convert(rect, to: nil) ?? NSRect.zero // Convert the rect to window coordinates
        screenRect.origin = mainWindow?.convertToScreen(screenRect).origin // Convert window coordinates to screen coordinates
        let calculatedDirection = _arrowDirection(withPreferredArrowDirection: direction) // Calculate the best arrow direction
        _setArrowDirection(calculatedDirection) // Change the arrow direction of the popover
        let windowFrame = popoverFrame(with: contentSize, andArrowDirection: calculatedDirection) // Calculate the window frame based on the arrow direction
        popoverWindow?.updateContentView()
        popoverWindow?.setFrame(windowFrame, display: true) // Se the frame of the window
        (popoverWindow?.animation(forKey: "alphaValue") as? CAAnimation)?.delegate = self

        // Show the popover
        _callDelegateMethod(#selector(NSPopoverDelegate.popoverWillShow(_:))) // Call the delegate
        if animates && animationType != .fadeOut {
            // Animate the popover in
            popoverWindow?.presentAnimated()
        } else {
            popoverWindow?.alphaValue = 1.0
            if let popoverWindow = popoverWindow {
                mainWindow?.addChildWindow(popoverWindow, ordered: .above)
            } // Add the popover as a child window of the main window
            popoverWindow?.makeKeyAndOrderFront(nil) // Show the popover
            _callDelegateMethod(#selector(NSPopoverDelegate.popoverDidShow(_:))) // Call the delegate
        }

        let nc = NotificationCenter.default
        if anchors {
            // If the anchors option is enabled, register for bounds change notifications
            nc.addObserver(self, selector: #selector(_positionViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: self.positionView)
        }
        // When -closesWhenPopoverResignsKey is set to YES, the popover will automatically close when the popover loses its key status
        if closesWhenPopoverResignsKey {
            nc.addObserver(self, selector: #selector(closePopover(_:)), name: NSWindow.didResignKeyNotification, object: popoverWindow)
            if !closesWhenApplicationBecomesInactive {
                nc.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: NSApplication.didBecomeActiveNotification, object: nil)
            }
        } else if closesWhenApplicationBecomesInactive {
            // this is only needed if closesWhenPopoverResignsKey is NO, otherwise we already get a "resign key" notification when resigning active
            nc.addObserver(self, selector: #selector(closePopover(_:)), name: NSApplication.didResignActiveNotification, object: nil)
        }
    }

    /** 
     Recalculates the best arrow direction for the current window position and resets the arrow direction. The change will not be animated. **/
    func recalculateAndResetArrowDirection() {
        let direction = _arrowDirection(withPreferredArrowDirection: arrowDirection)
        _setArrowDirection(direction)
    }

    /**
     Closes the popover unless NO is returned for the -popoverShouldClose: delegate method 
     @param sender the object that sent this message
     */
    @IBAction func closePopover(_ sender: Any) {
        if !(popoverWindow?.isVisible ?? false) {
            return
        }
        if (sender is Notification) && ((sender as? Notification)?.name).isEqual(toString: NSWindow.didResignKeyNotification) != nil {
            // ignore "resign key" notification sent when app becomes inactive unless closesWhenApplicationBecomesInactive is enabled
            if !closesWhenApplicationBecomesInactive && !NSApp.isActive() {
                return
            }
        }
        var close = true
        // Check to see if the delegate has implemented the -popoverShouldClose: method
        if delegate?.responds(to: #selector(NSPopoverDelegate.popoverShouldClose(_:))) ?? false {
            close = delegate?.popoverShouldClose?(self) ?? false
        }
        if close {
            forceClosePopover(nil)
        }
    }

    /**
     Closes the popover regardless of what the delegate returns
     @param sender the object that sent this message
     */
    @IBAction func forceClosePopover(_ sender: Any) {
        if !(popoverWindow?.isVisible ?? false) {
            return
        }
        _callDelegateMethod(#selector(NSPopoverDelegate.popoverWillClose(_:))) // Call delegate
        if animates && animationType != .fadeIn {
            popoverWindow?.dismissAnimated()
        } else {
            _closePopoverAndResetVariables()
        }
    }

    /**
     Returns the frame for a popop window with a given size depending on the arrow direction.
     @param contentSize the popover window content size
     @param direction the arrow direction
     */
    func popoverFrame(with contentSize: NSSize, andArrowDirection direction: INPopoverArrowDirection) -> NSRect {
        var contentRect = NSRect.zero
        contentRect.size = contentSize
        var windowFrame = popoverWindow?.frameRect(forContentRect: contentRect)
        if direction == .up {
            let xOrigin = screenRect.midX - floor((windowFrame?.size.width ?? 0.0) / 2.0)
            let yOrigin = screenRect.minY - (windowFrame?.size.height ?? 0.0)
            windowFrame?.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .upLeft {
            let xOrigin = screenRect.minX - arrowSize.width + 2
            let yOrigin = screenRect.minY - (windowFrame?.size.height ?? 0.0)
            windowFrame?.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .upRight {
            let xOrigin = screenRect.maxX - (windowFrame?.size.width ?? 0.0) + arrowSize.width - 3
            let yOrigin = screenRect.minY - (windowFrame?.size.height ?? 0.0)
            windowFrame?.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .down {
            let xOrigin = screenRect.midX - floor((windowFrame?.size.width ?? 0.0) / 2.0)
            windowFrame?.origin = NSPoint(x: xOrigin, y: screenRect.maxY)
        } else if direction == .left {
            let yOrigin = screenRect.midY - floor((windowFrame?.size.height ?? 0.0) / 2.0)
            windowFrame?.origin = NSPoint(x: screenRect.maxX, y: yOrigin)
        } else if direction == .right {
            let xOrigin = screenRect.minX - (windowFrame?.size.width ?? 0.0)
            let yOrigin = screenRect.midY - floor((windowFrame?.size.height ?? 0.0) / 2.0)
            windowFrame?.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else {
            // If no arrow direction is specified, just return an empty rect
            windowFrame = NSRect.zero
        }
        return windowFrame ?? NSRect.zero
    }

// MARK: -
// MARK: Initialization
    override init() {
        super.init() != nil
            _setInitialPropertyValues()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        _setInitialPropertyValues()
    }

// MARK: -
// MARK: - Memory Management
    deinit {
        popoverWindow?.popoverController = nil
    }

// MARK: -
// MARK: Public Methods

    // Calculate the frame of the window depending on the arrow direction
    func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {
//#pragma unused(animation)
//#pragma unused(flag)
        // Detect the end of fade out and close the window
        if 0.0 == popoverWindow?.alphaValue {
            _closePopoverAndResetVariables()
        } else if 1.0 == popoverWindow?.alphaValue {
            if let popoverWindow = popoverWindow {
                positionView?.window?.addChildWindow(popoverWindow, ordered: .above)
            }
            _callDelegateMethod(#selector(NSPopoverDelegate.popoverDidShow(_:)))
        }
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        // when the user clicks in the parent window for activating the app, the parent window becomes key which prevents 
        if popoverWindow?.isVisible ?? false {
            perform(#selector(checkPopoverKeyWindowStatus), with: nil, afterDelay: 0)
        }
    }

    @objc func checkPopoverKeyWindowStatus() {
        let parentWindow = positionView?.window // could be INPopoverParentWindow
        let isKey = parentWindow?.responds(to: #selector(INPopoverParentWindow.isReallyKeyWindow)) ?? false ? parentWindow?.isReallyKey() : parentWindow?.isKey()
        if isKey ?? false {
            popoverWindow?.makeKey()
        }
    }

// MARK: -
// MARK: Getters

    func contentView() -> NSView? {
        return popoverWindow?.popoverContentView()
    }

// MARK: -
// MARK: Setters

    func _setArrowDirection(_ direction: INPopoverArrowDirection) {
        popoverWindow?.frameView.arrowDirection = UIMenuController.ArrowDirection(rawValue: direction.rawValue)
    }

// MARK: -
// MARK: Private

    // Set the default values for all the properties as described in the header documentation
    func _setInitialPropertyValues() {
        // Create an empty popover window
        popoverWindow = INPopoverWindow(contentRect: NSRect.zero, styleMask: NSBorderlessWindowMask, backing: .buffered, defer: false)
        popoverWindow?.popoverController = self

        // set defaults like iCal popover
        color = NSColor(calibratedWhite: 0.94, alpha: 0.92)
        borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.92)
        borderWidth = 1.0
        closesWhenEscapeKeyPressed = true
        closesWhenPopoverResignsKey = true
        closesWhenApplicationBecomesInactive = false
        animates = true
        animationType = .pop

        // create animation to get callback - delegate is set when opening popover to avoid memory cycles
        let animation = CABasicAnimation()
        popoverWindow?.animations = ["alphaValue" : animation]
    }

    // Figure out which direction best stays in screen bounds
    func _arrowDirection(withPreferredArrowDirection direction: INPopoverArrowDirection) -> INPopoverArrowDirection {
        let screenFrame = positionView?.window?.screen?.frame
        // If the window with the preferred arrow direction already falls within the screen bounds then no need to go any further
        var windowFrame = popoverFrame(with: contentSize, andArrowDirection: direction)
        if NSContainsRect(screenFrame, windowFrame) {
            return direction
        }
        // First thing to try is making the popover go opposite of its current direction
        var newDirection: INPopoverArrowDirection = .undefined
        switch direction {
            case .up:
                newDirection = .down
            case .down:
                newDirection = .up
            case .left:
                newDirection = .right
            case .right:
                newDirection = .left
            default:
                break
        }
        // If the popover now fits within bounds, then return the newly adjusted direction
        windowFrame = popoverFrame(with: contentSize, andArrowDirection: newDirection)
        if NSContainsRect(screenFrame, windowFrame) {
            return newDirection
        }
        // Calculate the remaining space on each side and figure out which would be the best to try next
        let `left` = screenRect.minX
        let `right` = (screenFrame?.size.width ?? 0.0) - screenRect.maxX
        let up = (screenFrame?.size.height ?? 0.0) - screenRect.maxY
        let down = screenRect.minY
        let arrowLeft = `right` > `left`
        let arrowUp = down > up
        // Now the next thing to try is the direction with the most space
        switch direction {
            case .up, .down:
                newDirection = arrowLeft ? .left : .right
            case .left, .right:
                newDirection = arrowUp ? .up : .down
            default:
                break
        }
        // If the popover now fits within bounds, then return the newly adjusted direction
        windowFrame = popoverFrame(with: contentSize, andArrowDirection: newDirection)
        if NSContainsRect(screenFrame, windowFrame) {
            return newDirection
        }
        // If that didn't fit, then that means that it will be out of bounds on every side so just return the original direction
        return direction
    }

    @objc func _positionViewBoundsChanged(_ notification: Notification?) {
        let superviewBounds = positionView?.superview?.bounds
        if !(NSContainsRect(superviewBounds, positionView?.frame)) {
            forceClosePopover(nil) // If the position view goes off screen then close the popover
            return
        }
        let newFrame = popoverWindow?.frame
        screenRect = positionView?.convert(viewRect, to: nil) ?? NSRect.zero // Convert the rect to window coordinates
        screenRect.origin = positionView?.window?.convertToScreen(screenRect).origin // Convert window coordinates to screen coordinates
        let calculatedFrame = popoverFrame(with: contentSize, andArrowDirection: arrowDirection) // Calculate the window frame based on the arrow direction
        newFrame?.origin = calculatedFrame.origin
        popoverWindow?.setFrame(newFrame ?? NSRect.zero, display: true, animate: false) // Set the frame of the window
    }

    func _closePopoverAndResetVariables() {
        let positionWindow = positionView?.window
        popoverWindow?.orderOut(nil) // Close the window
        _callDelegateMethod(#selector(NSPopoverDelegate.popoverDidClose(_:))) // Call the delegate to inform that the popover has closed
        if let popoverWindow = popoverWindow {
            positionWindow?.removeChildWindow(popoverWindow)
        } // Remove it as a child window
        positionWindow?.makeKeyAndOrderFront(nil)
        // Clear all the ivars
        _setArrowDirection(.undefined)
        NotificationCenter.default.removeObserver(self)
        positionView = nil
        screenRect = NSRect.zero
        viewRect = NSRect.zero

        // When using ARC and no animation, there is a "message sent to deallocated instance" crash if setDelegate: is not performed at the end of the event.
        popoverWindow?.animation(forKey: "alphaValue")?.perform(#selector(setDelegate(_:)), with: nil, afterDelay: 0)
    }

    func _callDelegateMethod(_ selector: Selector) {
        if delegate?.responds(to: selector) ?? false {
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            delegate?.perform(selector, with: self)
        //#pragma clang diagnostic pop
        }
    }
}

@objc protocol INPopoverControllerDelegate: NSObjectProtocol {
    /**
     When the -closePopover: method is invoked, this method is called to give a change for the delegate to prevent it from closing. Returning NO for this delegate method will prevent the popover being closed. This delegate method does not apply to the -forceClosePopover: method, which will close the popover regardless of what the delegate returns.
     @param popover the @class INPopoverController object that is controlling the popover
     @returns whether the popover should close or not
     */
    @objc optional func popoverShouldClose(_ popover: NSPopover) -> Bool
    /**
     Invoked right before the popover shows on screen
     @param popover the @class INPopoverController object that is controlling the popover
     */
    @objc optional func popoverWillShow(_ popover: INPopoverController?)
    /**
     Invoked right after the popover shows on screen
     @param popover the @class INPopoverController object that is controlling the popover
     */
    @objc optional func popoverDidShow(_ popover: INPopoverController?)
    /**
     Invoked right before the popover closes
     @param popover the @class INPopoverController object that is controlling the popover
     */
    @objc optional func popoverWillClose(_ popover: INPopoverController?)
    /**
     Invoked right before the popover closes
     @param popover the @class INPopoverController object that is controlling the popover
     */
    @objc optional func popoverDidClose(_ popover: INPopoverController?)
}