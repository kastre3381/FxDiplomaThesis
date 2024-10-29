//
//  TileableRemoteBrightness.metal
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#include <metal_stdlib>
#include <metal_math>
#include <metal_graphics>
#include <metal_atomic>
#include <metal_simdgroup_matrix>
#include <simd/simd.h>

using namespace metal;

#include "../ShaderTypes.h"
#include "../RasterizerData.h"

#pragma mark Default Shader
[[fragment]]
float4 fragmentDefaultShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_NoneInputImage) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    return static_cast<float4>(colorSample);
}



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



#pragma mark Negative Shader
[[fragment]]
float4 fragmentNegativeShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_NegativeInputImage) ]],
                                       constant bool* negative [[ buffer(FIN_Negative)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    if(*negative == true)
        return 1.0 - static_cast<float4>(colorSample);
    else
        return static_cast<float4>(colorSample);
}





#pragma mark Gaussian Blur Shader
fragment float4 fragmentGaussianBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_GaussianBlurInputImage) ]],
                                           constant int* radius [[buffer(FIGB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIGB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIGB_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    float4 colorSample = 0.0;
    

    float sigma = fmax(static_cast<float>((*radius) / 2), 1);
    unsigned int matrixSize = 2 * (*radius) + 1;
    float matrix[41][41];
    float sum = 0.0;

    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);
    
    for(unsigned int i{0}; i < matrixSize; i++)
    {
        for(unsigned int j{0}; j < matrixSize; j++)
        {
            float xDist = i - r;
            float yDist = j - r;
            float exponent = -(xDist*xDist + yDist*yDist) / (2.0 * sigma * sigma);
            
            matrix[i][j] = exp(exponent) / (2.0 * M_PI_F * sigma * sigma);
            sum += matrix[i][j];
        }
    }
    
    for (unsigned int i{0}; i < matrixSize; i++) 
    {
        for (unsigned int j{0}; j < matrixSize; j++) 
        {
            matrix[i][j] /= sum;
        }
    }
    

    
    for(unsigned int i{0}; i < matrixSize; i++)
    {
        for(unsigned int j{0}; j < matrixSize; j++)
        {
            float2 offset = float2((i - r) * x, (j - r) * y);
            colorSample += static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + offset)) * matrix[i][j];
        }
    }
    
    return colorSample;
}





#pragma mark Kawase Blur Shader
fragment float4 fragmentKawaseBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_KawaseBlurInputImage) ]],
                                           constant int* radius [[buffer(FIKB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIKB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIKB_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    half4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);
    
    colorSample += (colorTexture.sample(textureSampler, in.textureCoordinate) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r * x + 0.5 * x, -r * y + 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(r * x - 0.5 * x, -r * y + 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r * x + 0.5 * x, r * y - 0.5 * y)) +
                    colorTexture.sample(textureSampler, in.textureCoordinate + float2(r * x - 0.5 * x, r * y - 0.5 * y))) / 5.0;
    
    
    
    return static_cast<float4>(colorSample);
}


#pragma mark Box Blur Shader
fragment float4 fragmentBoxBlurShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_BoxBlurInputImage) ]],
                                           constant int* radius [[buffer(FIBB_BlurRadius)]],
                                           constant float* texelSizeX [[buffer(FIBB_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIBB_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear,
                                      r_address::clamp_to_edge,
                                      s_address::clamp_to_edge,
                                      t_address::clamp_to_edge);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    float4 colorSample = 0.0;
    float x = *texelSizeX, y = *texelSizeY, r = static_cast<float>(*radius);
    
    for(unsigned int i{0}; i < 2*r + 1; i++)
    {
        for(unsigned int j{0}; j < 2*r + 1; j++)
        {
            colorSample += static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + float2(-r*x + i*x, -r*y + r*y)));
        }
    }

    
    return static_cast<float4>(colorSample) / pow(2*r + 1, 2);
}







#pragma mark Oil Painting Shader
fragment float4 fragmentOilPaintingShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(TI_OilPaintingInputImage) ]],
                                           constant int* radius [[buffer(FIOP_Radius)]],
                                           constant int* levelOfIntencity [[buffer(FIOP_LevelOfIntencity)]],
                                           constant float* texelSizeX [[buffer(FIOP_TexelSizeX)]],
                                           constant float* texelSizeY [[buffer(FIOP_TexelSizeY)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    if(*radius == 0)
        return static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate));
    
    float x = *texelSizeX, y = *texelSizeY;
    unsigned int r = *radius, loi = *levelOfIntencity;
    int intensityCount[256] = {0};
    float3 averageColor[256] = {float3(0.0)};
    
    for (unsigned int i{0}; i < 256; i++)
    {
        intensityCount[i] = 0;
        averageColor[i] = float3(0.0);
    }
    
    for(unsigned int i{0}; i < 2*r + 1; i++)
    {
        for(unsigned int j{0}; j < 2*r + 1; j++)
        {
            float2 offset = float2((i - float(r)) * x, (j - float(r)) * y);

            float4 color = static_cast<float4>(colorTexture.sample(textureSampler, in.textureCoordinate + offset));
            
            int currIntensity = int(((color.r + color.g + color.b) / 3.0) * (float(loi)));
            
            intensityCount[currIntensity]++;
            averageColor[currIntensity] += color.rgb;
        }
    }
    
    int curMax = intensityCount[0];
    int maxIndex = 0;
    
    for(unsigned int i{1}; i < loi; i++)
    {
        if(intensityCount[i] > curMax)
        {
            curMax = intensityCount[i];
            maxIndex = i;
        }
    }
    
    float3 finalColor = (curMax > 0) ? averageColor[maxIndex] / float(curMax) : float3(0.0);

    return float4(finalColor, 1.0);
}
