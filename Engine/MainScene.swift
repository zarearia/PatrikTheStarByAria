//
//  MainScene.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/11/2025.
//

class MainScene: Scene {
    
    var groundModel = Model(name: "ground", resourse: "ground", extention: "obj")
    var patrik = Model(name: "patrik", resourse: "patrik", extention: "usda")
    var arcballCamera = ArcballCamera()
    
    override func setupScene() {
        
        arcballCamera.zoom(delta: -30)
        arcballCamera.rotate(delta: [180, -5])
        arcballCamera.target = [0, 1, 0]
        
        cameras.append(arcballCamera)
        currentCameraIndex = 1
        
        groundModel.tiling = 4
        
        add(node: groundModel)
        add(node: patrik)
        
    }
}
