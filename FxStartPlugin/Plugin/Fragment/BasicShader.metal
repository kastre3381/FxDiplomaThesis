//
//  Temp.metal
//  FxStartPlugin
//
//  Created by Kacper  on 29/10/2024.
//

#include <metal_stdlib>
using namespace metal;
#include "../ShaderTypes.h"
#include "../RasterizerData.h"

#pragma mark Brightness Shader
[[fragment]]
float4 fragmentBrightnessShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_BrightnessInputImage) ]],
                               constant float* brightness [[ buffer(FIB_Brightness) ]],
                               constant bool* clampVal [[ buffer(FIB_Clamp) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    const half hBrightness = static_cast<half>(*brightness);
    colorSample.rgb = colorSample.rgb * hBrightness;
    
    if(*clampVal) return clamp(static_cast<float4>(colorSample), 0.0, 1.0);
    
    return static_cast<float4>(colorSample);
}
