//  Converted to Swift 5 by Swiftify v5.0.30657 - https://objectivec2swift.com/
//
//  INPopoverControllerDefines.swift
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

public enum INPopoverArrowDirection : Int {
    case undefined = 0
    case left = 1
    case right = 2
    case up = 3
    case down = 4
    case upLeft = 100
    case upRight = 101
}

public enum INPopoverAnimationType : Int {
    case pop = 0 // Pop animation similar to NSPopover
    case fadeIn // Fade in only, no fade out
    case fadeOut // Fade out only, no fade in
    case fadeInOut // Fade in and out
}
