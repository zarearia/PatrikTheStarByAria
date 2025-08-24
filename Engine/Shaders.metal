//
//  Shaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[stage_in]]) {
    return float4(vertexIn.position);
}

fragment float4 fragment_main() {
    return float4(0, 1, 0, 1);
}
