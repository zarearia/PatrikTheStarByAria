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
    var model: Model
    
    //TODO: I have to make a class called node for these later
    var uniforms = Uniforms()
    let modelMatrix: matrix_float4x4 = matrix_float4x4.init(rotation: [0, 0, Float(45).degreesToRadians])
    let viewMatrix: matrix_float4x4 = matrix_float4x4.init(translation: [0.5, 0, -5])
    
//    func rotateCamera(delta: float2) {
//        
//    }
//    
//    var cameraDistance: Float = 0
//    func zoomCamera(delta: Float) {
//        let sensitivity: Float = 0.005
//        cameraDistance = sensitivity * delta
//        viewMatrix = 
//        
//    }
    

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
        
        
        model = Model(resourse: "patrik", extention: "usda")

        super.init()
        
        metalView.delegate = self
        metalView.clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
        
        
        makePipelineState()
        
        uniforms.modelMatrix = modelMatrix
        

        uniforms.viewMatrix = viewMatrix.inverse
        
        
        let aspect: Float = Float(metalView.frame.width / metalView.frame.height)
        uniforms.projectionMatrix = matrix_float4x4.init(projectionFov: 70, near: 0.01, far: 1000, aspect: aspect)
        
    }
    
    func makePipelineState() {
        let vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
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


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect: Float = Float(view.frame.width / view.frame.height)
        uniforms.projectionMatrix = matrix_float4x4.init(projectionFov: 70, near: 0.01, far: 1000, aspect: aspect)
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipelineState = self.pipelineState else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        for mesh in model.meshes {
            let submeshs = mesh.submeshes
            
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            
            for submesh in submeshs {
                
                renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: mesh.vertexBuffers[0].offset, index: 0)
                
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer:
                        submesh.indexBuffer.buffer,
                    indexBufferOffset: 0
                )
            }
        }
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
    }
    
    
}
