//
//  EffectTypes.h
//  FxStartPlugin
//
//  Created by Kacper  on 08/10/2024.
//

#ifndef EffectTypes_h
#define EffectTypes_h

typedef enum EffectTypes
{
    ET_None = 0,
    ET_Brightness = 1,
    ET_Negative = 2,
    ET_Blur = 3,
    ET_SpecialEffect = 4,
    
    ET_GaussianBlur = 200,
    ET_KawaseBlur = 201,
    ET_BoxBlur = 202,
    
    ET_OilPainting = 300,
} EffectTypes;

typedef enum BlurTypes
{
    BT_GaussianBlur = 0,
    BT_KawaseBlur = 1,
    BT_BoxBlur = 2,
} BlurTypes;

typedef enum SpecialTypes
{
    ST_OilPainting = 0,
} SpecialTypes;

#endif /* EffectTypes_h */
