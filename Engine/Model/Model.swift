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
    var meshes: [Mesh] = []
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
        
        _ = mdlMeshes.map {
            do {
                let mesh: Mesh = try Mesh(mtkMesh: MTKMesh(mesh: $0, device: Renderer.device), mdlMesh: $0)
                meshes.append(mesh)
            } catch(let error) {
                print("failed to load Mesh: \(error)")
            }
            
        }
    }
}

extension Model: Renderable {
    func render(renderEncoder: any MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms) {
        for mesh in self.meshes {
            let mtkMesh = mesh.mtkMesh
            let submeshs = mesh.submeshes
            
            renderEncoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer, offset: mtkMesh.vertexBuffers[0].offset, index: 0)
            
            for submeshe in submeshs {
                
                //TODO: Add texture submeshes here
                
                let mtkSubmesh = submeshe.mtkSubmesh
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: mtkSubmesh.indexCount,
                    indexType: mtkSubmesh.indexType,
                    indexBuffer:
                        mtkSubmesh.indexBuffer.buffer,
                    indexBufferOffset: 0
                )
            }
        }
    }
}
