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
    }
    
    
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms) {
        var uniforms = uniforms
        renderEncoder.pushDebugGroup("Skybox: \(name)")
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(cubeMesh.vertexBuffers[0].buffer, offset: 0, index: Int(VerticesBufferIndex.rawValue))
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
//        add pipelineState and depth stencil and make all these array calls a variable on top of draw call and dont forget to put the translation of the a part of uniform to 0 so the box won't move around
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: cubeMesh.submeshes[0].indexCount, indexType: cubeMesh.submeshes[0].indexType, indexBuffer: cubeMesh.submeshes[0].indexBuffer.buffer, indexBufferOffset: 0)
        renderEncoder.popDebugGroup()
    }
}
