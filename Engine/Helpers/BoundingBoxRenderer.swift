//
//  BoundingBoxRenderer.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 16/12/2025.
//

import Metal
import ModelIO

class BoundingBoxRenderer {
    
    var pipelineState: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    var boundingBox: MDLAxisAlignedBoundingBox
    var testVertices: [float3]
    
    init(boundingBox: MDLAxisAlignedBoundingBox) {
        let vertexFunction = Renderer.library.makeFunction(name: "vertex_debug")
        let fragmentFunction = Renderer.library.makeFunction(name: "fragment_debug")
        
        let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        //TODO: globalize sample counts
        pipelineDescriptor.sampleCount = 4
        
        do {
            self.pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch (let error) {
            fatalError(error.localizedDescription)
        }
         
        self.boundingBox = boundingBox
       
        testVertices = [
            [boundingBox.minBounds.x, boundingBox.minBounds.y, boundingBox.minBounds.z], // 0: min corner
            [boundingBox.maxBounds.x, boundingBox.minBounds.y, boundingBox.minBounds.z], // 1: +X
            [boundingBox.minBounds.x, boundingBox.maxBounds.y, boundingBox.minBounds.z], // 2: +Y
            [boundingBox.maxBounds.x, boundingBox.maxBounds.y, boundingBox.minBounds.z], // 3: +X+Y
            [boundingBox.minBounds.x, boundingBox.minBounds.y, boundingBox.maxBounds.z], // 4: +Z
            [boundingBox.maxBounds.x, boundingBox.minBounds.y, boundingBox.maxBounds.z], // 5: +X+Z
            [boundingBox.minBounds.x, boundingBox.maxBounds.y, boundingBox.maxBounds.z], // 6: +Y+Z
            [boundingBox.maxBounds.x, boundingBox.maxBounds.y, boundingBox.maxBounds.z]  // 7: max corner
        ]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: &testVertices, length: MemoryLayout<float3>.stride * testVertices.count)!
    }
    
    func debugBoundingBox(rendereEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms) {
         
        rendereEncoder.pushDebugGroup("boundingbox")
        var renderUniforms = uniforms
        rendereEncoder.setRenderPipelineState(pipelineState)
        rendereEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        rendereEncoder.setVertexBytes(&renderUniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        rendereEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: testVertices.count)
        rendereEncoder.popDebugGroup()
        
    }
    
}
