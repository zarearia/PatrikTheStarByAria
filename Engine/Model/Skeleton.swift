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
    
    func updatePose(at time: Float, animation: SkeletonAnimation) {
        guard let paletteBuffer = jointPaletteBuffer else {
            return
        }
        
        var palettePointer = paletteBuffer.contents().bindMemory(to: float4x4.self, capacity: jointPaths.count)
        palettePointer.initialize(repeating: .identity(), count: jointPaths.count)
        
        var poses = [float4x4](repeatElement(.identity(), count: jointPaths.count))
        
        for (index, path) in jointPaths.enumerated() {
            //Note: there was a speed that I am not putting here.
            let pose = animation.jointsAnimationAtKeyFrame[path]?.getTransformation(at: time)
            
            var parentPose: float4x4 = .identity()
            if let parentIndex = parentIndices[index] {
                parentPose = poses[parentIndex]
            }
            
            
            let rotationPose = float4x4(pose?.rotationQuatf ?? simd_quatf())
            let translationPose = float4x4(translation: pose?.translation ?? float3.zero)
            let scalePose = float4x4(scaling: float3.one)
            
            let poseMatrix = translationPose * rotationPose * scalePose
            poses[index] = parentPose * poseMatrix
            
            palettePointer.pointee = poses[index] * bindTransform[index].inverse
            palettePointer = palettePointer.advanced(by: 1)
        }
        
    }
}
