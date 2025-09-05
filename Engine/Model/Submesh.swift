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
        if let property = material.property(with: MDLMaterialSemantic.baseColor),
           let sampler = property.textureSamplerValue,
           let mdlTexture = sampler.texture {
            
            let textureLoader = MTKTextureLoader(device: Renderer.device)
            baseColorTexture = try! textureLoader.newTexture(texture: mdlTexture, options: [.origin: MTKTextureLoader.Origin.bottomLeft])
            
            return
        }
    }
}
