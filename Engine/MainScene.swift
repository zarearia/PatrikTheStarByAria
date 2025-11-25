//
//  MainScene.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/11/2025.
//

class MainScene: Scene {
    
    var groundModel = Model(name: "ground", resourse: "ground", extention: "obj")
    var patrik = Model(name: "patrik3", resourse: "patrik3", extention: "usdz")
//    var train = Model(name: "train", resourse: "train", extention: "obj")
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
//        add(node: patrik, parent: train)
//        add(node: train)
        
//        train.position = [0, 1, 0]
        patrik.rotation = [0, 180, 0]
        
    }
    
    override func updateScene(deltaTime: Float) {
//        train.position.x += deltaTime
    }
}


//NOTE: Some Lights for the future:
//position is not useful for ambientLight
//        let ambientLight = Light(type: Ambientlight,
//                                 position: [0, 0, 0],
//                                 color: [1, 0, 0],
//                                 specularColor: [0, 0, 0],
//                                 attenuation: [1, 0, 0],
//                                 intensity: 0.2)
//        lights.append(ambientLight)

//        var pointLight = Light()
//        pointLight.color = float3(1, 1, 0)
//        pointLight.position = float3(1, 2, 1)
//        pointLight.intensity = 1
//        pointLight.attenuation = [1, 1, 1]
//        pointLight.type = PointLight
//        pointLight.specularColor = float3(1, 1, 1)
//        lights.append(pointLight)

//        var spotLight = Light()
//        spotLight.color = float3(1, 1, 0)
//        spotLight.position = float3(1, 2, 1)
//        spotLight.intensity = 1
//        spotLight.attenuation = [1, 1, 1]
//        spotLight.type = SpotLight
//        spotLight.specularColor = float3(1, 1, 1)
//
//        spotLight.coneAttenuation = 0.1
//        spotLight.coneAngel = 30
//        spotLight.coneDirection = [1, 1, -1]
//        lights.append(spotLight)
/***************/
