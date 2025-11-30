//
//  File.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 30/11/2025.
//

import Foundation

protocol Controllable {
    var isMoving: Bool { get set }
    var controlled: Node? { get set }
    
    var direction: float3 { get }
    var rotation: float3 { get }
    
    var directionSpeed: Float { get set }
    var rotationSpeed: Float { get set }
    
    func updateControled(deltaTime: Float)
    
    func keyUp(keyCode: KeyCode)
    func keyDown(keyCode: KeyCode)
}
