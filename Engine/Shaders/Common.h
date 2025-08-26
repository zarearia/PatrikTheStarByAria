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

#endif /* Header_h */
