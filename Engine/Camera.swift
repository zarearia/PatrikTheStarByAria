//
//  Camera.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/08/2025.
//

import Foundation

class Camera: Node {
    
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 1000
    
    //Fov for field of view
    var projectionFov: Float = 70
    var projectionFovRadian: Float {
        projectionFov.degreesToRadians
    }
    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: projectionFovRadian,
                        near: near,
                        far: far,
                        aspect: aspect)
    }
    
    func zoom(delta: Float, sensitivity: Float) {
        //This field should be overritten
    }
    func rotate(delta: float2, sensitivity: Float) {
        //This field should be overritten
    }
    
    var viewMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        return (translateMatrix * scaleMatrix * rotateMatrix).inverse
    }
}

