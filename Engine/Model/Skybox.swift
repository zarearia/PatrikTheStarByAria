//
//  Sky.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/05/2026.
//

import MetalKit
import ModelIO

class Skybox: Renderable {
    
    var name: String
    
    let cubeMesh: MTKMesh
    let pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState
    
    init(name: String) {
        self.name = name
        let allocator = MDLMeshBufferDataAllocator()
        let mesh = MDLMesh(boxWithExtent: [1, 1, 1], segments: [1, 1, 1], inwardNormals: true, geometryType: .triangles, allocator: allocator)
        
        cubeMesh = try! MTKMesh(mesh: mesh, device: Renderer.device)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = Renderer.device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "verte_skybox")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_skybox")
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(cubeMesh.vertexDescriptor)
        pipelineState = try! Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthDescriptor)!
    }
    
    
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        var uniforms = uniforms
        renderEncoder.setVertexBuffer(cubeMesh.vertexBuffers[0].buffer, offset: 0, index: Int(VerticesBufferIndex.rawValue))
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
//        add pipelineState and depth stencil and make all these array calls a variable on top of draw call and dont forget to put the translation of the a part of uniform to 0 so the box won't move around
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: cubeMesh.submeshes[0].indexCount, indexType: cubeMesh.submeshes[0].indexType, indexBuffer: cubeMesh.submeshes[0].indexBuffer.buffer, indexBufferOffset: 0)
    }
}
