//
//  TileableRemoteBrightnessShaderTypes.h
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>

typedef enum VertexInputIndex {
    VI_Vertices        = 0,
    VI_ViewportSize    = 1
} VertexInputIndex;

typedef enum TextureIndex {
    TI_NoneInputImage = 0,
    TI_BrightnessInputImage  = 1,
    TI_NegativeInputImage  = 2,
    TI_GaussianBlurInputImage = 3,
    TI_KawaseBlurInputImage = 4,
    TI_BoxBlurInputImage = 5,
    
    TI_OilPaintingInputImage = 100,
} TextureIndex;

typedef enum FragmentIndexBrightness {
    FIB_Brightness  = 0,
    FIB_Clamp = 1,
} FragmentIndexBrightness;

typedef enum FragmentIndexNegative {
    FIN_Negative = 0,
} FragmentIndexNegative;

typedef enum FragmentIndexGaussianBlur {
    FIGB_BlurRadius = 0,
    FIGB_TexelSizeX = 1,
    FIGB_TexelSizeY = 2,
} FragmentIndexGaussianBlur;

typedef enum FragmentIndexKawaseBlur {
    FIKB_BlurRadius = 0,
    FIKB_TexelSizeX = 1,
    FIKB_TexelSizeY = 2,
} FragmentIndexKawaseBlur;

typedef enum FragmentIndexBoxBlur {
    FIBB_BlurRadius = 0,
    FIBB_TexelSizeX = 1,
    FIBB_TexelSizeY = 2,
} FragmentIndexBoxBlur;

typedef enum FragmentIndexOilPainting {
    FIOP_Radius = 0,
    FIOP_LevelOfIntencity = 1,
    FIOP_TexelSizeX = 2,
    FIOP_TexelSizeY = 3,
} FragmentIndexOilPainting;

typedef struct Vertex2D {
    vector_float2   position;
    vector_float2   textureCoordinate;
} Vertex2D;


#endif /* TileableRemoteBrightnessShaderTypes_h */
