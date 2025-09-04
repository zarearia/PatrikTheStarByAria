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
            getTextureProperty(material: material, semantic: MDLMaterialSemantic.baseColor)
        }
    }
    
    func getTextureProperty(material: MDLMaterial, semantic: MDLMaterialSemantic) {
        
        guard let property = material.property(with: semantic) else {
            return
        }
        
        for property in material.properties(with: semantic) {
            print("name: \(property.name), semantic: \(property.semantic.rawValue), type: \(property.type.rawValue)")
            print("   string: \(property.stringValue ?? "nil")")
            if let sampler = property.textureSamplerValue {
                print("   sampler: \(sampler)")
//                print("   texture url: \(sampler.texture?.url?.path ?? "nil")")
                print("   texture name: \(sampler.texture?.name ?? "nil")")
            }
        }
        
//        switch property.type {
//        case .texture:
//            print("Texturesssssss")
////            if let textureSampler = property.textureSamplerValue {
////                if let url = textureSampler.texture?.url {
////                    print("Texture URL: \(url)")
////                } else {
////                    print("Texture found, but no URL")
////                }
////            }
//        case .string:
//            if let fileName = property.stringValue {
//                print("Texture path: \(fileName)")
//            } else {
//                print("String property is nil")
//            }
//        default:
//            print("Unhandled property type: \(property.type)")
//        }
//        
//
//        
//        print(property)
//        print(property.name)
              
    }
}
