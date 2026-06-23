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
    var morphTargetResources: [(resource: String, extention: String)]?
    var morphTextures: [String]?
    
    var vertexCount: Int?
    var morphingVertexBuffer: MTLBuffer?
    
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
    init(name: String, resourse: String, extention: String, vertex_function: String = "vertex_main", fragment_function: String = "fragment_main", instanceCount: Int = 1, isMorphing: Bool = false, morphTargetResources: [(resource: String, extention: String)]? = nil, morphTextures: [String]? = nil) {
        self.name = name
        
        self.vertex_function = vertex_function
        self.fragment_function = fragment_function
        
        guard let assetURL = Bundle.main.url(forResource: resourse, withExtension: extention) else
        {
            fatalError()
        }
        
        self.isMorphing = isMorphing
        self.morphTargetResources = morphTargetResources
        self.morphTextures = morphTextures
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
        
        instances = Array(repeating: Instance(modelMatrix: matrix_float4x4.identity(), morphTextureId: 0, morphTargetId: 0), count: instanceCount)
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
        
        // for rock which has 1 mesh at the moment
        if isMorphing,
           let morphTargetResources,
           let mesh = meshes.first?.mtkMesh,
           let vertexBuffer = self.meshes.first?.mtkMesh.vertexBuffers,
           let bufferSize = vertexBuffer.first?.length,
           let vertexLayout = mesh.vertexDescriptor.layouts[0] as? MDLVertexBufferLayout,
           let morphingVertexBuffer = Renderer.device.makeBuffer(length: bufferSize * morphTargetResources.count)
        {
            self.morphingVertexBuffer = morphingVertexBuffer
            self.vertexCount = bufferSize / vertexLayout.stride
            
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
            let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
            
            for i in 0..<morphTargetResources.count {
                let targetResource = morphTargetResources[i]
                guard let mesh = Model.loadMesh(resourceName: targetResource.resource, resourceExtention: targetResource.extention) else {
                    fatalError("could not load the morphTargetMesh")
                }
                let meshBuffer = mesh.vertexBuffers[0].buffer
                
                blitEncoder?.copy(from: meshBuffer,
                                  sourceOffset: 0,
                                  to: morphingVertexBuffer,
                                  destinationOffset: i * bufferSize,
                                  size: meshBuffer.length)
            }
            blitEncoder?.endEncoding()
            commandBuffer?.commit()
        }
    }
    
    func updateInstanceBuffer() {
        
        instancesBuffer = Renderer.device.makeBuffer(length: MemoryLayout<Instance>.stride * instanceCount)
        
        guard let pointer: UnsafeMutablePointer<Instance> = instancesBuffer?.contents().bindMemory(to: Instance.self, capacity: instanceCount) else { return }
        
        for i in 0..<instanceCount {
            let itemUnsafe = pointer.advanced(by: i)
            itemUnsafe.pointee.modelMatrix = instances[i].modelMatrix
            itemUnsafe.pointee.morphTargetId = instances[i].morphTargetId
            itemUnsafe.pointee.morphTextureId = instances[i].morphTextureId
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
    
    static func loadMesh(resourceName: String, resourceExtention: String) -> MTKMesh? {
        guard let assetURL = Bundle.main.url(forResource: resourceName, withExtension: resourceExtention) else
        {
            fatalError()
        }
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: Model.vertexDescriptor, bufferAllocator: allocator)
        
        guard let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh else {
            return nil
        }
        
        let mtkMesh = try? MTKMesh(mesh: mdlMesh, device: Renderer.device)
        
        
        return mtkMesh
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
            
            if isMorphing {
                renderEncoder.setVertexBuffer(self.morphingVertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&vertexCount, length: MemoryLayout<Int>.stride, index: Int(VertexCountIndexBuffer.rawValue))
            } else {
                for (index, buffer) in mtkMesh.vertexBuffers.enumerated() {
                    renderEncoder.setVertexBuffer(mtkMesh.vertexBuffers[index].buffer, offset: mtkMesh.vertexBuffers[index].offset, index: index)
                }
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
