//
//  MainScene.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/11/2025.
//

protocol ControleDelegate {
    func keyDown(keyCode: KeyCode)
    func keyUp(keyCode: KeyCode)
}

class MainScene: Scene {
    
    
    var groundModel = Model(name: "ground", resourse: "ground", extention: "obj")
    var patrik = Model(name: "patrik3", resourse: "patrik3", extention: "usdz")
    
    var freeCameraController: Controllable = CameraController()
    var thirdPersonCameraController: Controllable = CameraController()
    
    // true is camera, false is patrik focus
    var freeCameraOn: Bool = true
    
    //TODO: back architecture decision replace this
    var patrikMovingForward: Bool = false
    
//    var train = Model(name: "train", resourse: "train", extention: "obj")
    var arcballCamera = ArcballCamera()
    var freeCamera = Camera()
    var thirdPersonCamera = Camera()
    
    override func setupScene() {
        
        freeCameraController.controlled = freeCamera
        freeCameraController.rotationSpeed = 0.1
        freeCameraController.directionSpeed = 0.1
        freeCameraController.isMoving = false
        
        thirdPersonCameraController.controlled = thirdPersonCamera
        thirdPersonCameraController.rotationSpeed = 0.1
        thirdPersonCameraController.directionSpeed = 0.1
        thirdPersonCameraController.isMoving = true

        arcballCamera.zoom(delta: -30)
        arcballCamera.rotate(delta: [180, -5])
        arcballCamera.target = [0, 1, 0]
        
        freeCamera.rotation = [0, 0, 0]
        freeCamera.position = [0, 1, -1]
        
        cameras.append(arcballCamera)
        cameras.append(freeCamera)
        cameras.append(thirdPersonCamera)
        currentCameraIndex = 3
        
        groundModel.tiling = 4
        
        add(node: groundModel)
        
        thirdPersonCamera.position = patrik.position
        thirdPersonCamera.position.y += 2
        
        add(node: patrik, parent: thirdPersonCamera)
        
        patrik.position.z += 3
        patrik.position.y -= 1.5
    }
    
    override func updateScene(deltaTime: Float) {
        freeCameraController.updateControled(deltaTime: deltaTime)
        thirdPersonCameraController.updateControled(deltaTime: deltaTime)
    }
    
    override func keyDown(keyCode: KeyCode) {
        
        
        switch keyCode {
        default:
            break
        }
        
        freeCameraController.keyDown(keyCode: keyCode)
        thirdPersonCameraController.keyDown(keyCode: keyCode)
    }
    
    override func keyUp(keyCode: KeyCode) {
        
        switch keyCode {
        case .c:
            freeCameraController.isMoving.toggle()
            thirdPersonCameraController.isMoving.toggle()
        default:
            break
        }
        
        freeCameraController.keyUp(keyCode: keyCode)
        thirdPersonCameraController.keyUp(keyCode: keyCode)
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
