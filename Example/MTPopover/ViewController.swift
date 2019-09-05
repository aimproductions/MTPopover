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
    private var popoverController: MTPopover!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onDestroyPressed(_ sender: Any) {
        
        guard let popoverController = popoverController else {
            return
        }
        
        if popoverController.popoverIsVisible {
            popoverController.close()
        }
        
        self.popoverController = nil
    }
    
    @IBAction func onButtonPressed(_ sender: Any) {
        
        
        if popoverController == nil {
            
            let viewController = ContentViewController(nibName: "ContentViewController", bundle: nil)
            popoverController = MTPopover(contentViewController: viewController)
            
            popoverController.cornerRadius = 10
            //popoverController.borderWidth = 0
            //popoverController.arrowSize = NSSize.zero
            popoverController.animationType = .fadeInOut
            popoverController.closesWhenApplicationBecomesInactive = false
            popoverController.closesWhenEscapeKeyPressed = false
            popoverController.closesWhenPopoverResignsKey = false
            popoverController.closesWhenGoingOffscreen = true
            popoverController.delegate = self
        }
        
        if popoverController.popoverIsVisible {
            popoverController.performClose()
        } else {
            popoverController.show(relativeTo: (sender as! NSView).bounds, of: sender as! NSView, preferredArrowDirection: .down, anchorsToPositionView: true)
            // NOTE: The next example is equal in functionality
            // popoverController.show(relativeTo: (sender as! NSView).bounds, of: sender as! NSView, preferredEdge: .maxY, anchorsToPositionView: true)
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
