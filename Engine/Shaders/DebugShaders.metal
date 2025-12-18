//
//  DebugShaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 16/12/2025.
//

#include <metal_stdlib>
#include "Common.h"
using namespace metal;

struct DebugVertexIn {
    float3 position [[attribute(0)]];
};

vertex float4 vertex_debug(DebugVertexIn vertexIn [[stage_in]],
                           constant Uniforms &uniform [[buffer(1)]]) {
    return uniform.projectionMatrix * uniform.viewMatrix * uniform.modelMatrix * float4(vertexIn.position, 1);
}

fragment float4 fragment_debug(float4 in [[stage_in]]) {
    return float4(1, 0, 0, 1);
}
