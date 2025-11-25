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
        
        vertexDescriptor.attributes[Int(Joints.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeJointIndices, format: .uShort4, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<simd_ushort4>.stride

        vertexDescriptor.attributes[Int(Weights.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeJointWeights, format: .float4, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<float4>.stride
        
        vertexDescriptor.attributes[Int(Color.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeColor, format: .float3, offset: offset, bufferIndex: Int(VerticesBufferIndex.rawValue))
        offset += MemoryLayout<float3>.stride

        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
}
