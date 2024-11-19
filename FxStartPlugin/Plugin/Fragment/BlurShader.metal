//
//  TileableRemoteBrightness.metal
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "../ShaderTypes.h"
#include "../RasterizerData.h"


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

