//
//  ArcballCamera.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 27/08/2025.
//

import Foundation

class ArcballCamera: Camera {
    
    var target: float3 = [0, 0, 0] {
        didSet {
            updateViewMatrix()
        }
    }
    
    override init() {
        super.init()
        _viewMatrix = viewMatrix
    }
    private var _viewMatrix: matrix_float4x4 = .identity()
    
    var distance: Float = 0 {
        didSet {
            updateViewMatrix()
        }
    }
    
    override var rotation: float3 {
        didSet {
            updateViewMatrix()
        }
    }
    
    override var viewMatrix: float4x4 {
        return _viewMatrix
    }
    
    private func updateViewMatrix() {
        let translationMatrix = float4x4(translation: float3(target.x, target.y, target.z - distance))
        let rotationMatrix = float4x4(rotationYXZ: float3(rotation.x, rotation.y, 0))
//      TODO: Calclulate the linear algebra on paper for this inverse
        let transformationMatrix = (rotationMatrix * translationMatrix).inverse
        
        //TODO: Calculate the math of this again
        position = rotationMatrix.upperLeft * -transformationMatrix.columns.3.xyz
        
        _viewMatrix = transformationMatrix
    }
    
    override func zoom(delta: Float, sensitivity: Float = 0.1) {
        distance -= delta * sensitivity
        updateViewMatrix()
    }
    
    override func rotate(delta: float2, sensitivity: Float = 0.05) {
        rotation.y += delta.x * sensitivity
        rotation.x -= delta.y * sensitivity
        rotation.x = max(-Float.pi / 2, min(Float.pi / 2, rotation.x))
        updateViewMatrix()
    }
    
}

