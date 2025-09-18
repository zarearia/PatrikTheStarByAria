//
//  Skeleton.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 18/09/2025.
//

import MetalKit

struct Skeleton {
    let parentIndices: [Int?]
    let bindTransform: [float4x4]
    let restTransform: [float4x4]
    let jointPaths: [String]
    let jointPaletteBuffer: MTLBuffer?
    
    init?(animationBindComponent: MDLAnimationBindComponent?) {
        
        guard let bindComponentSkeleton = animationBindComponent?.skeleton else {
            return nil
        }
        
        self.parentIndices = Skeleton.makeParentIndices(skeleton: bindComponentSkeleton)
        self.bindTransform = bindComponentSkeleton.jointBindTransforms.float4x4Array
        self.restTransform = bindComponentSkeleton.jointRestTransforms.float4x4Array
        self.jointPaths = bindComponentSkeleton.jointPaths
        self.jointPaletteBuffer = Renderer.device.makeBuffer(length: jointPaths.count * MemoryLayout<float4x4>.stride)
    }
    
    static func makeParentIndices(skeleton: MDLSkeleton) -> [Int?] {
        let jointPaths = skeleton.jointPaths
        var parentIndices: [Int?] =  [Int?](repeating: nil, count: jointPaths.count)
        for (jointIndex, jointPath) in jointPaths.enumerated() {
            let jointParentName = URL(string: jointPath)?.deletingLastPathComponent().relativePath
            parentIndices[jointIndex] = jointPaths.firstIndex {
                jointParentName == $0
            }
        }
        
        return parentIndices
    }
}
