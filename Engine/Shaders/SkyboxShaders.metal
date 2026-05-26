//
//  SkyboxShaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 26/05/2026.
//

#include <metal_stdlib>
#include "Common.h"
using namespace metal;

struct VertexIn {
    float4 position [[attribute(Position)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut verte_skybox(const VertexIn vertexIn [[stage_in]],
                               constant Uniforms &uniforms [[buffer(UniformsBufferIndex)]]) {
    VertexOut vertexOut;
    vertexOut.position = uniforms.projectionMatrix * uniforms.viewMatrix * vertexIn.position;
    vertexOut.position = vertexOut.position.xyww;
    return vertexOut;
}

fragment float4 fragment_skybox(VertexOut vertexIn [[stage_in]]) {
    return float4(1, 1, 0, 1);
}
