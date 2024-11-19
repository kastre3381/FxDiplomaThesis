#include "OSC.h"
#include "../FxStartPluginPlugIn.h"
#include "../Device/MetalDeviceCache.h"


enum {
    kFSPart_Rectangle   = 1,
    kFSPart_Circle = 2,
};

const simd_float4   kUnselectedColor    = { 0.0, 0.0, 0.0, 0.0 };
const simd_float4   kSelectedColor      = { 0.1, 0.1, 0.1, 0.1 };
const simd_float4   kOutlineColor       = { 1.0, 1.0, 1.0, 1.0 };
const simd_float4   kShadowColor        = { 0.0, 0.0, 0.0, 1.0 };

@implementation OSC
{
    NSLock* lastPositionLock;
}

- (instancetype)initWithAPIManager:(id<PROAPIAccessing>)newAPIManager
{
    self = [super init];
    
    if (self != nil)
    {
        apiManager = newAPIManager;
        lastPositionLock = [[NSLock alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [lastPositionLock release];
    [super dealloc];
}


#pragma mark -
#pragma mark Drawing

- (FxDrawingCoordinates)drawingCoordinates
{
    return kFxDrawingCoordinates_CANVAS;
}


- (void)canvasPoint:(CGPoint*)canvasPt
    forCircleCenter:(CGPoint)cc
              angle:(double)radians
   normalizedRadius:(CGPoint)normalizedRadius
         canvasSize:(NSSize)canvasSize
             oscAPI:(id<FxOnScreenControlAPI_v4>)oscAPI
{
    CGPoint objectPt;
    objectPt.x = cc.x + cos(radians) * normalizedRadius.x;
    objectPt.y = cc.y + sin(radians) * normalizedRadius.y;
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                            fromX:objectPt.x
                            fromY:objectPt.y
                          toSpace:kFxDrawingCoordinates_CANVAS
                              toX:&canvasPt->x
                              toY:&canvasPt->y];
    canvasPt->y = canvasSize.height - canvasPt->y;
    canvasPt->x -= canvasSize.width / 2.0;
    canvasPt->y -= canvasSize.height / 2.0;
}

- (void)drawCircleWithImageSize:(NSSize)canvasSize
                 commandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
                     activePart:(NSInteger)activePart
                         atTime:(CMTime)time
{
    double  destImageWidth  = canvasSize.width;
    double  destImageHeight = canvasSize.height;
    
    // Draw the circle
    id<FxParameterRetrievalAPI_v6>  paramAPI    = [apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    CGPoint cc  = { 0.5, 0.5 };
//    [paramAPI getXValue:&cc.x
//                 YValue:&cc.y
//          fromParameter:kCircleCenter
//                 atTime:time];
    
    double  radius  = 0.3;
//    [paramAPI getFloatValue:&radius
//              fromParameter:kCircleRadius
//                     atTime:time];
    id<FxOnScreenControlAPI_v4> oscAPI  = [apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    NSRect  imageBounds = [oscAPI inputBounds];
    CGPoint normalizedRadius;
    normalizedRadius.x = radius / imageBounds.size.width;
    normalizedRadius.y = radius / imageBounds.size.height;
    
    CGPoint canvasCC    = { 0.0, 0.0 };
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_OBJECT
                            fromX:cc.x
                            fromY:cc.y
                          toSpace:kFxDrawingCoordinates_CANVAS
                              toX:&canvasCC.x
                              toY:&canvasCC.y];
    canvasCC.y = destImageHeight - canvasCC.y;
    canvasCC.x -= destImageWidth / 2.0;
    canvasCC.y -= destImageHeight / 2.0;
    
    
    const size_t    kNumAngles              = 360;
    const float     kDegreesPerIteration    = 360 / kNumAngles;
    const size_t    kNumCircleVertices      = 3 * kNumAngles;
    Vertex2D    circleVertices [ kNumCircleVertices ];
    simd_float2 zeroZero    = { 0.0, 0.0 };
    CGPoint     canvasPt;
    for (int i = 0; i < kNumAngles; ++i)
    {
        // Center point
        circleVertices [ i * 3 + 0 ].position.x = canvasCC.x;
        circleVertices [ i * 3 + 0 ].position.y = canvasCC.y;
        circleVertices [ i * 3 + 0 ].textureCoordinate = zeroZero;
        
        // Point at i degrees on the outer edge of the cirle
        double  radians = (double)(i * kDegreesPerIteration) * M_PI / 180.0;
        [self canvasPoint:&canvasPt
          forCircleCenter:cc
                    angle:radians
         normalizedRadius:normalizedRadius
               canvasSize:canvasSize
                   oscAPI:oscAPI];
        circleVertices [ i * 3 + 1 ].position.x = canvasPt.x;
        circleVertices [ i * 3 + 1 ].position.y = canvasPt.y;
        circleVertices [ i * 3 + 1 ].textureCoordinate = zeroZero;
        
        // Point at (i + 1) degrees on the outer edge of the circle
        radians = (double)((i + 1) * kDegreesPerIteration) * M_PI / 180.0;
        [self canvasPoint:&canvasPt
          forCircleCenter:cc
                    angle:radians
         normalizedRadius:normalizedRadius
               canvasSize:canvasSize
                   oscAPI:oscAPI];
        circleVertices [ i * 3 + 2 ].position.x = canvasPt.x;
        circleVertices [ i * 3 + 2 ].position.y = canvasPt.y;
        circleVertices [ i * 3 + 2 ].textureCoordinate = zeroZero;
    }
    
    Vertex2D    outlineVertices [ kNumAngles + 1 ];
    for (int i = 0; i < kNumAngles; ++i)
    {
        outlineVertices [ i ] = circleVertices [ i * 3 + 1 ];
    }
    outlineVertices [ kNumAngles ] = outlineVertices [ 0 ];
    
    // Draw the circle
//    [commandEncoder setVertexBytes:circleVertices
//                            length:sizeof(circleVertices)
//                           atIndex:FSVI_Vertices];
//    
//    simd_uint2  viewportSize = {
//        (unsigned int)(destImageWidth),
//        (unsigned int)(destImageHeight)
//    };
//    [commandEncoder setVertexBytes:&viewportSize
//                            length:sizeof(viewportSize)
//                           atIndex:FSVI_ViewportSize];
//    
//    if (activePart == kFSPart_Circle)
//    {
//        [commandEncoder setFragmentBytes:&kSelectedColor
//                                  length:sizeof(kSelectedColor)
//                                 atIndex:FSFI_DrawColor];
//    }
//    else
//    {
//        [commandEncoder setFragmentBytes:&kUnselectedColor
//                                  length:sizeof(kUnselectedColor)
//                                 atIndex:FSFI_DrawColor];
//    }
//    
//    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
//                       vertexStart:0
//                       vertexCount:kNumCircleVertices];
//    
//
//    
//    // Draw the outline
//    [commandEncoder setVertexBytes:outlineVertices
//                            length:sizeof(outlineVertices)
//                           atIndex:FSVI_Vertices];
//    
//    [commandEncoder setVertexBytes:&viewportSize
//                            length:sizeof(viewportSize)
//                           atIndex:FSVI_ViewportSize];
//    
//    [commandEncoder setFragmentBytes:&kOutlineColor
//                              length:sizeof(kOutlineColor)
//                             atIndex:FSFI_DrawColor];
//    
//    [commandEncoder drawPrimitives:MTLPrimitiveTypeLineStrip
//                       vertexStart:0
//                       vertexCount:kNumAngles + 1];
}

- (void)drawOSC:(FxImageTile*)destinationImage
 commandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
     activePart:(NSInteger)activePart
         atTime:(CMTime)time
{
    // Width and height of the canvas we're drawing to
    float   destImageWidth  = destinationImage.imagePixelBounds.right - destinationImage.imagePixelBounds.left;
    float   destImageHeight = destinationImage.imagePixelBounds.top - destinationImage.imagePixelBounds.bottom;
    
    // Because of Metal's Y-down orientation, we need to start at the top of the
    // viewport instead of the bottom.
    float   ioSurfaceHeight = [destinationImage.ioSurface height];
    MTLViewport viewport    = {
        0, ioSurfaceHeight - destImageHeight, destImageWidth, destImageHeight, -1.0, 1.0
    };
    [commandEncoder setViewport:viewport];
    
    
    [self drawCircleWithImageSize:NSMakeSize(destImageWidth, destImageHeight)
                   commandEncoder:commandEncoder
                       activePart:activePart
                           atTime:time];

}

- (void)drawOSCWithWidth:(NSInteger)width
                  height:(NSInteger)height
              activePart:(NSInteger)activePart
        destinationImage:(FxImageTile*)destinationImage
                  atTime:(CMTime)time
{
    // Set up our Metal command queue
    // Make a command buffer
    MetalDeviceCache*   deviceCache = [MetalDeviceCache deviceCache];
    id<MTLDevice>   gpuDevice = [deviceCache deviceWithRegistryID:destinationImage.deviceRegistryID];
    id<MTLCommandQueue> commandQueue    = [deviceCache commandQueueWithRegistryID:destinationImage.deviceRegistryID
                                                                      pixelFormat:MTLPixelFormatRGBA16Float];
    id<MTLCommandBuffer>    commandBuffer   = [commandQueue commandBuffer];
    commandBuffer.label = @"FxShapeOSC Command Buffer";
    [commandBuffer enqueue];
    
    // Setup the color attachment to draw to our output texture
    id<MTLTexture>  outputTexture   = [destinationImage metalTextureForDevice:gpuDevice];
    MTLRenderPassColorAttachmentDescriptor* colorAttachmentDescriptor   = [[MTLRenderPassColorAttachmentDescriptor alloc] init];
    colorAttachmentDescriptor.texture = outputTexture;
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    
    // Create a render pass descriptor and attach the color attachment to it
    MTLRenderPassDescriptor*    renderPassDescriptor    = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor;
    
    // Create the render command encoder
    id<MTLRenderCommandEncoder>   commandEncoder  = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Get the pipeline state that contains our fragment and vertex shaders
    id<MTLRenderPipelineState>  pipelineState = nil; //   = [deviceCache oscPipelineStateWithRegistryID:destinationImage.deviceRegistryID];
    [commandEncoder setRenderPipelineState:pipelineState];
    
    // Draw something here
    [self drawOSC:destinationImage
   commandEncoder:commandEncoder
       activePart:activePart
           atTime:time];
    
    // Clean up
    [commandEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilScheduled];
    
    [deviceCache returnCommandQueueToCache:commandQueue];
    
    [colorAttachmentDescriptor release];
}

- (void)hitTestOSCAtMousePositionX:(double)mousePositionX
                    mousePositionY:(double)mousePositionY
                        activePart:(NSInteger*)activePart
                            atTime:(CMTime)time;
{
    id<FxOnScreenControlAPI_v4>    oscAPI  = [apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    CGPoint objectPosition  = { 0.0, 0.0 };
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&objectPosition.x
                              toY:&objectPosition.y];
    
    id<FxParameterRetrievalAPI_v6>  paramAPI    = [apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    CGPoint ll  = { 0.0, 0.0 };
    CGPoint ur  = { 0.0, 0.0 };
    CGPoint cc  = { 0.0, 0.0 };
    double  circleRadius    = 0.0;
    
//    [paramAPI getXValue:&ll.x
//                 YValue:&ll.y
//          fromParameter:kLowerLeftID
//                 atTime:time];
//    
//    [paramAPI getXValue:&ur.x
//                 YValue:&ur.y
//          fromParameter:kUpperRightID
//                 atTime:time];
//    
//    [paramAPI getXValue:&cc.x
//                 YValue:&cc.y
//          fromParameter:kCircleCenter
//                 atTime:time];
//    
//    [paramAPI getFloatValue:&circleRadius
//              fromParameter:kCircleRadius
//                     atTime:time];
    
    NSRect  inputBounds = [oscAPI inputBounds];
    
    *activePart = 0;
    if ((ll.x <= objectPosition.x) && (objectPosition.x <= ur.x) &&
        (ll.y <= objectPosition.y) && (objectPosition.y <= ur.y))
    {
        *activePart = kFSPart_Rectangle;
    }
    else
    {
        double  objectRadius = circleRadius / inputBounds.size.width;
        
        CGPoint delta   = {
            objectPosition.x - cc.x,
            (objectPosition.y - cc.y) * inputBounds.size.height / inputBounds.size.width
        };
        double  dist    = sqrt(delta.x * delta.x + delta.y * delta.y);
        if (dist < objectRadius)
        {
            *activePart = kFSPart_Circle;
        }
    }
}

#pragma mark -
#pragma mark Key Events

- (void)keyDownAtPositionX:(double)mousePositionX
                 positionY:(double)mousePositionY
                keyPressed:(unsigned short)asciiKey
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                 didHandle:(BOOL *)didHandle
                    atTime:(CMTime)time
{
    *didHandle = NO;
}

- (void)keyUpAtPositionX:(double)mousePositionX
               positionY:(double)mousePositionY
              keyPressed:(unsigned short)asciiKey
               modifiers:(FxModifierKeys)modifiers
             forceUpdate:(BOOL *)forceUpdate
               didHandle:(BOOL *)didHandle
                  atTime:(CMTime)time
{
    *didHandle = NO;
}

#pragma mark -
#pragma mark Mouse Events

- (void)mouseDownAtPositionX:(double)mousePositionX
                   positionY:(double)mousePositionY
                  activePart:(NSInteger)activePart
                   modifiers:(FxModifierKeys)modifiers
                 forceUpdate:(BOOL *)forceUpdate
                      atTime:(CMTime)time
{
    id<FxOnScreenControlAPI_v4> oscAPI  = [apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    [lastPositionLock lock];
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&lastObjectPosition.x
                              toY:&lastObjectPosition.y];
    [lastPositionLock unlock];
    *forceUpdate = NO;
}

- (void)mouseDraggedAtPositionX:(double)mousePositionX
                      positionY:(double)mousePositionY
                     activePart:(NSInteger)activePart
                      modifiers:(FxModifierKeys)modifiers
                    forceUpdate:(BOOL *)forceUpdate
                         atTime:(CMTime)time
{
    id<FxOnScreenControlAPI_v4> oscAPI  = [apiManager apiForProtocol:@protocol(FxOnScreenControlAPI_v4)];
    CGPoint objectPos = { 0.0, 0.0 };
    [oscAPI convertPointFromSpace:kFxDrawingCoordinates_CANVAS
                            fromX:mousePositionX
                            fromY:mousePositionY
                          toSpace:kFxDrawingCoordinates_OBJECT
                              toX:&objectPos.x
                              toY:&objectPos.y];
    
    [lastPositionLock lock];
    CGPoint delta   = { objectPos.x - lastObjectPosition.x, objectPos.y - lastObjectPosition.y };
    lastObjectPosition = objectPos;
    [lastPositionLock unlock];
    
    id<FxParameterSettingAPI_v5>    paramSetAPI = [apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v5)];
    id<FxParameterRetrievalAPI_v6>  paramGetAPI = [apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];
    
    if (activePart == kFSPart_Rectangle)
    {
        CGPoint ll  = { 0.0, 0.0 };
        CGPoint ur  = { 0.0, 0.0 };
//        [paramGetAPI getXValue:&ll.x
//                        YValue:&ll.y
//                 fromParameter:kLowerLeftID
//                        atTime:time];
//        [paramGetAPI getXValue:&ur.x
//                        YValue:&ur.y
//                 fromParameter:kUpperRightID
//                        atTime:time];
        
        ll.x += delta.x;
        ll.y += delta.y;
        ur.x += delta.x;
        ur.y += delta.y;
        
//        [paramSetAPI setXValue:ll.x
//                        YValue:ll.y
//                   toParameter:kLowerLeftID
//                        atTime:time];
//        [paramSetAPI setXValue:ur.x
//                        YValue:ur.y
//                   toParameter:kUpperRightID
//                        atTime:time];
    }
    else if (activePart == kFSPart_Circle)
    {
        CGPoint cc  = { 0.0, 0.0 };
//        [paramGetAPI getXValue:&cc.x
//                        YValue:&cc.y
//                 fromParameter:kCircleCenter
//                        atTime:time];
        
        cc.x += delta.x;
        cc.y += delta.y;
        
//        [paramSetAPI setXValue:cc.x
//                        YValue:cc.y
//                   toParameter:kCircleCenter
//                        atTime:time];
    }
    
    *forceUpdate = YES;
}

- (void)mouseUpAtPositionX:(double)mousePositionX
                 positionY:(double)mousePositionY
                activePart:(NSInteger)activePart
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                    atTime:(CMTime)time
{
    [self mouseDraggedAtPositionX:mousePositionX
                        positionY:mousePositionY
                       activePart:activePart
                        modifiers:modifiers
                      forceUpdate:forceUpdate
                           atTime:time];
    
    [lastPositionLock lock];
    lastObjectPosition = CGPointMake(-1.0, -1.0);
    [lastPositionLock unlock];
}

#pragma mark -
#pragma mark Mouse Moved Events

- (void)mouseEnteredAtPositionX:(double)mousePositionX
                      positionY:(double)mousePositionY
                      modifiers:(FxModifierKeys)modifiers
                    forceUpdate:(BOOL *)forceUpdate
                         atTime:(CMTime)time
{
    // TODO: Put any mouse-entered handling code here
}

- (void)mouseMovedAtPositionX:(double)mousePositionX
                    positionY:(double)mousePositionY
                   activePart:(NSInteger)activePart
                    modifiers:(FxModifierKeys)modifiers
                  forceUpdate:(BOOL *)forceUpdate
                       atTime:(CMTime)time
{
    // TODO: Put any mouse-moved handling code here
}

- (void)mouseExitedAtPositionX:(double)mousePositionX
                     positionY:(double)mousePositionY
                     modifiers:(FxModifierKeys)modifiers
                   forceUpdate:(BOOL *)forceUpdate
                        atTime:(CMTime)time
{
    // TODO: Put any mouse-exited handling code here
}

@end
