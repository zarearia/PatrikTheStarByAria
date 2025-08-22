//
//  Renderer.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 19/08/2025.
//

import MetalKit

class Renderer: NSObject {
    // these are forcebly unwrapped solely for simplicity, will be refactored in the future
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    static var colorPixelFormat: MTLPixelFormat!
    
    var pipelineState: MTLRenderPipelineState?
    let vertices: [float3] = [float3(0.5, 0.5, 0.0),
                              float3(-0.5, -0.5, 0.0),
                              float3(-0.5, 0.5, 0.0),
                              float3(0.5, -0.5, 0.0),]
    
    let verticeIndices: [UInt16] = [0, 1, 2, 1, 3, 0]
    
    var verticesBuffer: MTLBuffer
    var indicesBuffer: MTLBuffer
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not found")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        guard let verticesBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<float3>.stride * vertices.count, options: []),
              let indicesBuffer = device.makeBuffer(bytes: verticeIndices, length: MemoryLayout<UInt16>.stride * verticeIndices.count, options: []) else {
            fatalError("buffer problem")
        }
        
        self.verticesBuffer = verticesBuffer
        self.indicesBuffer = indicesBuffer

        super.init()
        
        metalView.delegate = self
        metalView.clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
        
        
        makePipelineState()
    }
    
    func makePipelineState() {
        let vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        
//        let vertexDescriptor = MTLVertexDescriptor()
//        vertexDescriptor.attributes[0].format = .float3
//        vertexDescriptor.attributes[0].offset = 0
//        vertexDescriptor.attributes[0].bufferIndex = 0
//        
//        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
//        
//        descriptor.vertexDescriptor = vertexDescriptor
        
        do {
            try pipelineState = Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
}


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipelineState = self.pipelineState else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: verticeIndices.count, indexType: .uint16, indexBuffer: indicesBuffer, indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
    }
    
    
}
