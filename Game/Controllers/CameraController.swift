//
//  Controller.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 30/11/2025.
//



class CameraController: Controllable {
    var controlled: Node?
    
    var direction: float3 = .zero
    var rotation: float3 = .zero
    
    func updateControled(deltaTime: Float) {
        guard let controlled else {
            fatalError("no controlled set")
        }
        let zUpdate = direction.z * (controlled.forwardVector / 10)
        let xUpdate = direction.x * (controlled.rightVector / 10)
        let yUpdate = direction.y * (controlled.upVector / 10)
        controlled.position += (xUpdate + zUpdate + yUpdate)
        controlled.rotation += (rotation / 10)
    }
    
    func keyUp(keyCode: KeyCode) {
        switch keyCode {
        case .w:
            direction.z -= 1
        case .a:
            direction.x -= -1
        case .s:
            direction.z -= -1
        case .d:
            direction.x -= 1
        case .z:
            direction.y -= 1
        case .x:
            direction.y -= -1
        case .e:
            rotation.y -= 1
        case .q:
            rotation.y -= -1
        case .f:
            rotation.x -= 1
        case .g:
            rotation.x -= -1
        default:
            break
        }
    }
    
    func keyDown(keyCode: KeyCode) {
        switch keyCode {
        case .w:
            direction.z += 1
        case .a:
            direction.x += -1
        case .s:
            direction.z += -1
        case .d:
            direction.x += 1
        case .z:
            direction.y += 1
        case .x:
            direction.y += -1
        case .e:
            rotation.y += 1
        case .q:
            rotation.y += -1
        case .f:
            rotation.x += 1
        case .g:
            rotation.x += -1
        default:
            break
        }
    }
}
