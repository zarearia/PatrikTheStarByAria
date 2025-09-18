//
//  Meshe.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 03/09/2025.
//

import MetalKit

class Mesh {
    var submeshes: [Submesh] = []
    var mtkMesh: MTKMesh
    let skeleton: Skeleton?
    
    init(mtkMesh: MTKMesh, mdlMesh: MDLMesh) {
        self.mtkMesh = mtkMesh
        self.skeleton = Skeleton(animationBindComponent: (mdlMesh.componentConforming(to: MDLComponent.self) as? MDLAnimationBindComponent))
        if let mdlSubmeshes: [MDLSubmesh] = mdlMesh.submeshes as? [MDLSubmesh] {
            
            self.submeshes = zip(mtkMesh.submeshes, mdlSubmeshes).map { mesh in
                Submesh(mtkSubmesh: mesh.0, mdlSubmesh: mesh.1 as MDLSubmesh)
            }
            
        }
//        self.submeshes = Submesh(mtkSubmesh: mtkSubmesh.submeshes, mdlMesh: mdlMesh.submeshes!)
    }
}
