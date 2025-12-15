//
//  ViewController.swift
//  PatrikTheStarByAriaiOS
//
//  Created by Aria Zare on 19/08/2025.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    
    var renderer: Renderer?
    var scene: Scene?
    @IBOutlet var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Renderer.hasFog = false
        renderer = Renderer(metalView: metalView)
        scene = MainScene(size: metalView.frame.size)
        renderer?.scene = scene
        
        
        // Do any additional setup after loading the view.
    }


}

