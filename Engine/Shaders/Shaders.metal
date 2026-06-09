//
//  Shaders.metal
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 21/08/2025.
//

#include <metal_stdlib>
#include "Common.h"
using namespace metal;

//TODO: Send all of hese has Solid Colors as one object in a buffer, they always exist anyways
constant bool hasSkeleton [[function_constant(HasSkeletonIndex)]];
constant bool hasBaseColorTexture [[function_constant(HasBaseColorTextureIndex)]];
constant bool hasFog [[function_constant(HasFogIndex)]];
constant bool hasNormalTexture [[function_constant(HasNormalTextureIndex)]];

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
    float3 color [[attribute(Color)]];
    float3 tangent [[attribute(Tangent)]];
    float3 bitangent [[attribute(Bitangent)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldCameraPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
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

float4 getFogColor(float4 color, float4 position, float density) {
    float distance = position.z / position.w;
    float4 fogColor = float4(1.0);
    float fogFactor = 1 - clamp(exp(-density * distance), 0.0, 1.0);
    float4 finalColor = mix(color, fogColor, fogFactor);
    return finalColor;
}

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                             constant float4x4 *jointMatrices [[buffer(JointsBufferIndex)]],
                             constant Uniforms &uniforms [[buffer(UniformsBufferIndex)]],
                             constant Instance *instances [[buffer(InstancesBufferIndex)]],
                             uint instanceId [[instance_id]]) {
    
    float4 position = vertexIn.position;
    float4 normal = float4(vertexIn.normal, 0);
    Instance instance = instances[instanceId];
    
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
    matrix_float3x3 instanceNormalMatrix = extract_top_3x3(instance.modelMatrix);
    
    VertexOut vertexOut = VertexOut {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * instance.modelMatrix * position,
        .worldPosition = (uniforms.modelMatrix * instance.modelMatrix * vertexIn.position).xyz,
        .worldNormal = normalMatrix * instanceNormalMatrix * normal.xyz,
        .worldTangent = normalMatrix * instanceNormalMatrix * vertexIn.tangent,
        .worldBitangent = normalMatrix * instanceNormalMatrix * vertexIn.bitangent,
        .uv = vertexIn.uv,
        .color = vertexIn.color
    };
    return vertexOut;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(FragmentUniformsBufferIndex)]],
                              constant Light *lights [[buffer(LightsBufferIndex)]],
                              texture2d<float> baseColorTexture2d [[texture(BaseColorTextureIndex), function_constant(hasBaseColorTexture)]],
                              texture2d<float> normalColorTexture2d [[texture(NormalColorTextureIndex), function_constant(hasNormalTexture)]],
                              sampler textureSampler [[sampler(0)]],
                              constant Material &material [[buffer(MaterialBufferIndex)]]) {
    
    
    
    
    float4 baseColor;
    if (hasBaseColorTexture) {
        baseColor = baseColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgba;
        //TODO: This one is not optimized with function constants, I have to fix it
        if (baseColor.a <= 0.1) {
            discard_fragment();
        }
    } else {
        baseColor = material.baseColor;
    }
    
    if (hasFog) {
        baseColor = getFogColor(baseColor, in.position, 0.1);
    }
    
    float3 normal = 0;
    if (hasNormalTexture) {
        normal = normalColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgb;
    } else {
        normal = in.worldNormal;
    }
    
    //TODO: For now we just add the sunlight, later we need to add a generic more types of light
    float3 lightDirection = normalize(float3(1, 2, -1));
    float4 lightColor = float4(1, 1, 1, 1);
    //Note: if we only use texture, it will not reflect the light direction
    float3 normalDirection = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal) * normal;
    normalDirection = normalize(normalDirection);
    
    float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
    float4 diffuseColor = 0;
    float4 ambientColor = 0;
    ambientColor += lightColor * 0.1 * baseColor;//this is light intensity
    
    diffuseColor += lightColor * baseColor * diffuseIntensity;
    
    //This is for specular, we myst have material shininess for it
//    if (diffuseIntensity > 0) {
//        float3 reflection = reflect(lightDirection, in.worldNormal);
//        //this is camera direction toward the fragment
//        float3 cameraDirection = normalize(in.worldPosition - uniforms.cameraPosition);
//        float specularIntensity = pow(saturate(dot(reflection, cameraDirection)), materialShininess);
//        specularColor += specularIntensity * materialSpecularColor * light.specularColor;
//    }
    
//    baseColor = normalColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgba;
    baseColor = saturate(diffuseColor + ambientColor);
    baseColor.a = 1;
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

fragment float4 fragment_post_processing_plane(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture2d [[texture(BaseColorTextureIndex), function_constant(hasBaseColorTexture)]],
                              sampler textureSampler [[sampler(0)]],
                              constant Material &material [[buffer(MaterialBufferIndex)]],
                              float4 attachedColor [[color(0)]],
                              constant float &planeAlpha [[buffer(16)]]) {
    
    float4 baseColor = baseColorTexture2d.sample(textureSampler, in.uv).rgba;
    if (baseColor.a <= 0.1) {
        discard_fragment();
    }
//    float planeAlpha = 0.2; should be equal/less than 1
    float sourceAlpha = 1 - planeAlpha;
    
    baseColor = baseColor * planeAlpha + attachedColor * sourceAlpha;
    
    return baseColor;
}


fragment float4 fragment_skyBox_reflection_test(VertexOut in [[stage_in]],
                                                constant FragmentUniforms &uniforms [[buffer(FragmentUniformsBufferIndex)]],
                                                texturecube<float> skyTexture [[texture(SkyBoxIndex)]]) {
    float3 cameraDirection = in.worldPosition - uniforms.cameraPosition;
    float3 reflection = reflect(cameraDirection, in.worldNormal);
    constexpr sampler defaultSampler(filter::linear);
    float4 color = skyTexture.sample(defaultSampler, reflection);
    float4 copper = float4(1.0, 0.8, 0.0, 1);
    return color * copper;
}



fragment float4 fragment_ibl(VertexOut in [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(FragmentUniformsBufferIndex)]],
                              constant Light *lights [[buffer(LightsBufferIndex)]],
                              texture2d<float> baseColorTexture2d [[texture(BaseColorTextureIndex), function_constant(hasBaseColorTexture)]],
                              texture2d<float> normalColorTexture2d [[texture(NormalColorTextureIndex), function_constant(hasNormalTexture)]],
                             texture2d<float> metalicTexture2d [[texture(MetalicTextureIndex), function_constant(hasNormalTexture)]],
                             texture2d<float> rothnessColorTexture2d [[texture(RouthnessTextureIndex), function_constant(hasNormalTexture)]],
                              sampler textureSampler [[sampler(0)]],
                              constant Material &material [[buffer(MaterialBufferIndex)]],
                              texturecube<float> diffuseSkyBox [[texture(DiffuseSkyBoxIndex)]],
                              texturecube<float> skyTexture [[texture(SkyBoxIndex)]],
                              texture2d<float> brdfLut [[texture(BrdfLutTextureIndex)]],
                              texture2d<float> ambientOcclusion [[texture(AmbientOcclusionTextureIndex)]]) {

    float4 baseColor;
    if (hasBaseColorTexture) {
        baseColor = baseColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgba;
        //TODO: This one is not optimized with function constants, I have to fix it
        if (baseColor.a <= 0.1) {
            discard_fragment();
        }
    } else {
        baseColor = material.baseColor;
    }
    
//    float3 normal = 0;
//    if (hasNormalTexture) {
//        normal = normalColorTexture2d.sample(textureSampler, in.uv * uniforms.tiling).rgb;
//    } else {
//        normal = in.worldNormal;
//    }
    float3 normal = normalize(in.worldNormal);;
    
    constexpr sampler s(filter::linear, mip_filter::linear);
    
    float4 skyBoxDiffuse = diffuseSkyBox.sample(s, normal);
    
    float routhness = rothnessColorTexture2d.sample(s, in.uv).r;
    float metalicness = metalicTexture2d.sample(s, in.uv).r;
    
    // first part that is the prefilteredColor is done here, prefilteredColor is the one that samoles the blurrier parts for parts with a lot of routhness, level is mipmap level
    float3 viewDirection = in.worldPosition.xyz - uniforms.cameraPosition;
    float3 textureCoordinates = reflect(viewDirection, normal);
    float3 prefilteredColor = skyTexture.sample(s, textureCoordinates, level(routhness * 10)).rgb;
    
    // not using tangent space here, which could be used to replace world normal in case of necessity, look at shaders above for examples
    float NdotV = saturate(dot(normal, normalize(-viewDirection)));
    float2 bdrfLutResult = brdfLut.sample(s, float2(routhness, NdotV)).rg;
    
    float3 f0 = mix(0.04, baseColor.rgb, metalicness);
    
    float3 specularBDRColor = f0 * bdrfLutResult.r + bdrfLutResult.g;
    
    float3 specularColor = prefilteredColor * specularBDRColor;
    
    float4 finalColor = skyBoxDiffuse * baseColor + float4(specularColor, 1);
    
    float4 ambientOcclusionColor = ambientOcclusion.sample(textureSampler, in.uv);
    
    finalColor *= ambientOcclusionColor;
    
    return finalColor;
}
