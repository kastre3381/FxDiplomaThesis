//
//  PluginState.h
//  FxStartPlugin
//
//  Created by Kacper  on 04/09/2024.
//

#ifndef PluginState_h
#define PluginState_h

#include "EffectTypes.h"

typedef struct
{
    EffectTypes effect;
    double brightness;
    bool clampBrightness;
    bool negative;
    int gaussianBlurRadius;
    int kawaseBlurRadius;
    int boxBlurRadius;
    int oilPaintingRadius;
    int oilPaintingLevelOfIntensity;
} PluginState;

#endif /* PluginState_h */
