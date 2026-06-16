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
    let vertex_function: String
    let fragment_function: String
    var instances: [Instance] = []
    var instanceCount: Int {
        instances.count
    }
    var instancesBuffer: MTLBuffer?
    
    var isMorphing: Bool = false
    
    var isAnimating: Bool = false
    
    var animations: [String: SkeletonAnimation]
    
    static var showDebugBoundingBox = false
    
    var costumeRender: ((MTLRenderCommandEncoder) -> Void)?
    
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.getDefaultVertexDescriptor()
    
    /// at first will be inited with the first animation available
    var currentAnimation: String?
    
    var debugBoundingBoxRenderer: BoundingBoxRenderer?
    
    /**
        if you set isMorphing to true, you will need ti handle vertexDescription and some other buffer related stuff yourself.
     */
    init(name: String, resourse: String, extention: String, vertex_function: String = "vertex_main", fragment_function: String = "fragment_main", instanceCount: Int = 1, isMorphing: Bool = false) {
        self.name = name
        
        self.vertex_function = vertex_function
        self.fragment_function = fragment_function
        
        guard let assetURL = Bundle.main.url(forResource: resourse, withExtension: extention) else
        {
            fatalError()
        }
        
        self.isMorphing = isMorphing
        Model.vertexDescriptor = isMorphing ? MDLVertexDescriptor.getMorphingVertexDescriptor() : MDLVertexDescriptor.getDefaultVertexDescriptor()
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        self.asset = MDLAsset(url: assetURL, vertexDescriptor: Model.vertexDescriptor, bufferAllocator: allocator)
        
        
        
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
        
        instances = Array(repeating: Instance(modelMatrix: matrix_float4x4.identity()), count: instanceCount);
        super.init()
        
        updateInstanceBuffer()
        
        boundingBox = asset.boundingBox
        debugBoundingBoxRenderer = BoundingBoxRenderer(boundingBox: boundingBox)
        
        guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            return
        }
        
        samplerState = buildSamplerState()
        
        _ = mdlMeshes.map {
            do {
                $0.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
                let mesh: Mesh = try Mesh(mtkMesh: MTKMesh(mesh: $0, device: Renderer.device), mdlMesh: $0, vertex_function: vertex_function, fragment_function: fragment_function)
                // set's tangent and bitangent at buffer 1 and 2(0 is taken by me)
                Model.vertexDescriptor = $0.vertexDescriptor
                meshes.append(mesh)
            } catch(let error) {
                print("failed to load Mesh: \(error)")
            }
            
        }
        
    }
    
    func updateInstanceBuffer() {
        
        instancesBuffer = Renderer.device.makeBuffer(length: MemoryLayout<Instance>.stride * instanceCount)
        
        guard let pointer: UnsafeMutablePointer<Instance> = instancesBuffer?.contents().bindMemory(to: Instance.self, capacity: instanceCount) else { return }
        
        for i in 0..<instanceCount {
            let itemUnsafe = pointer.advanced(by: i)
            itemUnsafe.pointee.modelMatrix = instances[i].modelMatrix
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
            
            renderEncoder.setVertexBuffer(instancesBuffer, offset: 0, index: Int(InstancesBufferIndex.rawValue))
            
            for submesh in submeshs {
                
                var material = submesh.material
                
                renderEncoder.setRenderPipelineState(submesh.pipelineState!)
                
                //TODO: Add texture submeshes here
                renderEncoder.setFragmentTexture(submesh.baseColorTexture, index: Int(BaseColorTextureIndex.rawValue))
                renderEncoder.setFragmentTexture(submesh.normalTexture, index: Int(NormalColorTextureIndex.rawValue))
                renderEncoder.setFragmentTexture(submesh.metalicTexture, index: Int(MetalicTextureIndex.rawValue))
                renderEncoder.setFragmentTexture(submesh.routhnessTexture, index: Int(RouthnessTextureIndex.rawValue))
                renderEncoder.setFragmentTexture(submesh.ambientOcclusion, index: Int(AmbientOcclusionTextureIndex.rawValue))
                
                renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: Int(MaterialBufferIndex.rawValue))
                
                
                let mtkSubmesh = submesh.mtkSubmesh
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: mtkSubmesh.indexCount,
                    indexType: mtkSubmesh.indexType,
                    indexBuffer:
                        mtkSubmesh.indexBuffer.buffer,
                    indexBufferOffset: 0,
                    instanceCount: instanceCount
                )
            }
        }
        
//        debugBoundingBoxRenderer?.debugBoundingBox(rendereEncoder: renderEncoder, uniforms: modelUniforms)
    }
}
