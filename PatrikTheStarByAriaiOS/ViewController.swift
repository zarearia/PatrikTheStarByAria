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
    @IBOutlet var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderer = Renderer(metalView: metalView)
        
        // Do any additional setup after loading the view.
    }


}

