import Cocoa

public class MTPopoverParentWindow: NSWindow {
    @objc func isReallyKeyWindow() -> Bool {
        return super.isKeyWindow
    }
    
    func isKeyWindow() -> Bool {
        var isKey = super.isKeyWindow
        if !isKey {
            for childWindow in childWindows ?? [] {
                if (childWindow is MTPopoverWindow) {
                    // if we have popover attached, window is key if app is active
                    isKey = NSApp.isActive
                    break
                }
            }
        }
        return isKey
    }
}
