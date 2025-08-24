//
//  Model.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 24/08/2025.
//

import MetalKit
import ModelIO
import os

class Model {
    let asset: MDLAsset
    var meshes: [MTKMesh] = []
    let logger = Logger()
    
    init(resourse: String, extention: String) {
        guard let assetURL = Bundle.main.url(forResource: resourse, withExtension: extention) else
        {
            fatalError()
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        self.asset = MDLAsset(url: assetURL, vertexDescriptor: MDLVertexDescriptor.getDefaultVertexDescriptor(), bufferAllocator: allocator)
        
        guard let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            return
        }
        
        for mesh in mdlMeshes {
            meshes.append(try! MTKMesh(mesh: mesh, device: Renderer.device))
            print(mesh)
        }
    }
}
