//
//  VertexDescriptorHelper.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

import Metal
import ModelIO

extension MTLVertexDescriptor {
    static func getDefaultVertexDescriptor() -> MTLVertexDescriptor {
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        
        return vertexDescriptor
    }
}

extension MDLVertexDescriptor {
    static func getDefaultVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        
        var offset = 0
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: offset, bufferIndex: 0)
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
}
