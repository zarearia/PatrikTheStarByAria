//
//  ViewController.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 19/08/2025.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

    var renderer: Renderer?
    @IBOutlet var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderer = Renderer(metalView: metalView)
        addGestureRecognizers(to: metalView)
        

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func addGestureRecognizers(to view: NSView) {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let delta = float2(Float(translation.x),
                           Float(translation.y))
        
        renderer?.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer?.camera.zoom(delta: Float(event.deltaY))
    }
}

