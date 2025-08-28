//
//  Shaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

#include <metal_stdlib>
#include "Common.h"
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut vertexOut = VertexOut {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertexIn.position,
        .normal = vertexIn.normal
    };
    return vertexOut;
}

fragment float4 fragment_main(VertexOut vertexIn [[stage_in]]) {
    float4 color;
    float3 normal = vertexIn.normal;
    float4 skyColor = float4(0, 0.5, 1, 1);
    float4 groundColor = float4(0, 1, 0, 1);
    float colorIntensity = saturate((normal.y + 1) / 2);
    color = mix(groundColor, skyColor, colorIntensity);
    return color;
}
