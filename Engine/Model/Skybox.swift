//
//  Sky.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/05/2026.
//

import MetalKit
import ModelIO

class Skybox {
    
    var name: String
    
    let cubeMesh: MTKMesh
    let renderPipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState
    
    var skyTexture: MTLTexture?
    var irradianceTexture: MTLTexture?
    
    init(name: String) {
        self.name = name
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let mesh = MDLMesh(boxWithExtent: [1, 1, 1], segments: [1, 1, 1], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        
        cubeMesh = try! MTKMesh(mesh: mesh, device: Renderer.device)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = Renderer.device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "verte_skybox")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_skybox")
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(cubeMesh.vertexDescriptor)
        pipelineDescriptor.rasterSampleCount = 4
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineState = try! Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthDescriptor)!
       
//        makeGenerativeSky()
        loadSkyTexture(textureName: "sky")
        loadIrradianceTexture(textureName: "irradiance_sky")
        
    }
    
    func makeGenerativeSky() {
        let sky = MDLSkyCubeTexture(
            name: "sky",
            channelEncoding: .float32,
            textureDimensions: SIMD2<Int32>(128, 128),
            turbidity: 0.1,              // 0=crystal clear, 1=very hazy
            sunElevation: 0.7,           // 0=horizon, 1=overhead
            sunAzimuth: .pi,             // 0-2π, direction of sun
            upperAtmosphereScattering: 0.3,  // how much light scatters
            groundAlbedo: 0.5            // ground reflectivity
        )
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        skyTexture = try! textureLoader.newTexture(texture: sky, options: nil)
    }
    
    func loadSkyTexture(textureName: String) {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        skyTexture = try! textureLoader.newTexture(name: textureName, scaleFactor: 1, bundle: Bundle.main)
    }
    
    func loadIrradianceTexture(textureName: String) {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        irradianceTexture = try! textureLoader.newTexture(name: textureName, scaleFactor: 1, bundle: Bundle.main)
    }
    
    func makeIrradianceTexture(textureName: String) {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let skyTextureMdl = MDLTexture(named: textureName)!
        let irradianceTextureMDL = MDLTexture.irradianceTextureCube(with: skyTextureMdl, name: "skyIrradianceTexture", dimensions: SIMD2<Int32>(64, 64), roughness: 0.7)
        irradianceTexture = try! textureLoader.newTexture(texture: irradianceTextureMDL)
    }
    
    func update(renderEncoder: any MTLRenderCommandEncoder) {
        renderEncoder.setFragmentTexture(skyTexture, index: Int(SkyBoxIndex.rawValue))
        renderEncoder.setFragmentTexture(irradianceTexture, index: Int(DiffuseSkyBoxIndex.rawValue))
    }
    
    
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms) {
        var uniforms = uniforms
        renderEncoder.pushDebugGroup("Skybox: \(name)")
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(cubeMesh.vertexBuffers[0].buffer, offset: 0, index: Int(VerticesBufferIndex.rawValue))
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
        renderEncoder.setFragmentTexture(skyTexture, index: Int(SkyBoxIndex.rawValue))
//        add pipelineState and depth stencil and make all these array calls a variable on top of draw call and dont forget to put the translation of the a part of uniform to 0 so the box won't move around
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: cubeMesh.submeshes[0].indexCount, indexType: cubeMesh.submeshes[0].indexType, indexBuffer: cubeMesh.submeshes[0].indexBuffer.buffer, indexBufferOffset: 0)
        renderEncoder.popDebugGroup()
    }
}

