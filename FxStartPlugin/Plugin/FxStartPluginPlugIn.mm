//
//  FxStartPluginPlugIn.m
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#import "FxStartPluginPlugIn.h"
#import <IOSurface/IOSurfaceObjC.h>
#import "ShaderTypes.h"
#import "MetalDeviceCache.h"
#import "PluginState.h"
#import <string>



@implementation FxStartPluginPlugIn

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. Returning NULL means that a plug-in
// chooses not to be accessible for some reason.
//---------------------------------------------------------

- (nullable instancetype)initWithAPIManager:(id<PROAPIAccessing>)newApiManager;
{
    self = [super init];
    if (self != nil)
    {
        _apiManager = newApiManager;
        _menuEntries = @[@"None", @"Brightness", @"Negative", @"Blur", @"Special Effects", @"Edge detection"];
        _blurEntries = @[@"Gaussian blur", @"Kawase blur", @"Box blur"];
        _specialEffectsEntries = @[@"Oil painting"];
        _oscentries = @[@"No OSC", @"Rectanle OSC", @"Circle OSC"];
    }
    return self;
}

//---------------------------------------------------------
// properties
//
// This method should return an NSDictionary defining the
// properties of the effect.
//---------------------------------------------------------


- (BOOL)properties:(NSDictionary * _Nonnull *)properties
             error:(NSError * _Nullable *)error
{
    *properties = @{
                    kFxPropertyKey_MayRemapTime : [NSNumber numberWithBool:NO],
                    kFxPropertyKey_PixelTransformSupport : [NSNumber numberWithInt:kFxPixelTransform_ScaleTranslate],
                    kFxPropertyKey_VariesWhenParamsAreStatic : [NSNumber numberWithBool:NO]
                    };
    
    return YES;
}

//---------------------------------------------------------
// addParametersWithError
//
// This method is where a plug-in defines its list of parameters.
//---------------------------------------------------------

- (BOOL)addParametersWithError:(NSError**)error
{
    id<FxParameterCreationAPI_v5>   paramAPI    = [_apiManager apiForProtocol:@protocol(FxParameterCreationAPI_v5)];
    if (paramAPI == nil)
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to obtain an FxPlug API Object"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_APIUnavailable
                                     userInfo:userInfo];
        
        return NO;
    }
    
    
    
//    [paramAPI addPointParameterWithName:@"Location"
//                            parameterID:2121
//                               defaultX:1.0 / 3.0
//                               defaultY:2.0 / 3.0
//                         parameterFlags:kFxParameterFlag_DEFAULT];
    
    if (![paramAPI addPopupMenuWithName:@"Filters"
                            parameterID:PF_EffectTypes
                           defaultValue:0
                            menuEntries:_menuEntries
                         parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add filters popup menu"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    [paramAPI startParameterSubGroup:@"Brightness"
                         parameterID:PF_BrightnessGroup
                      parameterFlags:kFxParameterFlag_HIDDEN];
    
    if (![paramAPI addFloatSliderWithName:@"Intensity"
                              parameterID:PF_BrightnessSlider
                             defaultValue:1.0
                             parameterMin:0.0
                             parameterMax:100.0
                                sliderMin:0.0
                                sliderMax:10.0
                                    delta:0.1
                           parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add brightness slider"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    if (![paramAPI addToggleButtonWithName:@"Clamp values"
                               parameterID:PF_BrightnessClamp
                              defaultValue:FALSE
                            parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add brightness slider"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    [paramAPI endParameterSubGroup];
    
    
    
    
    if (![paramAPI addToggleButtonWithName:@"Negative"
                               parameterID:PF_NegativeButton
                              defaultValue:FALSE
                            parameterFlags:kFxParameterFlag_HIDDEN])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add negative toggle button"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    [paramAPI startParameterSubGroup:@"Blur"
                         parameterID:PF_BlurGroup
                      parameterFlags:kFxParameterFlag_HIDDEN];
    
    if (![paramAPI addPopupMenuWithName:@"Type"
                            parameterID:PF_BlurTypes
                           defaultValue:0
                            menuEntries:_blurEntries
                         parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add filters popup menu"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    
    if (![paramAPI addIntSliderWithName:@"Blur radius"
                            parameterID:PF_GaussianBlurRadius
                           defaultValue:0
                           parameterMin:0
                           parameterMax:20
                              sliderMin:0
                              sliderMax:20
                                  delta:1
                         parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add blur radius slider"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    if (![paramAPI addIntSliderWithName:@"Blur radius"
                            parameterID:PF_KawaseBlurRadius
                           defaultValue:0
                           parameterMin:0
                           parameterMax:20
                              sliderMin:0
                              sliderMax:20
                                  delta:1
                         parameterFlags:kFxParameterFlag_HIDDEN])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add blur radius slider"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    
    if (![paramAPI addIntSliderWithName:@"Blur radius"
                            parameterID:PF_BoxBlurRadius
                           defaultValue:0
                           parameterMin:0
                           parameterMax:20
                              sliderMin:0
                              sliderMax:20
                                  delta:1
                         parameterFlags:kFxParameterFlag_HIDDEN])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add blur radius slider"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    [paramAPI endParameterSubGroup];
    
    [paramAPI startParameterSubGroup:@"Special Effects"
                            parameterID:PF_SpecialEffectGroup
                        parameterFlags:kFxParameterFlag_HIDDEN];
    
    if (![paramAPI addPopupMenuWithName:@"Type"
                            parameterID:PF_SpecialEffectsTypes
                           defaultValue:0
                            menuEntries:_specialEffectsEntries
                         parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add filters popup menu"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    
    [paramAPI startParameterSubGroup:@"Oil painting effect"
                            parameterID:PF_OilPaintingGroup
                        parameterFlags:kFxParameterFlag_DEFAULT];

    
    if (![paramAPI addIntSliderWithName:@"Radius"
                            parameterID:PF_OilPaintingRadius
                            defaultValue:0
                            parameterMin:0
                            parameterMax:20
                                sliderMin:0
                                sliderMax:20
                                    delta:1
                            parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
            NSLocalizedDescriptionKey : @"Unable to add blur radius slider"
        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                            code:kFxError_InvalidParameter
                                        userInfo:userInfo];
        
        return NO;
    }
    
    if (![paramAPI addIntSliderWithName:@"Level of intensity"
                            parameterID:PF_OilPaintingLevelOfIntensity
                            defaultValue:0
                            parameterMin:0
                            parameterMax:255
                                sliderMin:0
                                sliderMax:255
                                    delta:1
                            parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
            NSLocalizedDescriptionKey : @"Unable to add blur radius slider"
        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                            code:kFxError_InvalidParameter
                                        userInfo:userInfo];
        
        return NO;
    }
    
    [paramAPI endParameterSubGroup];
    [paramAPI endParameterSubGroup];
    
    [paramAPI startParameterSubGroup:@"OSC"
                         parameterID:PF_OSCGroup
                      parameterFlags:kFxParameterFlag_DEFAULT];
    
    if (![paramAPI addPopupMenuWithName:@"Type"
                            parameterID:PF_OSCTypes
                           defaultValue:0
                            menuEntries:_oscentries
                         parameterFlags:kFxParameterFlag_DEFAULT])
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Unable to add filters popup menu"
                                        };
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_InvalidParameter
                                     userInfo:userInfo];
        
        return NO;
    }
    
    
    [paramAPI endParameterSubGroup];
    
    return YES;
}

- (BOOL)parameterChanged:(UInt32)paramID
                  atTime:(CMTime)time
                   error:(NSError * _Nullable *)error
{
    NSLog(@"parameterChanged called for parameter ID: %u at time: %f", paramID, CMTimeGetSeconds(time));
    
    id<FxParameterRetrievalAPI_v6> retrievalAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    id<FxParameterSettingAPI_v6> settingsAPI = [_apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v6)];
    
    if(paramID == PF_EffectTypes)
    {
        
        int menuVal;
        
        [retrievalAPI getIntValue:&menuVal 
                    fromParameter:PF_EffectTypes
                           atTime:time];
        
        [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                           toParameter:PF_BrightnessGroup];
        
        [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                           toParameter:PF_NegativeButton];
        
        [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                           toParameter:PF_BlurGroup];
        
        [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                           toParameter:PF_SpecialEffectGroup];
        
        
        switch (menuVal)
        {
            case ET_Brightness:
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_BrightnessGroup];
                break;
            }
            
            case ET_Negative:
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_NegativeButton];
                break;
            }
            
            case ET_Blur:
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_BlurGroup];
                
                break;
            }
                
            case ET_SpecialEffect:
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_SpecialEffectGroup];
                
                break;
            }
            
            
            default:
                break;
        }
    }
    
    else if(paramID == PF_BlurTypes)
    {
        int blurMenu;
        
        [retrievalAPI getIntValue:&blurMenu
                    fromParameter:PF_BlurTypes
                           atTime:time];
        
        NSLog(@"parameterChanged called for blur ID: %u at time: %f", blurMenu, CMTimeGetSeconds(time));
        
        switch(blurMenu)
        {
            case (BT_GaussianBlur):
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_GaussianBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_KawaseBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_BoxBlurRadius];
                
                break;
            }
                
                
            case (BT_KawaseBlur):
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_KawaseBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_GaussianBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_BoxBlurRadius];
                
                break;
            }
                
            case (BT_BoxBlur):
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_BoxBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_GaussianBlurRadius];
                
                [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                                   toParameter:PF_KawaseBlurRadius];
                
                break;
            }
                
            default:
                break;
        }
    }
    
    
    else if(paramID == PF_SpecialEffectsTypes)
    {
        int specialMenu;
        
        [retrievalAPI getIntValue:&specialMenu
                    fromParameter:PF_SpecialEffectsTypes
                           atTime:time];
    
        
        [settingsAPI setParameterFlags:kFxParameterFlag_HIDDEN
                           toParameter:PF_OilPaintingGroup];
        
        
        switch(specialMenu)
        {
            case (ST_OilPainting):
            {
                [settingsAPI setParameterFlags:kFxParameterFlag_DEFAULT
                                   toParameter:PF_OilPaintingGroup];
                
                break;
            }
                
            default:
                break;
        }
    }
        
    
    return YES;
}


//---------------------------------------------------------
// pluginState:atTime:quality:error
//
// Your plug-in should get its parameter values, do any calculations it needs to
// from those values, and package up the result to be used later with rendering.
// The host application will call this method before rendering. The
// FxParameterRetrievalAPI* is valid during this call. Use it to get the values of
// your plug-in's parameters, then put those values or the results of any calculations
// you need to do with those parameters to render into an NSData that you return
// to the host application. The host will pass it back to you during subsequent calls.
// Do not re-use the NSData; always create a new one as this method may be called
// on multiple threads at the same time.
//---------------------------------------------------------

- (BOOL)pluginState:(NSData**)pluginState
             atTime:(CMTime)renderTime
            quality:(FxQuality)qualityLevel
              error:(NSError**)error
{
    BOOL    succeeded = NO;
    id<FxParameterRetrievalAPI_v6>  paramGetAPI = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    if (paramGetAPI != nil)
    {
        int effectType;
        [paramGetAPI getIntValue:&effectType
                   fromParameter:PF_EffectTypes
                          atTime:renderTime];
        
        BOOL brightnessClamp = FALSE;
        [paramGetAPI getBoolValue:&brightnessClamp
                    fromParameter:PF_BrightnessClamp
                           atTime:renderTime];
        
        double  brightness  = 1.0;
        [paramGetAPI getFloatValue:&brightness
                     fromParameter:PF_BrightnessSlider
                            atTime:renderTime];
        
        BOOL  negative  = FALSE;
        [paramGetAPI getBoolValue:&negative
                     fromParameter:PF_NegativeButton
                            atTime:renderTime];
        

        int  gaussianBlurRadius  = 0;
        [paramGetAPI getIntValue:&gaussianBlurRadius
                     fromParameter:PF_GaussianBlurRadius
                            atTime:renderTime];
        
        int  kawaseBlurRadius  = 0;
        [paramGetAPI getIntValue:&kawaseBlurRadius
                     fromParameter:PF_KawaseBlurRadius
                            atTime:renderTime];
        
        int  boxBlurRadius  = 0.0;
        [paramGetAPI getIntValue:&boxBlurRadius
                     fromParameter:PF_BoxBlurRadius
                            atTime:renderTime];
        
        int  blurType  = 0;
        [paramGetAPI getIntValue:&blurType
                   fromParameter:PF_BlurTypes
                          atTime:renderTime];
        
        int  specialType  = 0;
        [paramGetAPI getIntValue:&specialType
                   fromParameter:PF_SpecialEffectsTypes
                          atTime:renderTime];
        
        int  oilPaintingRadius  = 0;
        [paramGetAPI getIntValue:&oilPaintingRadius
                     fromParameter:PF_OilPaintingRadius
                            atTime:renderTime];
        
        int  oilPaintingLevelOfIntensity  = 0;
        [paramGetAPI getIntValue:&oilPaintingLevelOfIntensity
                     fromParameter:PF_OilPaintingLevelOfIntensity
                            atTime:renderTime];
        
        PluginState state;
        state.brightness = brightness;
        state.clampBrightness = brightnessClamp;
        state.negative = negative;
        state.gaussianBlurRadius = gaussianBlurRadius;
        state.kawaseBlurRadius = kawaseBlurRadius;
        state.boxBlurRadius = boxBlurRadius;
        state.oilPaintingRadius = oilPaintingRadius;
        state.oilPaintingLevelOfIntensity = oilPaintingLevelOfIntensity;
        
        if(effectType == ET_Blur)
        {
            if(blurType == BT_GaussianBlur) state.effect = ET_GaussianBlur;
            else if (blurType == BT_KawaseBlur) state.effect = ET_KawaseBlur;
            else state.effect = ET_BoxBlur;
        }
        
        else if(effectType == ET_SpecialEffect)
        {
            if(specialType == ST_OilPainting) state.effect = ET_OilPainting;
        }
        
        else state.effect = static_cast<EffectTypes>(effectType);
        
        
        
        *pluginState = [NSData dataWithBytes:&state
                                      length:sizeof(state)];
        
        if (*pluginState != nil) {
            succeeded = YES;
        }
        

    }
    else
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:FxPlugErrorDomain
                                         code:kFxError_ThirdPartyDeveloperStart + 20
                                     userInfo:@{
                                                NSLocalizedDescriptionKey :
                                                    @"Unable to retrieve FxParameterRetrievalAPI_v6 in \
                                                    [-pluginStateAtTime:]" }];
        
    }
    
    return succeeded;
}

//---------------------------------------------------------
// destinationImageRect:sourceImages:destinationImage:pluginState:atTime:error
//
// This method will calculate the rectangular bounds of the output
// image given the various inputs and plug-in state
// at the given render time.
// It will pass in an array of images, the plug-in state
// returned from your plug-in's -pluginStateAtTime:error: method,
// and the render time.
//---------------------------------------------------------

- (BOOL)destinationImageRect:(FxRect *)destinationImageRect
                sourceImages:(NSArray<FxImageTile *> *)sourceImages
            destinationImage:(nonnull FxImageTile *)destinationImage
                 pluginState:(NSData *)pluginState
                      atTime:(CMTime)renderTime
                       error:(NSError * _Nullable *)outError
{
    if (sourceImages.count < 1)
    {
        NSLog (@"No inputImages list");
        return NO;
    }
    
    // In the case of a filter that only changed RGB values,
    // the output rect is the same as the input rect.
    *destinationImageRect = sourceImages [ 0 ].imagePixelBounds;
    
    return YES;
    
}

//---------------------------------------------------------
// sourceTileRect:sourceImageIndex:sourceImages:destinationTileRect:destinationImage:pluginState:atTime:error
//
// Calculate tile of the source image we need
// to render the given output tile.
//---------------------------------------------------------

- (BOOL)sourceTileRect:(FxRect *)sourceTileRect
      sourceImageIndex:(NSUInteger)sourceImageIndex
          sourceImages:(NSArray<FxImageTile *> *)sourceImages
   destinationTileRect:(FxRect)destinationTileRect
      destinationImage:(FxImageTile *)destinationImage
           pluginState:(NSData *)pluginState
                atTime:(CMTime)renderTime
                 error:(NSError * _Nullable *)outError
{
    // Since this is a color-only filter, the input tile will be the same size as the output tile
    *sourceTileRect = destinationTileRect;
    
    return YES;
}



//---------------------------------------------------------
// renderDestinationImage:sourceImages:pluginState:atTime:error:
//
// The host will call this method when it wants your plug-in to render an image
// tile of the output image. It will pass in each of the input tiles needed as well
// as the plug-in state needed for the calculations. Your plug-in should do all its
// rendering in this method. It should not attempt to use the FxParameterRetrievalAPI*
// object as it is invalid at this time. Note that this method will be called on
// multiple threads at the same time.
//---------------------------------------------------------



- (BOOL)renderDestinationImage:(FxImageTile *)destinationImage
                  sourceImages:(NSArray<FxImageTile *> *)sourceImages
                   pluginState:(NSData *)pluginState
                        atTime:(CMTime)renderTime
                         error:(NSError * _Nullable *)outError
{
    if ((pluginState == nil) || (sourceImages [ 0 ].ioSurface == nil) || (destinationImage.ioSurface == nil))
    {
        NSDictionary*   userInfo    = @{
                                        NSLocalizedDescriptionKey : @"Invalid plugin state received from host"
                                        };
        if (outError != NULL)
            *outError = [NSError errorWithDomain:FxPlugErrorDomain
                                            code:kFxError_InvalidParameter
                                        userInfo:userInfo];
        return NO;
    }
    
    
    PluginState state;
    [pluginState getBytes:&state
                   length:sizeof(state)];
    
    
    
    MetalDeviceCache*  deviceCache     = [MetalDeviceCache deviceCache];
    MTLPixelFormat     pixelFormat     = [MetalDeviceCache MTLPixelFormatForImageTile:destinationImage];
    id<MTLCommandQueue> commandQueue   = [deviceCache commandQueueWithRegistryID:sourceImages[0].deviceRegistryID
                                                                     pixelFormat:pixelFormat];
    if (commandQueue == nil)
    {
        return NO;
    }
    
    id<MTLCommandBuffer>    commandBuffer   = [commandQueue commandBuffer];	
    commandBuffer.label = @"DynamicRegXPC Command Buffer";
    [commandBuffer enqueue];
    
    id<MTLTexture>  inputTexture    = [sourceImages[0] metalTextureForDevice:[deviceCache deviceWithRegistryID:sourceImages[0].deviceRegistryID]];
    id<MTLTexture>  outputTexture   = [destinationImage metalTextureForDevice:[deviceCache deviceWithRegistryID:destinationImage.deviceRegistryID]];
        
    
    MTLRenderPassColorAttachmentDescriptor* colorAttachmentDescriptor   = [[MTLRenderPassColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.texture = outputTexture;
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 0.5, 0.0, 1.0);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    MTLRenderPassDescriptor*    renderPassDescriptor    = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
    id<MTLRenderCommandEncoder>   commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Rendering
    float   outputWidth     = (float)(destinationImage.tilePixelBounds.right - destinationImage.tilePixelBounds.left);
    float   outputHeight    = (float)(destinationImage.tilePixelBounds.top - destinationImage.tilePixelBounds.bottom);
    Vertex2D    vertices[]  = {
        { {  static_cast<float>(outputWidth / 2.0), static_cast<float>(-outputHeight / 2.0) }, { 1.0, 1.0 } },
        { { static_cast<float>(-outputWidth / 2.0), static_cast<float>(-outputHeight / 2.0) }, { 0.0, 1.0 } },
        { {  static_cast<float>(outputWidth / 2.0),  static_cast<float>(outputHeight / 2.0) }, { 1.0, 0.0 } },
        { { static_cast<float>(-outputWidth / 2.0),  static_cast<float>(outputHeight / 2.0) }, { 0.0, 0.0 } }
    };
    
    simd_uint2  viewportSize = {
        (unsigned int)(outputWidth),
        (unsigned int)(outputHeight)
    };
    
    MTLViewport viewport    = {
        0, 0, outputWidth, outputHeight, -1.0, 1.0
    };
    [commandEncoder setViewport:viewport];
    
    float texelSizeX = 1.0/static_cast<float>(outputTexture.width);
    float texelSizeY = 1.0/static_cast<float>(outputTexture.height);
    

#pragma mark Brightness effect
    switch (state.effect) {
        case (ET_Brightness):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_Brightness];
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_BrightnessInputImage];
            
            
            float brightnessValue = (float)(state.brightness);
            [commandEncoder setFragmentBytes:&brightnessValue
                                      length:sizeof(brightnessValue)
                                     atIndex:FIB_Brightness];
            
            BOOL clampBrightness = (BOOL)(state.clampBrightness);
            [commandEncoder setFragmentBytes:&clampBrightness
                                      length:sizeof(clampBrightness)
                                     atIndex:FIB_Clamp];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            break;
        }
            
#pragma mark Negative effect
        case (ET_Negative):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_Negative];
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_NegativeInputImage];
            
            BOOL negative = (BOOL)(state.negative);
            [commandEncoder setFragmentBytes:&negative
                                      length:sizeof(negative)
                                     atIndex:FIN_Negative];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            break;
        }
            
#pragma mark Gaussian Blur effect
        case (ET_GaussianBlur):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_GaussianBlur];
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_GaussianBlurInputImage];
            
            
            [commandEncoder setFragmentBytes:&texelSizeX
                                      length:sizeof(texelSizeX)
                                     atIndex:FIGB_TexelSizeX];
            
            [commandEncoder setFragmentBytes:&texelSizeY
                                      length:sizeof(texelSizeY)
                                     atIndex:FIGB_TexelSizeY];
            
            int radius = (int)state.gaussianBlurRadius;
            [commandEncoder setFragmentBytes:&radius
                                      length:sizeof(radius)
                                     atIndex:FIGB_BlurRadius];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            
            
            break;
        }
            
#pragma mark Kawase Blur effect
        case (ET_KawaseBlur):
        {
            int radius = (int)state.kawaseBlurRadius;
            
            if(radius == 0)
            {
                id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                              pixelFormat:pixelFormat
                                                             pipelineType:PT_None];
                [commandEncoder setRenderPipelineState:pipelineState];
                
                [commandEncoder setVertexBytes:vertices
                                        length:sizeof(vertices)
                                       atIndex:VI_Vertices];
                
                
                [commandEncoder setVertexBytes:&viewportSize
                                        length:sizeof(viewportSize)
                                       atIndex:VI_ViewportSize];
                
                [commandEncoder setFragmentTexture:inputTexture
                                           atIndex:TI_NoneInputImage];
                
                [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                                   vertexStart:0
                                   vertexCount:4];
                
                [commandEncoder endEncoding];
                
                
                [commandBuffer commit];
                [commandBuffer waitUntilCompleted];
            }
            
            else
            {
                id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                              pixelFormat:pixelFormat
                                                             pipelineType:PT_KawaseBlur];
                [commandEncoder setRenderPipelineState:pipelineState];
                
                [commandEncoder setVertexBytes:vertices
                                        length:sizeof(vertices)
                                       atIndex:VI_Vertices];
                
                
                [commandEncoder setVertexBytes:&viewportSize
                                        length:sizeof(viewportSize)
                                       atIndex:VI_ViewportSize];
                
                [commandEncoder setFragmentTexture:inputTexture
                                           atIndex:TI_KawaseBlurInputImage];
                
                [commandEncoder setFragmentBytes:&texelSizeX
                                          length:sizeof(texelSizeX)
                                         atIndex:FIKB_TexelSizeX];
                
                [commandEncoder setFragmentBytes:&texelSizeY
                                          length:sizeof(texelSizeY)
                                         atIndex:FIKB_TexelSizeY];
                
               
                [commandEncoder setFragmentBytes:&radius
                                          length:sizeof(radius)
                                         atIndex:FIKB_BlurRadius];
                
                [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                                   vertexStart:0
                                   vertexCount:4];
                
                [commandEncoder endEncoding];
                
                int tempRad = 2;
                while(tempRad++ <= radius)
                {
                    id<MTLTexture> tempTexture = outputTexture;
                    outputTexture = inputTexture;
                    inputTexture = tempTexture;
                    
                    colorAttachmentDescriptor.texture = outputTexture;
                    renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
                    
                    commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
                    
                    [commandEncoder setViewport:viewport];
                    
                    [commandEncoder setRenderPipelineState:pipelineState];
                    
                    [commandEncoder setVertexBytes:vertices
                                            length:sizeof(vertices)
                                           atIndex:VI_Vertices];
                    
                    
                    [commandEncoder setVertexBytes:&viewportSize
                                            length:sizeof(viewportSize)
                                           atIndex:VI_ViewportSize];
                    
                    [commandEncoder setFragmentTexture:inputTexture
                                               atIndex:TI_KawaseBlurInputImage];
                    
                    [commandEncoder setFragmentBytes:&texelSizeX
                                              length:sizeof(texelSizeX)
                                             atIndex:FIKB_TexelSizeX];
                    
                    [commandEncoder setFragmentBytes:&texelSizeY
                                              length:sizeof(texelSizeY)
                                             atIndex:FIKB_TexelSizeY];
                    
                   
                    [commandEncoder setFragmentBytes:&tempRad
                                              length:sizeof(tempRad)
                                             atIndex:FIKB_BlurRadius];
                    
                    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                                       vertexStart:0
                                       vertexCount:4];
                    
                    [commandEncoder endEncoding];
                }
                
                [commandBuffer commit];
                [commandBuffer waitUntilCompleted];
                
            }
            
            break;
        }
            
#pragma mark Box Blur effect
        case (ET_BoxBlur):
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_BoxBlur];
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_BoxBlurInputImage];
            
            
            [commandEncoder setFragmentBytes:&texelSizeX
                                      length:sizeof(texelSizeX)
                                     atIndex:FIBB_TexelSizeX];
            
            [commandEncoder setFragmentBytes:&texelSizeY
                                      length:sizeof(texelSizeY)
                                     atIndex:FIBB_TexelSizeY];
            
            int radius = (int)state.boxBlurRadius;
            [commandEncoder setFragmentBytes:&radius
                                      length:sizeof(radius)
                                     atIndex:FIBB_BlurRadius];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            
            
            break;
        }
            
#pragma mark Oil painting effect
        case (ET_OilPainting):
        {
            id<MTLRenderPipelineState>  pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_GaussianBlur];
            
            
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_GaussianBlurInputImage];
            
            [commandEncoder setFragmentBytes:&texelSizeX
                                      length:sizeof(texelSizeX)
                                     atIndex:FIGB_TexelSizeX];
            
            [commandEncoder setFragmentBytes:&texelSizeY
                                      length:sizeof(texelSizeY)
                                     atIndex:FIGB_TexelSizeY];
            
            int tempRad = 1;
            [commandEncoder setFragmentBytes:&tempRad
                                      length:sizeof(tempRad)
                                     atIndex:FIGB_BlurRadius];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            
            id<MTLTexture> tempTexture = outputTexture;
            outputTexture = inputTexture;
            inputTexture = tempTexture;
            
            colorAttachmentDescriptor.texture = inputTexture;
            renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
            commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            
            [commandEncoder setViewport:viewport];
            
            pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_OilPainting];
            
            
            [commandEncoder setRenderPipelineState:pipelineState];
            
            
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                    atIndex:VI_Vertices];
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                    atIndex:VI_ViewportSize];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setFragmentTexture:outputTexture
                                       atIndex:TI_OilPaintingInputImage];
            
            [commandEncoder setFragmentBytes:&texelSizeX
                                      length:sizeof(texelSizeX)
                                     atIndex:FIOP_TexelSizeX];
            
            [commandEncoder setFragmentBytes:&texelSizeY
                                      length:sizeof(texelSizeY)
                                     atIndex:FIOP_TexelSizeY];
            
            int radius = (int)state.oilPaintingRadius;
            [commandEncoder setFragmentBytes:&radius
                                      length:sizeof(radius)
                                     atIndex:FIOP_Radius];
            
            int loi = (int)state.oilPaintingLevelOfIntensity;
            [commandEncoder setFragmentBytes:&loi
                                      length:sizeof(loi)
                                     atIndex:FIOP_LevelOfIntencity];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            
            
            break;
        }
            
#pragma mark Default pass
        default:
        {
            id<MTLRenderPipelineState> pipelineState  = [deviceCache pipelineStateWithRegistryID:sourceImages[0].deviceRegistryID
                                                          pixelFormat:pixelFormat
                                                         pipelineType:PT_None];
            [commandEncoder setRenderPipelineState:pipelineState];
            
            [commandEncoder setVertexBytes:vertices
                                    length:sizeof(vertices)
                                   atIndex:VI_Vertices];
            
            
            [commandEncoder setVertexBytes:&viewportSize
                                    length:sizeof(viewportSize)
                                   atIndex:VI_ViewportSize];
            
            [commandEncoder setFragmentTexture:inputTexture
                                       atIndex:TI_NoneInputImage];
            
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                               vertexStart:0
                               vertexCount:4];
            
            [commandEncoder endEncoding];
            
            
            [commandBuffer commit];
            [commandBuffer waitUntilCompleted];
            break;
        }
    }
    
    
    
    [colorAttachmentDescriptor release];
    
    [deviceCache returnCommandQueueToCache:commandQueue];
    
    return YES;
    
}

@end
