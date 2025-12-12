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
    //TODO: check if this has any memory or other types of benefits: try to keep the things that we normally have at start and the rest after them, like we always can produce(or have) tangent bitangent
    Tangent = 3,
    Bitangent = 4,
    Color = 5,
    Joints = 6,
    Weights = 7,
} Attributes;

typedef enum {
    VerticesBufferIndex = 0,
    //leaving 1 to 10 for vertexDescriptor
    UniformsBufferIndex = 11,
    FragmentUniformsBufferIndex = 12,
    LightsBufferIndex = 13,
    JointsBufferIndex = 14,
    MaterialBufferIndex = 15
} BufferIndices;

typedef enum {
    BaseColorTextureIndex = 0,
    NormalColorTextureIndex = 1
} TextureIndices;

typedef enum {
    HasSkeletonIndex = 0,
    HasBaseColorTextureIndex = 1,
    HasFogIndex = 2,
    HasNormalTextureIndex = 3,
} ConstantFunctionIndices;

typedef struct {
    vector_float4 baseColor;
} Material;

#endif /* Header_h */
