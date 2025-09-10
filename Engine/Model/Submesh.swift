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
    
    init(mtkSubmesh: MTKSubmesh, mdlSubmesh: MDLSubmesh) {
        self.mtkSubmesh = mtkSubmesh
        if let material = mdlSubmesh.material {
            loadTextures(material: material)
        }
    }
    
    private func loadTextures(material: MDLMaterial) {
        
        //MARK: Loading BaseColor
        /// using usdz, ModelIO will handle the texture for us!
        guard let property = material.property(with: MDLMaterialSemantic.baseColor) else {
            print("submesh did not have any baseColors")
            return
        }

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
        }
    }
}
