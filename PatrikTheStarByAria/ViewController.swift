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
    var scene: Scene?
    @IBOutlet var metalView: MainView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Renderer.hasFog = true
        renderer = Renderer(metalView: metalView)
        scene = MainScene(size: metalView.frame.size)
        renderer?.scene = scene
        addGestureRecognizers(to: metalView)
        
        metalView.controleDelegate = scene
        
//        self.view.window?.makeFirstResponder(self.view)
        

        // Do any additional setup after loading the view.
    }
    
//    override func viewWillAppear() {
//        super.viewWillAppear()
//        
//        self.view.window?.makeFirstResponder(self.view)
//    }

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
        if let camera = renderer?.scene?.camera as? ArcballCamera {
            camera.rotate(delta: delta)
            gesture.setTranslation(.zero, in: gesture.view)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        if let camera = renderer?.scene?.camera as? ArcballCamera {
            camera.zoom(delta: Float(event.deltaY))
        }
    }
}

