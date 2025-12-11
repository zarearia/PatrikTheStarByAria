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
    
    var normalSolidColor: float3?
    var normalTexture: MTLTexture?
    
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
        if let property = material.property(with: MDLMaterialSemantic.baseColor) {
            baseColorTexture = loadTexture(property: property)
            if baseColorTexture == nil {
                baseColorSolidColor = property.float3Value
            }
        } else {
            print("[Submesh] submesh did not have any baseColor")
        }
        
        if let property = material.property(with: MDLMaterialSemantic.tangentSpaceNormal) {
            normalTexture = loadTexture(property: property)
            if normalTexture == nil {
                normalSolidColor = property.float3Value
            }
        } else {
            print("[Submesh] submesh did not have any normalColor")
        }
        
    }
    
    private func loadTexture(property: MDLMaterialProperty) -> (any MTLTexture)? {
         //MARK: Loading BaseColor
        
        // maybe move this down, we don't want a whole loading stuff to ram if we are just dealing with float
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: true
        ]
        
        if let sampler = property.textureSamplerValue,
           let mdlTexture = sampler.texture {

            let texture = try? textureLoader.newTexture(texture: mdlTexture, options: textureLoaderOptions)
            
            return texture
        }
        
        
        if let fileName = property.stringValue,
           property.type == .string {
            let texture = try? textureLoader.newTexture(name: fileName,
                                                        scaleFactor: 1.0,
                                                        bundle: Bundle.main, options: nil)
            
            return texture
        }
        
        print("[Submesh] No texture for this property.")
        return nil
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
        
        var hasFog = Renderer.hasFog
        functionConstant.setConstantValue(&hasFog, type: .bool, index: 3)
        
        var hasNormalTexture = normalTexture != nil
        functionConstant.setConstantValue(&hasNormalTexture, type: .bool, index: 4)
        var hasNormalSolidColor = normalSolidColor != nil
        functionConstant.setConstantValue(&hasNormalSolidColor, type: .bool, index: 5)

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
        
        
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.vertexDescriptor)
        
        descriptor.sampleCount = 4
        
        do {
            try pipelineState = Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
}

