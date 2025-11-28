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
    
    // true is camera, false is patrik focus
    var focusOnCamera: Bool = true
    
    //TODO: back architecture decision replace this
    var patrikMovingForward: Bool = false
    
//    var train = Model(name: "train", resourse: "train", extention: "obj")
    var arcballCamera = ArcballCamera()
    var normalCamera = Camera()
    
    var cameraDirection: float3 = .zero
    var cameraRotation: float3 = .zero
    
    override func setupScene() {
        
        arcballCamera.zoom(delta: -30)
        arcballCamera.rotate(delta: [180, -5])
        arcballCamera.target = [0, 1, 0]
        
//        normalCamera.zoom(delta: -30)
        normalCamera.rotation = [0, 0, 0]
        normalCamera.position = [0, 1, -1]
        
        cameras.append(arcballCamera)
        cameras.append(normalCamera)
        currentCameraIndex = 2
        
        groundModel.tiling = 4
        
        add(node: groundModel)
        add(node: patrik)
//        add(node: patrik, parent: train)
//        add(node: train)
        
//        train.position = [0, 1, 0]
        patrik.rotation = [0, 0, 0]
        
    }
    
    override func updateScene(deltaTime: Float) {
//        if patrikMovingForward {
//            patrik.position += (patrik.forwardVector/10)
//        }
        
        let camera1 = cameraDirection.z * (normalCamera.forwardVector / 10)
        let camera2 = cameraDirection.x * (normalCamera.rightVector / 10)
        let camera3 = cameraDirection.y * (normalCamera.upVector / 10)
        normalCamera.position += (camera1 + camera2 + camera3)
        normalCamera.rotation += (cameraRotation / 10)

//        arcballCamera.position = patrik.position
//        arcballCamera.target = patrik.position
//        normalCamera.position = patrik.position
//        normalCamera.position.z -= 1
//        normalCamera.position.y = 1
//        camera.position.z += 1
//        train.position.x += deltaTime
    }
    
    override func keyDown(keyCode: KeyCode) {
        if focusOnCamera {
//            updateCamera(keyCode: keyCode)
            updateCameraKeyDown(keyCode: keyCode)
            return
        }
        
        switch keyCode {
        case .w:
            patrikMovingForward = true
        default:
            break
        }
    }
    
    override func keyUp(keyCode: KeyCode) {
        if focusOnCamera {
//            updateCamera(keyCode: keyCode)
            updateCameraKeyUp(keyCode: keyCode)
            return
        }
        
        switch keyCode {
        case .w:
            patrikMovingForward = false
        case .c:
            focusOnCamera.toggle()
        default:
            break
        }
    }
    
    func updateCameraKeyDown(keyCode: KeyCode) {
        
        switch keyCode {
        case .w:
            cameraDirection.z += 1
//            camera.position += (camera.rightVector/10)
//            print(camera.position)
        case .a:
            cameraDirection.x += -1
//            camera.position -= (camera.rightVector/10)
        case .s:
            cameraDirection.z += -1
//            camera.position -= (camera.rightVector/10)
        case .d:
            cameraDirection.x += 1
//            camera.position += (camera.rightVector/10)
        case .z:
            cameraDirection.y += 1
        case .x:
            cameraDirection.y += -1
        case .e:
            cameraRotation.y += 1
        case .q:
            cameraRotation.y += -1
        case .f:
            cameraRotation.x += 1
        case .g:
            cameraRotation.x += -1
        default:
            break
        }
    }
    
    func updateCameraKeyUp(keyCode: KeyCode) {
        switch keyCode {
        case .w:
            cameraDirection.z -= 1
//            camera.position += (camera.rightVector/10)
//            print(camera.position)
        case .a:
            cameraDirection.x -= -1
//            camera.position -= (camera.rightVector/10)
        case .s:
            cameraDirection.z -= -1
//            camera.position -= (camera.rightVector/10)
        case .d:
            cameraDirection.x -= 1
//            camera.position += (camera.rightVector/10)
        case .z:
            cameraDirection.y -= 1
        case .x:
            cameraDirection.y -= -1
        case .e:
            cameraRotation.y -= 1
        case .q:
            cameraRotation.y -= -1
        case .f:
            cameraRotation.x -= 1
        case .g:
            cameraRotation.x -= -1
        default:
            break
        }
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
