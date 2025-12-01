//
//  ThirdPersonCamera.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 30/11/2025.
//

class ThirdPersonCamera: Camera {
    var focus: Node
    
    var focusDistance: Float = 3
    var focusHeight: Float = 1.2
    
    init(focus: Node) {
        self.focus = focus
        super.init()
    }
    
    //TODO: verify the math(I veridied it, consider doing more linear algebra)
    override var viewMatrix: float4x4 {
        position = focus.position - focusDistance
        * focus.forwardVector
        position.y = focusHeight
        rotation.y = focus.rotation.y
        return super.viewMatrix
    }
}
