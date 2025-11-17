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
    
    var depthStencilState: MTLDepthStencilState?
    var models: [Renderable] = []
    
    //TODO: I have to make a class called node for these later
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    let modelMatrix: matrix_float4x4 = .identity()//matrix_float4x4.init(rotation: [0, 0, Float(45).degreesToRadians])
    
    var camera = ArcballCamera()
    
    var lights: [Light] = []
    
    var texture: MTLTexture
    
    var time: Float = 0
//    let skeleton: Model!
//    var animationWithKeyFrames = generateTranslations()
    func update() {
//        animationWithKeyFrames.repeatAnimation = true
//        skeleton.position = animationWithKeyFrames.getTranslation(at: time) ?? float3(0, 0, 0)
//        skeleton.position.x += 1/60
        
//        skeleton.quaternion = skeleton.animations["/skeletonWave/Animations/wave"]?.jointsAnimationAtKeyFrame["/body/upperarm_L/forearm_L"]?.getTransformation(at: time).rotationQuatf ?? simd_quatf()
    }

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
        

//        skeleton = Model(name: "skeletonWave", resourse: "skeletonWave", extention: "usda")

        super.init()
        
        metalView.delegate = self
        metalView.clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
        
        models.append(Model(name: "patrik", resourse: "patrik", extention: "usda"))
//        models.append(Model(name: "patrik2", resourse: "patrik2", extention: "usdz"))
//        models.append(Model(name: "patrik3", resourse: "patrik3", extention: "usdz"))
        
//        skeleton.scale = [100, 100, 100]
//        skeleton.rotation = [-.pi/2, 0, 0]
//        models.append(skeleton)
        
        
        var groundModel = Model(name: "ground", resourse: "ground", extention: "obj")
        groundModel.tiling = 4
        models.append(groundModel)

        //MARK: Lights
        /**************/
        var sunLight = Light()
        sunLight.color = float3(1, 1, 1)
        sunLight.position = float3(1, 2, -2)
        sunLight.intensity = 1
        sunLight.type = SunLight
        sunLight.specularColor = float3(1, 1, 1)
        lights.append(sunLight)
        
        //position is not useful for ambientLight
//        let ambientLight = Light(type: Ambientlight,
//                                 position: [0, 0, 0],
//                                 color: [1, 0, 0],
//                                 specularColor: [0, 0, 0],
//                                 attenuation: [1, 0, 0],
//                                 intensity: 0.2)
//        lights.append(ambientLight)
        
//        var pointLight = Light()
//        pointLight.color = float3(1, 1, 0)
//        pointLight.position = float3(1, 2, 1)
//        pointLight.intensity = 1
//        pointLight.attenuation = [1, 1, 1]
//        pointLight.type = PointLight
//        pointLight.specularColor = float3(1, 1, 1)
//        lights.append(pointLight)
        
//        var spotLight = Light()
//        spotLight.color = float3(1, 1, 0)
//        spotLight.position = float3(1, 2, 1)
//        spotLight.intensity = 1
//        spotLight.attenuation = [1, 1, 1]
//        spotLight.type = SpotLight
//        spotLight.specularColor = float3(1, 1, 1)
//        
//        spotLight.coneAttenuation = 0.1
//        spotLight.coneAngel = 30
//        spotLight.coneDirection = [1, 1, -1]
//        lights.append(spotLight)
        /***************/
        
        
        makeDepthStencileState()
        
        metalView.depthStencilPixelFormat = .depth32Float
        
        uniforms.modelMatrix = modelMatrix
        
        let aspect: Float = Float(metalView.frame.width / metalView.frame.height)
        camera.aspect = aspect
        camera.zoom(delta: -30)
        camera.rotate(delta: [180, -5])
        camera.target = [0, 1, 0]
        uniforms.projectionMatrix = camera.projectionMatrix
        
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
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
//        let deltaTime = Float(1 / view.preferredFramesPerSecond)
        time += 1 / Float(view.preferredFramesPerSecond)
        update()
        
        uniforms.viewMatrix = camera.viewMatrix
//        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: Int(UniformsBufferIndex.rawValue))
        
        fragmentUniforms.lightCount = UInt32(lights.count)
        fragmentUniforms.cameraPosition = camera.position
        
        renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<Light>.stride * lights.count, index: Int(LightsBufferIndex.rawValue))
        
        for model in self.models {
            renderEncoder.pushDebugGroup(model.name)
            model.render(renderEncoder: renderEncoder, uniforms: uniforms, fragmentUniforms: fragmentUniforms)
            renderEncoder.popDebugGroup()
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
