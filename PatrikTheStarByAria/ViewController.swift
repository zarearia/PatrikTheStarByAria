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
        

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

