//
//  ParameterFlags.h
//  FxStartPlugin
//
//  Created by Kacper  on 08/10/2024.
//

#ifndef ParameterFlags_h
#define ParameterFlags_h

typedef enum ParameterFlags
{
    PF_BrightnessClamp = 1,
    PF_BrightnessSlider = 2,
    PF_NegativeButton = 10,
    PF_BlurTypes = 20,
    PF_GaussianBlurRadius = 21,
    PF_KawaseBlurRadius =22,
    PF_BoxBlurRadius = 23,
    PF_OilPaintingRadius = 30,
    PF_OilPaintingLevelOfIntensity = 31,
    PF_OSCTypes = 40,
    
    
    
    PF_EffectTypes = 222,
    PF_BrightnessGroup = 500,
    PF_BlurGroup = 501,
    PF_SpecialEffectsTypes = 502,
    PF_OilPaintingGroup = 503,
    PF_OSCGroup = 504,
    PF_SpecialEffectGroup = 499,
    
    
} ParameterFlags;

#endif /* ParameterFlags_h */
