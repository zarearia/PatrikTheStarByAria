//
//  VertexDescriptorHelper.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

import Metal
import ModelIO


extension MDLVertexDescriptor {
    static func getDefaultVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        
        var offset = 0
        vertexDescriptor.attributes[Int(Position.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.attributes[Int(Normal.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.attributes[Int(UV.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<float2>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
}
