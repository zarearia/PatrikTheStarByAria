//
//  Scene.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 20/11/2025.
//

import MetalKit

class Scene {
    var size: CGSize
    
    var cameras: [Camera] = [Camera()]
    var currentCameraIndex: Int = 0
    var camera: Camera {
        cameras[currentCameraIndex]
    }
    
    init(size: CGSize) {
        self.size = size
        setupScene()
    }
    
    func setupScene() {
        //should be overwritten
    }
    
}
