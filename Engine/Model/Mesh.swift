//
//  Meshe.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 03/09/2025.
//

import MetalKit

class Mesh: NSObject {
    var submeshes: [Submesh] = []
    var mtkMesh: MTKMesh
    let skeleton: Skeleton?
    //TODO: Fix the forced unwrapping later
    
    init(mtkMesh: MTKMesh, mdlMesh: MDLMesh) {
        self.mtkMesh = mtkMesh
        self.skeleton = Skeleton(animationBindComponent: (mdlMesh.componentConforming(to: MDLComponent.self) as? MDLAnimationBindComponent))

        super.init()
        
        if let mdlSubmeshes: [MDLSubmesh] = mdlMesh.submeshes as? [MDLSubmesh] {
            
            self.submeshes = zip(mtkMesh.submeshes, mdlSubmeshes).map { mesh in
                Submesh(mtkSubmesh: mesh.0, mdlSubmesh: mesh.1 as MDLSubmesh, hasSkeleton: skeleton != nil)
            }
            
        }
//        self.submeshes = Submesh(mtkSubmesh: mtkSubmesh.submeshes, mdlMesh: mdlMesh.submeshes!)
    }
    
}
