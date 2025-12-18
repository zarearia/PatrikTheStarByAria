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
    let vertexBuffer: MTLBuffer?
    var boundingBox: MDLAxisAlignedBoundingBox
    var vertices: [float3]
    var vertexIndices: [UInt16]
    let indexBuffer: MTLBuffer?
    
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
       
        vertices = [
            [boundingBox.minBounds.x, boundingBox.minBounds.y, boundingBox.minBounds.z], // 0: min corner
            [boundingBox.maxBounds.x, boundingBox.minBounds.y, boundingBox.minBounds.z], // 1: +X
            [boundingBox.minBounds.x, boundingBox.maxBounds.y, boundingBox.minBounds.z], // 2: +Y
            [boundingBox.maxBounds.x, boundingBox.maxBounds.y, boundingBox.minBounds.z], // 3: +X+Y
            [boundingBox.minBounds.x, boundingBox.minBounds.y, boundingBox.maxBounds.z], // 4: +Z
            [boundingBox.maxBounds.x, boundingBox.minBounds.y, boundingBox.maxBounds.z], // 5: +X+Z
            [boundingBox.minBounds.x, boundingBox.maxBounds.y, boundingBox.maxBounds.z], // 6: +Y+Z
            [boundingBox.maxBounds.x, boundingBox.maxBounds.y, boundingBox.maxBounds.z]  // 7: max corner
        ]
        
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count)
        
        vertexIndices = [
            0, 1,
            0, 2,
            2, 3,
            1, 3,
            
            0, 4,
            1, 5,
            2, 6,
            3, 7,
            
            4, 5,
            4, 6,
            5, 7,
            6, 7
        ]
        
        indexBuffer = Renderer.device.makeBuffer(bytes: &vertexIndices, length: MemoryLayout<UInt16>.stride * vertexIndices.count)
    }
    
    func debugBoundingBox(rendereEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms) {
         
        guard let indexBuffer,
              let vertexBuffer else {
            return
        }
        
        rendereEncoder.pushDebugGroup("boundingbox")
        var renderUniforms = uniforms
        rendereEncoder.setRenderPipelineState(pipelineState)
        rendereEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        rendereEncoder.setVertexBytes(&renderUniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        rendereEncoder.drawIndexedPrimitives(type: .line, indexCount: vertexIndices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        rendereEncoder.popDebugGroup()
        
    }
    
}
