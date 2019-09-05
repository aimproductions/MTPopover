//
//  ViewController.swift
//  MTPopover
//
//  Created by mylemans on 09/05/2019.
//  Copyright (c) 2019 mylemans. All rights reserved.
//

import Cocoa
import MTPopover

class ViewController: NSViewController {
    private var popoverController: MTPopover!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onDestroyPressed(_ sender: Any) {
        
        guard let popoverController = popoverController else {
            return
        }
        
        if popoverController.popoverIsVisible {
            popoverController.closePopover(sender)
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
        }
        
        if popoverController.popoverIsVisible {
            popoverController.closePopover(sender)
        } else {
            popoverController.presentPopover(positioningRect: (sender as! NSView).bounds, of: sender as! NSView, preferredArrowDirection: .down, anchorsToPositionView: true)
        }
    }


}

