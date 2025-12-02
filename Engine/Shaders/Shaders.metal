//
//  Shaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

#include <metal_stdlib>
#include "Common.h"
using namespace metal;

constant bool hasSkeleton [[function_constant(0)]];
constant bool hasBaseColorTexture [[function_constant(1)]];
constant bool hasBaseColorSolidColor [[function_constant(2)]];

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
    float3 color [[attribute(Color)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
    float3 color;
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
                             constant float4x4 *jointMatrices [[buffer(22)]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    
    float4 position = vertexIn.position;
    float4 normal = float4(vertexIn.normal, 0);
    
    
    float4 weights = vertexIn.weights;
    ushort4 joints = vertexIn.joints;
    if (hasSkeleton) {
        position = weights.x * (jointMatrices[joints.x] * position) +
            weights.y * (jointMatrices[joints.y] * position) +
            weights.z * (jointMatrices[joints.z] * position) +
            weights.w * (jointMatrices[joints.w] * position);
        normal =
            weights.x * (jointMatrices[joints.x] * normal) +
            weights.y * (jointMatrices[joints.y] * normal) +
            weights.z * (jointMatrices[joints.z] * normal) +
            weights.w * (jointMatrices[joints.w] * normal);
    }
    
    
    matrix_float3x3 normalMatrix = extract_top_3x3(uniforms.modelMatrix);
    
    VertexOut vertexOut = VertexOut {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position,
        .worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz,
        .worldNormal = normalMatrix * normal.xyz,
        .uv = vertexIn.uv,
        .color = vertexIn.color
    };
    return vertexOut;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(2)]],
                              constant Light *lights [[buffer(3)]],
                              texture2d<float> baseColorTexture2d [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float3 &solidColor [[buffer(SolidColorBufferIndex)]]) {
    
    float4 baseColor;
    if (hasBaseColorTexture) {
        baseColor = baseColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgba;
        if (baseColor.a <= 0.1) {
            discard_fragment();
        }
    } else if (hasBaseColorSolidColor) {
        baseColor = float4(solidColor, 1);
    }
    
    return baseColor;
    
    //This is important code, don't remove it
//    float3 diffuseColor = 0;
//    float3 ambientColor = 0;
//    float3 specularColor = 0;
//    float materialShininess = 32;
//    float3 materialSpecularColor = float3(1, 1, 1);
//    
//    float3 normalDirection = normalize(in.worldNormal);
//    
//    for (uint32_t i = 0; i < uniforms.lightCount; i++) {
//        
//        Light light = lights[i];
//        
//        if (light.type == SunLight) {
//            float3 lightDirection = normalize(light.position);
//            float3 lightColor = light.color;
//            
//            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
//            
//            diffuseColor += lightColor * baseColor * diffuseIntensity;
//            
//            if (diffuseIntensity > 0) {
//                float3 reflection = reflect(lightDirection, in.worldNormal);
//                //this is camera direction toward the fragment
//                float3 cameraDirection = normalize(in.worldPosition - uniforms.cameraPosition);
//                float specularIntensity = pow(saturate(dot(reflection, cameraDirection)), materialShininess);
//                specularColor += specularIntensity * materialSpecularColor * light.specularColor;
//            }
//        } else if (light.type == Ambientlight) {
//            ambientColor += light.color * light.intensity;
//        } else if (light.type == PointLight) {
//            float d = distance(light.position, in.worldPosition);
//            float3 lightDirection = normalize(light.position - in.worldPosition);
//            
//            float attenuation = 1.0 / ( light.attenuation.x + light.attenuation.y * d + light.attenuation.z * pow(light.attenuation.z, 2) );
//            
//            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
//            
//            float3 color = diffuseIntensity * light.color * baseColor;
//            
//            color *= attenuation;
//            diffuseColor += color;
//        } else if (light.type == SpotLight) {
//            float d = distance(light.position, in.worldPosition);
//            float3 lightDirection = normalize(light.position - in.worldPosition);
//            
//            float3 coneDirection = normalize(light.coneDirection);
//            float spotResult = dot(lightDirection, coneDirection);
//            
//            if (spotResult > cos(light.coneAngel)) {
//                float attenuation = 1.0 / ( light.attenuation.x + light.attenuation.y * d + light.attenuation.z * pow(light.attenuation.z, 2) );
//                
//                attenuation *= pow(spotResult, light.coneAttenuation);
//                
//                float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
//                
//                float3 color = diffuseIntensity * light.color * baseColor;
//                
//                color *= attenuation;
//                diffuseColor += color;
//            }
//        }
//    }
//    
//    
//    float3 finalColor = diffuseColor + ambientColor + specularColor;
//    return float4(finalColor, 1);
}
