//
//  ViewController.swift
//  MTPopover
//
//  Created by mylemans on 09/05/2019.
//  Copyright (c) 2019 mylemans. All rights reserved.
//

import Cocoa
import MTPopover

class ViewController: NSViewController, MTPopoverDelegate {
    private var popover: MTPopover!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onDestroyPressed(_ sender: Any) {
        
        guard let popoverController = popover else {
            return
        }
        
        if popoverController.popoverIsVisible {
            popoverController.close()
        }
        
        self.popover = nil
    }
    
    @IBAction func onButtonPressed(_ sender: Any) {
        
        
        if popover == nil {
            
            let viewController = ContentViewController(nibName: "ContentViewController", bundle: nil)
            popover = MTPopover(contentViewController: viewController)
            
            popover.cornerRadius = 0
            popover.borderWidth = 0
            popover.arrowSize = NSSize.zero
            popover.animationType = .fadeInOut
            popover.closesWhenApplicationBecomesInactive = false
            popover.closesWhenEscapeKeyPressed = false
            popover.closesWhenPopoverResignsKey = false
            popover.closesWhenGoingOffscreen = true
            popover.hasShadow = false
            popover.delegate = self
            popover.topHighlightColor = NSColor.green
            popover.originOffset = CGPoint(x: 0.0, y: 2)
            popover.contentSize = CGSize(width: (sender as! NSButton).intrinsicContentSize.width - 2, height: popover.contentSize.height)
        }
        
        if popover.popoverIsVisible {
            popover.performClose()
        } else {
            var bounds = (sender as! NSView).bounds
            bounds.origin = CGPoint(x: bounds.origin.x, y: bounds.origin.y + 2)
            
            popover.show(relativeTo: bounds, of: sender as! NSView, preferredArrowDirection: .down, anchorsToPositionView: true)
            
            // NOTE: The next example is equal in functionality
            // popoverController.show(relativeTo: bounds, of: sender as! NSView, preferredEdge: .maxY, anchorsToPositionView: true)
        }
    }

    func popoverDidClose(_ popover: MTPopover) {
        
        print("popoverDidClose(...)")
    }
    
    func popoverShouldClose(_ popover: MTPopover) -> Bool {
        
        print("popoverShouldClose(...)")
        
        return true
    }
    
    func popoverDidShow(_ popover: MTPopover) {
        
        print("popoverDidShow(...)")
    }
    
    func popoverWillShow(_ popover: MTPopover) {
        
        print("popoverWillShow(...)")
    }
    
    func popoverWillClose(_ popover: MTPopover) {
        
        print("popoverWillClose(...)")
    }
}
