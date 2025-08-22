//
//  Shaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_main(const device float3 *vertexIn [[buffer(0)]],
                          unsigned int vertexId [[vertex_id]]) {
    return float4(vertexIn[vertexId], 1);
}

fragment float4 fragment_main() {
    return float4(0, 1, 0, 1);
}
