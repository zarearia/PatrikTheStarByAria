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
    var depthStencilState: MTLDepthStencilState?
    var model: Model
    
    //TODO: I have to make a class called node for these later
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    let modelMatrix: matrix_float4x4 = .identity()//matrix_float4x4.init(rotation: [0, 0, Float(45).degreesToRadians])
    
    var camera = ArcballCamera()
    
    var lights: [Light] = []
    

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
        
        var sunLight = Light()
        sunLight.color = float3(1, 1, 1)
        sunLight.position = float3(1, 2, -2)
        sunLight.intensity = 1
        sunLight.type = SunLight
        lights.append(sunLight)
        
        makePipelineState()
        makeDepthStencileState()
        
        metalView.depthStencilPixelFormat = .depth32Float
        
        uniforms.modelMatrix = modelMatrix
        
        let aspect: Float = Float(metalView.frame.width / metalView.frame.height)
        camera.aspect = aspect
        camera.zoom(delta: -30)
        uniforms.projectionMatrix = camera.projectionMatrix
        
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
    
    func makeDepthStencileState() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
}


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect: Float = Float(view.frame.width / view.frame.height)
        camera.aspect = aspect
        uniforms.projectionMatrix = camera.projectionMatrix
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipelineState = self.pipelineState else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        uniforms.viewMatrix = camera.viewMatrix
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        fragmentUniforms.lightCount = UInt32(lights.count)
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 2)
        
        renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<Light>.stride * lights.count, index: 3)
        
        for mesh in model.meshes {
            let submeshs = mesh.submeshes
            
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
