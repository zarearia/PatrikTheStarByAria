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
    float2 uv [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
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
        .worldNormal = normalMatrix * vertexIn.normal,
        .uv = vertexIn.uv
    };
    return vertexOut;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(2)]],
                              constant Light *lights [[buffer(3)]],
                              texture2d<float> baseColorTexture2d [[texture(0)]]) {
    
    
    constexpr sampler textureSampler;

    float3 baseColor = baseColorTexture2d.sample(textureSampler, in.uv).rgb;
    return float4(baseColor, 1);
    
    float3 diffuseColor = 0;
    float3 ambientColor = 0;
    float3 specularColor = 0;
    float materialShininess = 32;
    float3 materialSpecularColor = float3(1, 1, 1);
    
    float3 normalDirection = normalize(in.worldNormal);
    
    for (uint32_t i = 0; i < uniforms.lightCount; i++) {
        
        Light light = lights[i];
        
        if (light.type == SunLight) {
            float3 lightDirection = normalize(light.position);
            float3 lightColor = light.color;
            
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            
            diffuseColor += lightColor * baseColor * diffuseIntensity;
            
            if (diffuseIntensity > 0) {
                float3 reflection = reflect(lightDirection, in.worldNormal);
                //this is camera direction toward the fragment
                float3 cameraDirection = normalize(in.worldPosition - uniforms.cameraPosition);
                float specularIntensity = pow(saturate(dot(reflection, cameraDirection)), materialShininess);
                specularColor += specularIntensity * materialSpecularColor * light.specularColor;
            }
        } else if (light.type == Ambientlight) {
            ambientColor += light.color * light.intensity;
        } else if (light.type == PointLight) {
            float d = distance(light.position, in.worldPosition);
            float3 lightDirection = normalize(light.position - in.worldPosition);
            
            float attenuation = 1.0 / ( light.attenuation.x + light.attenuation.y * d + light.attenuation.z * pow(light.attenuation.z, 2) );
            
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            
            float3 color = diffuseIntensity * light.color * baseColor;
            
            color *= attenuation;
            diffuseColor += color;
        } else if (light.type == SpotLight) {
            float d = distance(light.position, in.worldPosition);
            float3 lightDirection = normalize(light.position - in.worldPosition);
            
            float3 coneDirection = normalize(light.coneDirection);
            float spotResult = dot(lightDirection, coneDirection);
            
            if (spotResult > cos(light.coneAngel)) {
                float attenuation = 1.0 / ( light.attenuation.x + light.attenuation.y * d + light.attenuation.z * pow(light.attenuation.z, 2) );
                
                attenuation *= pow(spotResult, light.coneAttenuation);
                
                float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
                
                float3 color = diffuseIntensity * light.color * baseColor;
                
                color *= attenuation;
                diffuseColor += color;
            }
        }
    }
    
    
    float3 finalColor = diffuseColor + ambientColor + specularColor;
    return float4(finalColor, 1);
}
