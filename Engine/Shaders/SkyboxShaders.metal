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
    float3 textureCoordinates;
};

vertex VertexOut verte_skybox(const VertexIn vertexIn [[stage_in]],
                               constant Uniforms &uniforms [[buffer(UniformsBufferIndex)]]) {
    VertexOut vertexOut;
    float4x4 viewMatrix = uniforms.viewMatrix;
    viewMatrix.columns[3] = float4(0, 0, 0, 1);
    vertexOut.position = uniforms.projectionMatrix * viewMatrix * vertexIn.position;
    vertexOut.position = vertexOut.position.xyww;
    vertexOut.textureCoordinates = vertexIn.position.xyz;
    return vertexOut;
}

fragment half4 fragment_skybox(VertexOut vertexIn [[stage_in]],
                                texturecube<half> skyTexture [[texture(0)]]) {
    constexpr sampler defaultSampler(filter::linear);
    half4 color = skyTexture.sample(defaultSampler, vertexIn.textureCoordinates);
    return color;
}
