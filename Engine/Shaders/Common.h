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
    SunLight = 1
} LightType;

typedef struct {
    LightType type;
    vector_float3 position;
    vector_float3 color;
    float intensity;
} Light;

typedef struct {
    uint32_t lightCount;
} FragmentUniforms;

#endif /* Header_h */
