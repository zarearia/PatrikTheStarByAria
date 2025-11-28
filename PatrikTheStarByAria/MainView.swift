//
//  MainView.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 27/11/2025.
//

import MetalKit

class MainView: MTKView {
    
    var controleDelegate: ControleDelegate?
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // using f1 as safety net
        if event.isARepeat { return }
        controleDelegate?.keyDown(keyCode: KeyCode(rawValue: event.keyCode) ?? .f1)
    }

    override func keyUp(with event: NSEvent) {
        if event.isARepeat { return }
        controleDelegate?.keyUp(keyCode: KeyCode(rawValue: event.keyCode) ?? .f1)
    }
    
}
