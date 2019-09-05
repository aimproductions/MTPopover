//  Converted to Swift 5 by Swiftify v5.0.30657 - https://objectivec2swift.com/
//
//  INPopoverParentWindow.swift
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

//
//  INAlwaysKeyWindow.m
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

import Cocoa

public class INPopoverParentWindow: NSWindow {
    @objc func isReallyKeyWindow() -> Bool {
        return super.isKeyWindow
    }
    
    func isKeyWindow() -> Bool {
        var isKey = super.isKeyWindow
        if !isKey {
            for childWindow in childWindows ?? [] {
                if (childWindow is INPopoverWindow) {
                    // if we have popover attached, window is key if app is active
                    isKey = NSApp.isActive
                    break
                }
            }
        }
        return isKey
    }
}
