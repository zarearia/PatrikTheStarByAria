//
//  Node.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/08/2025.
//

import Foundation

class Node {
    var rotation: float3 = float3(0, 0, 0) {
        didSet {
            let rotationMatrix = float4x4(rotation: rotation)
            quaternion = simd_quatf(rotationMatrix)
        }
    }
    
    var quaternion = simd_quatf()
    
    var position: float3 = float3(0, 0, 0)
    var scale: float3 = float3(1, 1, 1)
    
    init() {
        let rotationMatrix = float4x4(rotation: self.rotation)
        self.quaternion = simd_quatf(rotationMatrix)
    }
    
    var modelMatrix: float4x4 {
        let rotationMatrix = float4x4(quaternion)
        let transalationMatrix = float4x4(translation: position)
        let scaleMatrix = float4x4(scaling: scale)
        return transalationMatrix * rotationMatrix * scaleMatrix
    }
}
