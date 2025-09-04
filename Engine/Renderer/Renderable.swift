//
//  Renderable.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 03/09/2025.
//

import Metal

protocol Renderable {
  func render(renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms, fragmentUniforms fragment: FragmentUniforms)
}
