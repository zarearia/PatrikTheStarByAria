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
    
    var animations: [String: SkeletonAnimation]
    var pipelineState: MTLRenderPipelineState!
    
    init(resourse: String, extention: String) {
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
        ////////////////////////////////////
        
        
        
        
        
        self.asset.loadTextures()
        
        super.init()
        
        guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            return
        }
        
        samplerState = buildSamplerState()
        
        _ = mdlMeshes.map {
            do {
                let mesh: Mesh = try Mesh(mtkMesh: MTKMesh(mesh: $0, device: Renderer.device), mdlMesh: $0)
                meshes.append(mesh)
            } catch(let error) {
                print("failed to load Mesh: \(error)")
            }
            
        }
        
        makePipelineState(hasSkeleton: !animations.isEmpty)
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
    
    func update(deltaTime: Float) {
        for mesh in meshes {
            if let skeletonAnimation = animations.first?.value {
                mesh.skeleton?.updatePose(at: deltaTime, animation: skeletonAnimation)
            }
        }
    }
    
    // send this to submesh later to be able to add texture constants
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

extension Model: Renderable {
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        
        var fragmentUniforms = fragment
        fragmentUniforms.tiling = tiling
        
        var modelUniforms = uniforms
        
        modelUniforms.modelMatrix = self.modelMatrix
        renderEncoder.setVertexBytes(&modelUniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: Int(FragmentUniformsBufferIndex.rawValue))
        
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        //60 frames per second
        time += 1 / Float(60)
        update(deltaTime: time)
        
        for mesh in self.meshes {
            if let paletteBuffer = mesh.skeleton?.jointPaletteBuffer {
                renderEncoder.setVertexBuffer(paletteBuffer, offset: 0, index: 22)
            }
            let mtkMesh = mesh.mtkMesh
            let submeshs = mesh.submeshes
            
            renderEncoder.setRenderPipelineState(pipelineState)
            
            renderEncoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer, offset: mtkMesh.vertexBuffers[0].offset, index: 0)
            
            for submeshe in submeshs {
                
                //TODO: Add texture submeshes here
                renderEncoder.setFragmentTexture(submeshe.baseColorTexture, index: 0)
                
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
