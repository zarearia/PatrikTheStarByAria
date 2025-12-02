//
//  Submesh.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 03/09/2025.
//

import MetalKit

class Submesh {
    var mtkSubmesh: MTKSubmesh
    //Texture logic can be abstracted away later if needed
    var baseColorTexture: MTLTexture?
    var baseColorSolidColor: float3?
    
    var pipelineState: MTLRenderPipelineState!
    var hasSkeleton: Bool

    init(mtkSubmesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, hasSkeleton: Bool) {
        self.mtkSubmesh = mtkSubmesh
        self.hasSkeleton = hasSkeleton
        if let material = mdlSubmesh.material {
            loadTextures(material: material)
        }
        
        makePipelineState()
    }
    
    private func loadTextures(material: MDLMaterial) {
        
        //MARK: Loading BaseColor
        /// using usdz, ModelIO will handle the texture for us!
        guard let property = material.property(with: MDLMaterialSemantic.baseColor) else {
            print("submesh did not have any baseColors")
            return
        }
        
//        if property.type == .float  {
            baseColorSolidColor = property.float3Value
//        }

        // maybe move this down, we don't want a whole loading stuff to ram if we are just dealing with float
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: true
        ]
        
        if let sampler = property.textureSamplerValue,
           let mdlTexture = sampler.texture {

            baseColorTexture = try? textureLoader.newTexture(texture: mdlTexture, options: textureLoaderOptions)
            
            return
        }
        
        
        if let fileName = property.stringValue,
           property.type == .string {
            baseColorTexture = try? textureLoader.newTexture(name: fileName,
                                            scaleFactor: 1.0,
                                            bundle: Bundle.main, options: nil)
            
            return
        }
        
    }
    
    
    func makePipelineState() {
        let vertexFunction: MTLFunction?
        let functionConstant = MTLFunctionConstantValues()
        
        //functionConstants
        var hasSkeleton = hasSkeleton
        functionConstant.setConstantValue(&hasSkeleton, type: .bool, index: 0)
        var hasBaseColorTexture = baseColorTexture != nil
        functionConstant.setConstantValue(&hasBaseColorTexture, type: .bool, index: 1)
        var hasBaseColorSolidColor = baseColorSolidColor != nil
        functionConstant.setConstantValue(&hasBaseColorSolidColor, type: .bool, index: 2)
        
        
        vertexFunction = try! Renderer.library.makeFunction(name: "vertex_main", constantValues: functionConstant)
        let fragmentFunction = try! Renderer.library.makeFunction(name: "fragment_main", constantValues: functionConstant)
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        
        guard let attachment = descriptor.colorAttachments[0] else { return }
        attachment.isBlendingEnabled = true
        attachment.rgbBlendOperation = .add
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MDLVertexDescriptor.getDefaultVertexDescriptor())
        
        descriptor.sampleCount = 4
        
        do {
            try pipelineState = Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
}

