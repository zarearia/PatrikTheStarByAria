//
//  Model.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 24/08/2025.
//

import MetalKit
import ModelIO
import os

class Model: Node {
    let asset: MDLAsset
    var meshes: [Mesh] = []
    var tiling: UInt32 = 1
    var samplerState: MTLSamplerState?
    var time: Float = 0
    var name: String
    
    var isAnimating: Bool = false
    
    var animations: [String: SkeletonAnimation]
    
    var costumeRender: ((MTLRenderCommandEncoder) -> Void)?
    
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.getDefaultVertexDescriptor()
    
    /// at first will be inited with the first animation available
    var currentAnimation: String?
    
    init(name: String, resourse: String, extention: String) {
        self.name = name
        
        guard let assetURL = Bundle.main.url(forResource: resourse, withExtension: extention) else
        {
            fatalError()
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        self.asset = MDLAsset(url: assetURL, vertexDescriptor: MDLVertexDescriptor.getDefaultVertexDescriptor(), bufferAllocator: allocator)
        
        
        
        
        //Animation tests
        ////////////////////////////////////animations
        let packedJointAnimations = self.asset.animations.objects.compactMap { animationObject in
            animationObject as? MDLPackedJointAnimation
        }
        
        var animations: [String: SkeletonAnimation] = [:]
        for item in packedJointAnimations {
            animations[item.name] = AnimationHelpers.loadAnimation(packedAnimation: item)
        }
        
        self.animations = animations
        
        for animation in animations {
            print("animation: \(animation.key)")
        }
        
        currentAnimation = animations.first?.key
        
        ////////////////////////////////////
        
        
        
        
        
        self.asset.loadTextures()
        
        super.init()
        
        guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            return
        }
        
        samplerState = buildSamplerState()
        
        _ = mdlMeshes.map {
            do {
                $0.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
                let mesh: Mesh = try Mesh(mtkMesh: MTKMesh(mesh: $0, device: Renderer.device), mdlMesh: $0)
                // set's tangent and bitangent at buffer 1 and 2(0 is taken by me)
                Model.vertexDescriptor = $0.vertexDescriptor
                meshes.append(mesh)
            } catch(let error) {
                print("failed to load Mesh: \(error)")
            }
            
        }
        
    }
    
    func buildSamplerState() -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        //this has a preformance trade off
        descriptor.maxAnisotropy = 8
        
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        return Renderer.device.makeSamplerState(descriptor: descriptor)
    }
    
    override func update(deltaTime: Float) {
        if isAnimating {
            time += deltaTime
        }
        
        let currentAnimation = animations.first(where: {
            self.currentAnimation == $0.key
        })
        
        if currentAnimation == nil {
            print("Animation was not found")
        }
        
        for mesh in meshes {
            if let skeletonAnimation = currentAnimation?.value {
                mesh.skeleton?.updatePose(at: time, animation: skeletonAnimation)
            }
        }
    }
    
    // send this to submesh later to be able to add texture constants

}

extension Model: Renderable {
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        
        var fragmentUniforms = fragment
        fragmentUniforms.tiling = tiling
        
        var modelUniforms = uniforms
        
        modelUniforms.modelMatrix = self.worldLocation
        renderEncoder.setVertexBytes(&modelUniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: Int(FragmentUniformsBufferIndex.rawValue))
        
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        if let costumeRender {
            costumeRender(renderEncoder)
        }
        
        //60 frames per second
        let deltaTime = 1 / Float(60)
        update(deltaTime: deltaTime)
        
        for mesh in self.meshes {
            if let paletteBuffer = mesh.skeleton?.jointPaletteBuffer {
                renderEncoder.setVertexBuffer(paletteBuffer, offset: 0, index: Int(JointsBufferIndex.rawValue))
            }
            let mtkMesh = mesh.mtkMesh
            let submeshs = mesh.submeshes
            
            for (index, buffer) in mtkMesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(mtkMesh.vertexBuffers[index].buffer, offset: mtkMesh.vertexBuffers[index].offset, index: index)
            }
            
            for submeshe in submeshs {
                
                renderEncoder.setRenderPipelineState(submeshe.pipelineState!)
                
                //TODO: Add texture submeshes here
                renderEncoder.setFragmentTexture(submeshe.baseColorTexture, index: Int(BaseColorTextureIndex.rawValue))

                renderEncoder.setFragmentBytes(&submeshe.baseColorSolidColor, length: MemoryLayout<float3>.stride, index: Int(BaseSolidColorBufferIndex.rawValue))
                
                renderEncoder.setFragmentTexture(submeshe.normalTexture, index: Int(NormalColorTextureIndex.rawValue))
                renderEncoder.setFragmentBytes(&submeshe.normalSolidColor, length: MemoryLayout<float3>.stride, index: Int(NormalSolidColorBufferIndex.rawValue))
                
                let mtkSubmesh = submeshe.mtkSubmesh
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: mtkSubmesh.indexCount,
                    indexType: mtkSubmesh.indexType,
                    indexBuffer:
                        mtkSubmesh.indexBuffer.buffer,
                    indexBufferOffset: 0
                )
            }
        }
    }
}
