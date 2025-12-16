//
//  PhysicsController.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 15/12/2025.
//

class PhysicsController {
    var dynamicObject: Model
    var staticObjects: [Model]
    
    init(dynamicObject: Model, staticObjects: [Model]) {
        self.dynamicObject = dynamicObject
        self.staticObjects = staticObjects
    }
    
//    func isColliding() -> Bool {
//        for object in staticObjects {
//            if object.asset.boundingBox.maxBounds
//        }
//    }
    
    func test() {
        print(dynamicObject.asset.boundingBox)
    }
}
