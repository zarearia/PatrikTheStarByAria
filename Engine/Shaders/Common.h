//
//  Header.h
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 25/08/2025.
//

#ifndef Header_h
#define Header_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

typedef enum {
    unused = 0,
    SunLight = 1,
    Ambientlight = 2,
    PointLight = 3,
    SpotLight
} LightType;

typedef struct {
    LightType type;
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    vector_float3 attenuation;
    float intensity;
    float coneAngel;
    vector_float3 coneDirection;
    float coneAttenuation;
} Light;

typedef struct {
    uint32_t lightCount;
    vector_float3 cameraPosition;
    uint32_t tiling;
} FragmentUniforms;


typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Joints = 3,
    Weights = 4
} Attributes;

typedef enum {
    VerticesBufferIndex = 0,
    UniformsBufferIndex = 1,
    FragmentUniformsBufferIndex = 2,
    LightsBufferIndex = 3
} BufferIndices;

#endif /* Header_h */
