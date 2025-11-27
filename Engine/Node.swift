//
//  Node.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/08/2025.
//

import Foundation

class Node {
    weak var parent: Node?
    var children: [Node] = []
    
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
    
    convenience init(parent: Node?) {
        self.init()
        self.parent = parent
    }
    
    var modelMatrix: float4x4 {
        let rotationMatrix = float4x4(quaternion)
        let transalationMatrix = float4x4(translation: position)
        let scaleMatrix = float4x4(scaling: scale)
        return transalationMatrix * rotationMatrix * scaleMatrix
    }
    
    var forwardVector: float3 {
        simd_normalize([cos(rotation.x) * sin(rotation.y),
         sin(rotation.x),
         cos(rotation.x) * cos(rotation.y)
        ])
    }
    
    var rightVector: float3 {
        simd_normalize([cos(rotation.y - (.pi / 2)),
         0,
         sin(rotation.y - (.pi / 2))
        ])
    }
    
    var worldLocation: float4x4 {
        if let parent {
            //NOTE: if we write it like parent.modelMatrix * modelMatrix, it will of course, mess up things
            return parent.modelMatrix * modelMatrix
        }
        return modelMatrix
    }
    
    func addChild(node: Node) {
        children.append(node)
        node.parent = self
    }
    
    func removeChild(child: Node) {
        child.parent = nil
        //if a child is removed from parent, the grandchildren will not be associated with grand parent(they will stay with parent), to be seen if in the future it would seem problematic or not
        self.children.removeAll { $0 === child }
    }
    
    func update(deltaTime: Float) {
        //override this
    }
}
