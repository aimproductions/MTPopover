import Cocoa

public class MTPopover: NSObject, CAAnimationDelegate {
    private var screenRect = NSRect.zero
    private var viewRect = NSRect.zero
    
    /// Keeps track if the popover is already being closed
    /// This is to prevent duplicate popoverWillClose callbacks
    private var isClosing: Bool = false
    
    // MARK: -
    // MARK: Properties
    
    /// The delegate of the MTPopover object (must conform to the MTPopoverDelegate protocol)
    public weak var delegate: MTPopoverDelegate?
    
    /// The background color of the popover. Default value is [NSColor blackColor] with an alpha value of 0.8.
    /// Changes to this value are not animated.
    public var color: NSColor? {
        get { return popoverWindow.frameView?.color }
        set(newColor) { popoverWindow.frameView?.color = newColor }
    }
    
    /// Border color to use when drawing a border. Default value: [NSColor blackColor].
    /// Changes to this value are not animated.
    public var borderColor: NSColor? {
        get { return popoverWindow.frameView?.borderColor }
        set(newBorderColor) { popoverWindow.frameView?.borderColor = newBorderColor }
    }
    
    /// Color to use for drawing a 1px highlight just below the top. Can be nil.
    /// Changes to this value are not animated.
    public var topHighlightColor: NSColor? {
        get { return popoverWindow.frameView?.topHighlightColor }
        set(newTopHighlightColor) { popoverWindow.frameView?.topHighlightColor = newTopHighlightColor }
    }
    
    /// The width of the popover border, drawn using borderColor. Default value: 0.0 (no border).
    /// Changes to this value are not animated.
    public var borderWidth: CGFloat {
        get { return popoverWindow.frameView?.borderWidth ?? 0.0 }
        set(newBorderWidth) { popoverWindow.frameView?.borderWidth = newBorderWidth }
    }
    
    /// Corner radius of the popover window. Default value: 4.
    /// Changes to this value are not animated.
    public var cornerRadius: CGFloat {
        get { return popoverWindow.frameView?.cornerRadius ?? 0.0 }
        set(cornerRadius) { popoverWindow.frameView?.cornerRadius = cornerRadius }
    }
    
    /// The size of the popover arrow. Default value: {23, 12}.
    /// Changes to this value are not animated. *
    public var arrowSize: NSSize {
        get { return popoverWindow.frameView?.arrowSize ?? NSSize.zero }
        set(arrowSize) {  popoverWindow.frameView?.arrowSize = arrowSize }
    }
    
    /// The current arrow direction of the popover.
    /// If the popover has never been displayed, then this will return .undefined
    public var arrowDirection: MTPopoverArrowDirection {
        return popoverWindow.frameView?.arrowDirection ?? .undefined
    }
    
    /// The size of the content of the popover.
    /// This is automatically set to contentViewController's size when the view controller is set, but can be modified.
    /// Changes to this value are animated when animates is set to YES
    public var contentSize: NSSize = NSSize.zero {
        didSet {
            // We use -frameRectForContentRect: just to get the frame size because the origin it returns is not the one we want to use.
            // Instead, -windowFrameWithSize:andArrowDirection: is used to complete the frame
            let adjustedRect = popoverFrame(with: contentSize, andArrowDirection: arrowDirection)
            popoverWindow.setFrame(adjustedRect, display: true, animate: animates)
        }
    }
    
    /// Whether the popover closes when user presses escape key. Default value: YES
    public var closesWhenEscapeKeyPressed = false
    
    /// Whether the popover closes when the popover window resigns its key status. Default value: YES
    public var closesWhenPopoverResignsKey = false
    
    /// Whether the popover closes when the application becomes inactive. Default value: NO
    public var closesWhenApplicationBecomesInactive = false
    
    /// Whether the popover closes when the position view goes offscreen. Only relevant when the position is bound to the anchors. Default value: YES
    public var closesWhenGoingOffscreen = true
    
    /// Enable or disable animation when showing/closing the popover and changing the content size. Default value: YES
    public var animates = true
    
    /// If `animates` is `YES`, this is the animation type to use when showing/closing the popover.
    /// Default value: `.pop`
    public var animationType: MTPopoverAnimationType = .pop
    
    /// The content view controller from which content is displayed in the popover
    private var _contentViewController: NSViewController?
    public var contentViewController: NSViewController? {
        get {
            return _contentViewController
        }
        // NOTE: I tried to change this logic to didSet but that triggered a BAD ACCESS crash..
        set(newContentViewController) {
            if _contentViewController != newContentViewController {
                popoverWindow.popoverContentView = nil// Clear the content view
                _contentViewController = newContentViewController
                let contentView = _contentViewController?.view
                contentSize = contentView?.frame.size ?? NSSize.zero
                popoverWindow.popoverContentView = contentView
            }
        }
    }
    
    /// The view that the currently displayed popover is positioned relative to.
    /// If there is no popover being displayed, this returns nil.
    private(set) var positionView: NSView?
    
    /// The window of the popover
    private(set) var popoverWindow: MTPopoverWindow!
    
    /// Whether the popover is currently visible or not
    public var popoverIsVisible: Bool {
        return popoverWindow.isVisible
    }
    
    /// Whether the window can become key or not. Default value: YES
    public var windowCanBecomeKey: Bool {
        get { return popoverWindow.windowCanBecomeKey }
        set(windowCanBecomeKey) { popoverWindow.windowCanBecomeKey = windowCanBecomeKey }
    }
    
    // MARK: -
    // MARK: Initializers

    /// Initializes the popover with a content view already set.
    ///
    /// - Parameter viewController: the content view controller
    public init(contentViewController viewController: NSViewController?) {
        super.init()
        
        setInitialPropertyValues()
        contentViewController = viewController
    }
    
    // MARK: -
    // MARK: Methods
    
    /// Displays the popover.
    ///
    /// - Parameters:
    ///   - relativeTo: the rect in the positionView from which to display the popover
    ///   - of: the view that the popover is positioned relative to
    ///   - preferredEdge: the prefered edge at which the arrow will point.
    ///     There is no guarantee that this will be the actual arrow direction,
    ///     depending on whether the screen is able to accomodate the popover in that position.
    ///   - anchors: whether the popover binds to the frame of the positionView.
    ///     This means that if the positionView is resized or moved, the popover will be repositioned
    ///     according to the point at which it was originally placed.
    ///     This also means that if the positionView goes off screen, the popover will be automatically closed.
    ///     Default value: YES
    public func show(relativeTo rect: NSRect,
                     of positionView: NSView,
                     preferredEdge: NSRectEdge,
                     anchorsToPositionView anchors: Bool = true) {
        
        var preferredArrowDirection: MTPopoverArrowDirection = .undefined
        
        switch preferredEdge {
        case .minX: preferredArrowDirection = .right
        case .maxX: preferredArrowDirection = .left
        case .maxY: preferredArrowDirection = .down
        case .minY: preferredArrowDirection = .up
        @unknown default:
            preferredArrowDirection = .left
        }
        
        show(relativeTo: rect, of: positionView, preferredArrowDirection: preferredArrowDirection, anchorsToPositionView: anchors)
    }
    
    /// Displays the popover.
    ///
    /// - Parameters:
    ///   - relativeTo: the rect in the positionView from which to display the popover
    ///   - of: the view that the popover is positioned relative to
    ///   - preferredArrowDirection: the prefered direction at which the arrow will point.
    ///     There is no guarantee that this will be the actual arrow direction,
    ///     depending on whether the screen is able to accomodate the popover in that position.
    ///   - anchors: whether the popover binds to the frame of the positionView.
    ///     This means that if the positionView is resized or moved, the popover will be repositioned
    ///     according to the point at which it was originally placed.
    ///     This also means that if the positionView goes off screen, the popover will be automatically closed.
    ///     Default value: YES
    public func show(relativeTo rect: NSRect,
                     of positionView: NSView,
                     preferredArrowDirection: MTPopoverArrowDirection,
                     anchorsToPositionView anchors: Bool = true) {
        guard !popoverIsVisible else { return } // If it's already visible, do nothing
        
        guard let mainWindow = positionView.window else {
            return
        }
        
        self.positionView = positionView
        viewRect = rect
        screenRect = positionView.convert(rect, to: nil) // Convert the rect to window coordinates
        screenRect.origin = mainWindow.convertToScreen(screenRect).origin // Convert window coordinates to screen coordinates
        let calculatedDirection = calculateArrowDirection(withPreferredArrowDirection: preferredArrowDirection) // Calculate the best arrow direction
        setArrowDirection(calculatedDirection) // Change the arrow direction of the popover
        let windowFrame = popoverFrame(with: contentSize, andArrowDirection: calculatedDirection) // Calculate the window frame based on the arrow direction
        popoverWindow.updateContentView()
        popoverWindow.setFrame(windowFrame, display: true) // Set the frame of the window
        (popoverWindow.animation(forKey: "alphaValue") as? CAAnimation)?.delegate = self
        
        // Show the popover
        callDelegateMethod(#selector(NSPopoverDelegate.popoverWillShow(_:))) // Call the delegate
        if animates && animationType != .fadeOut {
            // Animate the popover in
            popoverWindow.presentAnimated()
        } else {
            popoverWindow.alphaValue = 1.0
            mainWindow.addChildWindow(popoverWindow, ordered: .above) // Add the popover as a child window of the main window
            
            popoverWindow.makeKeyAndOrderFront(nil) // Show the popover
            callDelegateMethod(#selector(NSPopoverDelegate.popoverDidShow(_:))) // Call the delegate
        }
        
        let notificationCenter = NotificationCenter.default
        
        if anchors {
            // If the anchors option is enabled, register for bounds change notifications
            notificationCenter.addObserver(self, selector: #selector(positionViewBoundsChanged(_:)), name: NSView.boundsDidChangeNotification, object: self.positionView)
            
            // Also listen for frame changed notification
            // NOTE: Could be that just this one is sufficient; review later
            self.positionView?.postsFrameChangedNotifications = true
            notificationCenter.addObserver(self, selector: #selector(positionViewBoundsChanged(_:)), name: NSView.frameDidChangeNotification, object: self.positionView)
        }
        
        // When -closesWhenPopoverResignsKey is set to YES, the popover will automatically close when the popover loses its key status
        if closesWhenPopoverResignsKey {
            notificationCenter.addObserver(self, selector: #selector(performClose(_:)), name: NSWindow.didResignKeyNotification, object: popoverWindow)
            if !closesWhenApplicationBecomesInactive {
                notificationCenter.addObserver(self, selector: #selector(NSApplicationDelegate.applicationDidBecomeActive(_:)), name: NSApplication.didBecomeActiveNotification, object: nil)
            }
        } else if closesWhenApplicationBecomesInactive {
            // this is only needed if closesWhenPopoverResignsKey is NO, otherwise we already get a "resign key" notification when resigning active
            notificationCenter.addObserver(self, selector: #selector(performClose(_:)), name: NSApplication.didResignActiveNotification, object: nil)
        }
    }
    
    /// Recalculates the best arrow direction for the current window position and resets the arrow direction.
    /// The change will not be animated.
    public func recalculateAndResetArrowDirection() {
        let direction = calculateArrowDirection(withPreferredArrowDirection: arrowDirection)
        setArrowDirection(direction)
    }
    
    /// Closes the popover unless NO is returned for the -popoverShouldClose: delegate method
    ///
    /// - Note that the popover must be closed (either manually or automatically) before its reference can be released
    ///
    /// - Parameter sender: the object that sent this message
    @IBAction public func performClose(_ sender: Any = NSNull()) {
        guard popoverWindow.isVisible && !isClosing else { return }
        
        if (sender as? Notification)?.name == NSWindow.didResignKeyNotification {
            // ignore "resign key" notification sent when app becomes inactive unless closesWhenApplicationBecomesInactive is enabled
            if !closesWhenApplicationBecomesInactive && !NSApp.isActive {
                return
            }
        }
        
        var close = true
        
        if let delegate = delegate {
            
            // Check to see if the delegate has implemented the -popoverShouldClose: method
            if delegate.responds(to: #selector(NSPopoverDelegate.popoverShouldClose(_:))) {
                close = delegate.popoverShouldClose?(self) ?? false
            }
        }
        
        if close {
            self.close(sender)
        }
    }
    
    /// Closes the popover regardless of what the delegate returns
    ///
    /// - Note that the popover must be closed (either manually or automatically) before its reference can be released
    ///
    /// - Parameter sender: the object that sent this message
    @IBAction public func close(_ sender: Any = NSNull()) {
        guard popoverWindow.isVisible, !isClosing else { return }
        
        isClosing = true
        
        callDelegateMethod(#selector(NSPopoverDelegate.popoverWillClose(_:))) // Call delegate
        if animates && animationType != .fadeIn {
            popoverWindow.dismissAnimated()
        } else {
            closePopoverAndResetVariables()
        }
    }

    /// Returns the frame for a popop window with a given size depending on the arrow direction.
    ///
    /// - Parameters:
    ///   - contentSize: the popover window content size
    ///   - direction: the arrow direction
    /// - Returns: the frame for a popop window with a given size depending on the arrow direction.
    internal func popoverFrame(with contentSize: NSSize, andArrowDirection direction: MTPopoverArrowDirection) -> NSRect {
        var contentRect = NSRect.zero
        contentRect.size = contentSize
        var windowFrame = popoverWindow.frameRect(forContentRect: contentRect)
        if direction == .up {
            let xOrigin = screenRect.midX - floor((windowFrame.size.width) / 2.0)
            let yOrigin = screenRect.minY - (windowFrame.size.height)
            windowFrame.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .upLeft {
            let xOrigin = screenRect.minX - arrowSize.width + 2
            let yOrigin = screenRect.minY - (windowFrame.size.height)
            windowFrame.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .upRight {
            let xOrigin = screenRect.maxX - (windowFrame.size.width) + arrowSize.width - 3
            let yOrigin = screenRect.minY - (windowFrame.size.height)
            windowFrame.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else if direction == .down {
            let xOrigin = screenRect.midX - floor((windowFrame.size.width) / 2.0)
            windowFrame.origin = NSPoint(x: xOrigin, y: screenRect.maxY)
        } else if direction == .left {
            let yOrigin = screenRect.midY - floor((windowFrame.size.height) / 2.0)
            windowFrame.origin = NSPoint(x: screenRect.maxX, y: yOrigin)
        } else if direction == .right {
            let xOrigin = screenRect.minX - (windowFrame.size.width)
            let yOrigin = screenRect.midY - floor((windowFrame.size.height) / 2.0)
            windowFrame.origin = NSPoint(x: xOrigin, y: yOrigin)
        } else {
            // If no arrow direction is specified, just return an empty rect
            windowFrame = NSRect.zero
        }
        
        return windowFrame
    }
    
    // MARK: -
    // MARK: Initialization
    override public init() {
        super.init()
        setInitialPropertyValues()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setInitialPropertyValues()
    }
    
    // MARK: -
    // MARK: - Memory Management
    deinit {
        popoverWindow.popoverController = nil
    }
    
    // MARK: -
    // MARK: Public Methods
    
    // Calculate the frame of the window depending on the arrow direction
    public func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {

        // Detect the end of fade out and close the window
        if 0.0 == popoverWindow.alphaValue {
            closePopoverAndResetVariables()
        } else if 1.0 == popoverWindow.alphaValue {
            if let popoverWindow = popoverWindow {
                positionView?.window?.addChildWindow(popoverWindow, ordered: .above)
            }
            callDelegateMethod(#selector(NSPopoverDelegate.popoverDidShow(_:)))
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        guard popoverWindow.isVisible else { return }
        
        // when the user clicks in the parent window for activating the app,
        // the parent window becomes key which prevents the popover window from being key
        perform(#selector(checkPopoverKeyWindowStatus), with: nil, afterDelay: 0)
    }
    
    @objc private func checkPopoverKeyWindowStatus() {
        let parentWindow = positionView?.window // could be MTPopoverParentWindow
        
        var isKey = false
        
        if let popoverParentWindow = parentWindow as? MTPopoverParentWindow {
            isKey = popoverParentWindow.isReallyKeyWindow()
        } else {
            isKey = parentWindow?.isKeyWindow ?? isKey
        }
        
        if isKey {
            popoverWindow.makeKey()
        }
    }
    
    // MARK: -
    // MARK: Getters
    
    func contentView() -> NSView? {
        return popoverWindow.popoverContentView
    }
    
    // MARK: -
    // MARK: Private
        
    private func setArrowDirection(_ direction: MTPopoverArrowDirection) {
        popoverWindow.frameView?.arrowDirection = direction // UIMenuController.ArrowDirection(rawValue: direction.rawValue)
    }
    
    // Set the default values for all the properties as described in the header documentation
    private func setInitialPropertyValues() {
        // Create an empty popover window
        popoverWindow = MTPopoverWindow(contentRect: NSRect.zero, styleMask: .borderless, backing: .buffered, defer: false)
        popoverWindow.popoverController = self
        
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
        popoverWindow.animations = ["alphaValue" : animation]
    }
    
    // Figure out which direction best stays in screen bounds
    private func calculateArrowDirection(withPreferredArrowDirection direction: MTPopoverArrowDirection) -> MTPopoverArrowDirection {
        let screenFrame = positionView?.window?.screen?.frame ?? NSZeroRect
        
        // If the window with the preferred arrow direction already falls within the screen bounds then no need to go any further
        var windowFrame = popoverFrame(with: contentSize, andArrowDirection: direction)
        
        if NSContainsRect(screenFrame, windowFrame) {
            return direction
        }
        
        // First thing to try is making the popover go opposite of its current direction
        var newDirection: MTPopoverArrowDirection = .undefined
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
        let `right` = screenFrame.size.width - screenRect.maxX
        let up = screenFrame.size.height - screenRect.maxY
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
    
    @objc private func positionViewBoundsChanged(_ notification: Notification?) {
        let superviewBounds = positionView?.superview?.bounds ?? NSZeroRect
        if closesWhenGoingOffscreen && !(NSContainsRect(superviewBounds, positionView?.frame ?? NSZeroRect)) {
            close(self) // If the position view goes off screen then close the popover
            return
        }
        var newFrame = popoverWindow.frame
        screenRect = positionView?.convert(viewRect, to: nil) ?? NSRect.zero // Convert the rect to window coordinates
        screenRect.origin = positionView?.window?.convertToScreen(screenRect).origin ?? screenRect.origin // Convert window coordinates to screen coordinates
        let calculatedFrame = popoverFrame(with: contentSize, andArrowDirection: arrowDirection) // Calculate the window frame based on the arrow direction
        newFrame.origin = calculatedFrame.origin
        popoverWindow.setFrame(newFrame, display: true, animate: false) // Set the frame of the window
    }
    
    private func closePopoverAndResetVariables() {
        let positionWindow = positionView?.window
        popoverWindow.orderOut(nil) // Close the window
        callDelegateMethod(#selector(NSPopoverDelegate.popoverDidClose(_:))) // Call the delegate to inform that the popover has closed
        if let popoverWindow = popoverWindow {
            positionWindow?.removeChildWindow(popoverWindow)
        } // Remove it as a child window
        positionWindow?.makeKeyAndOrderFront(nil)
        // Clear all the ivars
        setArrowDirection(.undefined)
        NotificationCenter.default.removeObserver(self)
        positionView = nil
        screenRect = NSRect.zero
        viewRect = NSRect.zero
        isClosing = false
        
        // When using ARC and no animation, there is a "message sent to deallocated instance" crash if setDelegate: is not performed at the end of the event.
        (popoverWindow.animation(forKey: "alphaValue") as? CAAnimation)?.delegate = nil
    }
    
    /// Call the given selector on the delegate if one is assigned
    ///
    /// - Parameter selector: selector to try call
    private func callDelegateMethod(_ selector: Selector) {
        guard let delegate = delegate, delegate.responds(to: selector) else { return }
        
        _ = delegate.perform(selector, with: self)
    }
}

@objc public protocol MTPopoverDelegate: NSObjectProtocol {

    /// When the -closePopover: method is invoked, this method is called to give a change for the delegate to prevent it from closing.
    /// Returning NO for this delegate method will prevent the popover being closed.
    /// This delegate method does not apply to the -forceClosePopover: method, which will close the popover regardless of what the delegate returns.
    ///
    /// - Parameter popover: the @class MTPopover object that is controlling the popover
    /// - Returns: whether the popover should close or not
    @objc optional func popoverShouldClose(_ popover: MTPopover) -> Bool

    /// Invoked right before the popover is shown on screen
    ///
    /// - Parameter popover: the @class MTPopover object that is controlling the popover
    @objc optional func popoverWillShow(_ popover: MTPopover)

    /// Invoked right after the popover is shown on screen
    ///
    /// - Parameter popover: the @class MTPopover object that is controlling the popover
    @objc optional func popoverDidShow(_ popover: MTPopover)

    /// Invoked right before the popover closes
    ///
    /// - Parameter popover: the @class MTPopover object that is controlling the popover
    @objc optional func popoverWillClose(_ popover: MTPopover)

    /// Invoked right after the popover closed
    ///
    /// - Parameter popover: the @class MTPopover object that is controlling the popover
    @objc optional func popoverDidClose(_ popover: MTPopover)
}
