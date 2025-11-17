//
//  Meshe.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 03/09/2025.
//

import MetalKit

class Mesh: NSObject {
    var submeshes: [Submesh] = []
    var mtkMesh: MTKMesh
    let skeleton: Skeleton?
    //TODO: Fix the forced unwrapping later
    var pipelineState: MTLRenderPipelineState!
    
    init(mtkMesh: MTKMesh, mdlMesh: MDLMesh) {
        self.mtkMesh = mtkMesh
        self.skeleton = Skeleton(animationBindComponent: (mdlMesh.componentConforming(to: MDLComponent.self) as? MDLAnimationBindComponent))
        if let mdlSubmeshes: [MDLSubmesh] = mdlMesh.submeshes as? [MDLSubmesh] {
            
            self.submeshes = zip(mtkMesh.submeshes, mdlSubmeshes).map { mesh in
                Submesh(mtkSubmesh: mesh.0, mdlSubmesh: mesh.1 as MDLSubmesh)
            }
            
        }
        super.init()
        makePipelineState(hasSkeleton: skeleton != nil)
//        self.submeshes = Submesh(mtkSubmesh: mtkSubmesh.submeshes, mdlMesh: mdlMesh.submeshes!)
    }
    
    func makePipelineState(hasSkeleton: Bool) {
        let vertexFunction: MTLFunction?
        let functionConstant = MTLFunctionConstantValues()
        
        var hasSkeleton = hasSkeleton
        functionConstant.setConstantValue(&hasSkeleton, type: .bool, index: 0)
        
        
        vertexFunction = try! Renderer.library.makeFunction(name: "vertex_main", constantValues: functionConstant)
        let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        
        
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MDLVertexDescriptor.getDefaultVertexDescriptor())
        
        do {
            try pipelineState = Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
}
