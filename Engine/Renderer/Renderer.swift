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
    
    var shadowTexture: MTLTexture!
    var shadowRenderPassDescription: MTLRenderPassDescriptor = MTLRenderPassDescriptor()

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
}


extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene?.sceneSizeWillChange(newSize: size)
        updateShadowTextureAndRenderPassDescriptor(width: Int(size.width), height: Int(size.height))
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
//        let samplePosition: [MTLSamplePosition] = [
//            MTLSamplePosition(x: 0.01, y: 0.01),
//            MTLSamplePosition(x: 0.99, y: 0.01),
//            MTLSamplePosition(x: 0.01, y: 0.99),
//            MTLSamplePosition(x: 0.99, y: 0.99)
//        ]
//        descriptor.setSamplePositions(samplePosition)
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        let deltaTime = 1 / Float(60)
        
        guard let scene = scene else {
            fatalError("No scene")
        }
        
        scene.update(deltaTime: deltaTime)
        
        scene.skyBox.update(renderEncoder: renderEncoder)
        
        scene.fragmentUniforms.lightCount = UInt32(scene.lights.count)
        
        renderEncoder.setFragmentBytes(&scene.lights, length: MemoryLayout<Light>.stride * scene.lights.count, index: Int(LightsBufferIndex.rawValue))
        renderEncoder.setFragmentTexture(brdfLut, index: Int(BrdfLutTextureIndex.rawValue))
        
        for renderable in scene.renderables {
            renderEncoder.pushDebugGroup(renderable.name)
            renderable.render(renderEncoder: renderEncoder, uniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            renderEncoder.popDebugGroup()
        }
        
        scene.skyBox.render(renderEncoder: renderEncoder, uniforms: scene.uniforms)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
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
