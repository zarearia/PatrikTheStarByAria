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
    float3 worldPosition;
    float3 worldNormal;
};

float3x3 extract_top_3x3(float4x4 m)
{
    return float3x3(
        m.columns[0].xyz,
        m.columns[1].xyz,
        m.columns[2].xyz
    );
}

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    
    matrix_float3x3 normalMatrix = extract_top_3x3(uniforms.modelMatrix);
    
    VertexOut vertexOut = VertexOut {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertexIn.position,
        .worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz,
        .worldNormal = normalMatrix * vertexIn.normal
    };
    return vertexOut;
}

fragment float4 fragment_main(VertexOut vertexIn [[stage_in]]) {
    float3 lightDirection = normalize(float3(1, 2, -2));
    float3 lightColor = float3(1, 1, 1);
    float3 baseColor = float3(0, 1, 0);
    float3 normalDirection = normalize(vertexIn.worldNormal);
    
    float intensity = saturate(dot(lightDirection, normalDirection));
    
    baseColor = lightColor * baseColor * intensity;
    
    
    return float4(baseColor, 1);
}
