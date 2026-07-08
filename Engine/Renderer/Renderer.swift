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
    static var hasFog = false
    static var rasterSampleCount = 4
    
    var scene: Scene?
    
    var depthStencilState: MTLDepthStencilState?
    
    var texture: MTLTexture
    
    var brdfLut: MTLTexture
    
    // all shadow pass code needs to be relocated elsewhere
    var shadowTexture: MTLTexture!
    var shadowRenderPassDescription: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
    var shadowPipelineState: MTLRenderPipelineState!

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
        
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        
        self.texture = try! textureLoader.newTexture(name: "starfish_cloth_santa_baseColor", scaleFactor: 1.0, bundle: Bundle.main, options: textureLoaderOptions)

        guard let brdfLut = Renderer.buildBRDF() else {
            fatalError("could not find brdfLut")
        }
        self.brdfLut = brdfLut

        super.init()
        
        makeShadowPipelineState()
        
        metalView.delegate = self
        metalView.clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
        
        makeDepthStencileState()
        
        metalView.depthStencilPixelFormat = .depth32Float
        
        metalView.sampleCount = Renderer.rasterSampleCount
        
        updateShadowTextureAndRenderPassDescriptor(width: Int(metalView.drawableSize.width), height: Int(metalView.drawableSize.height))
        
    }
    
    
    func makeDepthStencileState() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    static func makeTexture(pixelFormat: MTLPixelFormat,
                     width: Int,
                     height: Int,
                     label: String) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        guard let texture = Renderer.device.makeTexture(descriptor: descriptor) else {
            fatalError("could not make texture: \(label)")
        }
        texture.label = label
        return texture
    }
    
    func updateShadowTextureAndRenderPassDescriptor(width: Int, height: Int) {
        self.shadowTexture = Renderer.makeTexture(pixelFormat: .depth32Float, width: width, height: height, label: "shadow")
        shadowRenderPassDescription.setupDepthAttachment(texture: self.shadowTexture)
    }
    
//    static var defaultVertexDescriptor: MDLVertexDescriptor = {
//      let vertexDescriptor = MDLVertexDescriptor()
//      vertexDescriptor.attributes[0] =
//        MDLVertexAttribute(name: MDLVertexAttributePosition,
//                           format: .float3,
//                           offset: 0, bufferIndex: 0)
//      vertexDescriptor.attributes[1] =
//        MDLVertexAttribute(name: MDLVertexAttributeNormal,
//                           format: .float3,
//                           offset: 12, bufferIndex: 0)
//      vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 24)
//      return vertexDescriptor
//    }()
    
    func makeShadowPipelineState() {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = Renderer.library.makeFunction(name: "vertex_shadow")
        descriptor.fragmentFunction = nil
        descriptor.colorAttachments[0].pixelFormat = .invalid
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MDLVertexDescriptor.getDefaultVertexDescriptor())
        do {
            shadowPipelineState =
            try Renderer.device.makeRenderPipelineState(
                descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        descriptor.fragmentFunction = nil
    }
    
    func renderShadowPass(renderEncoder: MTLRenderCommandEncoder) {
        guard let scene = scene else {
            return
        }
        renderEncoder.pushDebugGroup("shadow pass")
        renderEncoder.label = "shadow encoder"
        renderEncoder.setDepthStencilState(depthStencilState)
        // .none cull mode should be the default one
//        renderEncoder.setCullMode(.none)
        renderEncoder.setDepthBias(0.01, slopeScale: 1.0, clamp: 0.01)
        scene.uniforms.projectionMatrix = float4x4(orthoLeft: -8, right: 8,
                                                    bottom: -8, top: 8,
                                                    near: 0.1, far: 16)
        
        // using first light for now
        guard let light = scene.lights.first else {
            return
        }
        let position: float3 = [light.position.x, light.position.y, light.position.z]
        let lookAt: float4x4 = float4x4(eye: position, center: [0, 0, 0], up: [0, 1, 0])
        scene.uniforms.viewMatrix = lookAt
        scene.uniforms.shadowMatrix = scene.uniforms.projectionMatrix * lookAt
        renderEncoder.setRenderPipelineState(shadowPipelineState)
        for renderable in scene.renderables {
            renderEncoder.pushDebugGroup(renderable.name + "_shadow")
            renderable.renderShadow(renderEncoder: renderEncoder, uniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            renderEncoder.popDebugGroup()
        }
        
        renderEncoder.endEncoding()
    }

}


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene?.sceneSizeWillChange(newSize: size)
        updateShadowTextureAndRenderPassDescriptor(width: Int(size.width), height: Int(size.height))
    }
    
    func draw(in view: MTKView) {
        
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else {
            return
        }
        
        if let shadowEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescription) {
            renderShadowPass(renderEncoder: shadowEncoder)
        }
        
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
            mainPass(renderEncoder: renderEncoder)
        } else {
            return
        }
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func mainPass(renderEncoder: MTLRenderCommandEncoder) {

        renderEncoder.setDepthStencilState(depthStencilState)
        
        let deltaTime = 1 / Float(60)
        
        guard let scene = scene else {
            fatalError("No scene")
        }
        
        scene.update(deltaTime: deltaTime)
        
        scene.skyBox.update(renderEncoder: renderEncoder)
        
        scene.fragmentUniforms.lightCount = UInt32(scene.lights.count)
        
        scene.uniforms.projectionMatrix = scene.camera.projectionMatrix
        
        renderEncoder.setFragmentBytes(&scene.lights, length: MemoryLayout<Light>.stride * scene.lights.count, index: Int(LightsBufferIndex.rawValue))
        renderEncoder.setFragmentTexture(brdfLut, index: Int(BrdfLutTextureIndex.rawValue))
        renderEncoder.setFragmentTexture(shadowTexture, index: Int(ShadowTexture.rawValue))
        
        for renderable in scene.renderables {
            renderEncoder.pushDebugGroup(renderable.name)
            renderable.render(renderEncoder: renderEncoder, uniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            renderEncoder.popDebugGroup()
        }
        
        scene.skyBox.render(renderEncoder: renderEncoder, uniforms: scene.uniforms)
        
        renderEncoder.endEncoding()
    }
}

extension MTLRenderPassDescriptor {
    func setupDepthAttachment(texture: MTLTexture) {
        self.depthAttachment.texture = texture
        self.depthAttachment.clearDepth = 1
        self.depthAttachment.loadAction = .clear
        self.depthAttachment.storeAction = .store
    }
}
