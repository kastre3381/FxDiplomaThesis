//
//  MetalDeviceCache.m
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#import "MetalDeviceCache.h"
#include <vector>
#include <map>


const NSUInteger    kMaxCommandQueues   = 50;
static NSString*    kKey_InUse          = @"InUse";
static NSString*    kKey_CommandQueue   = @"CommandQueue";

static MetalDeviceCache*   gDeviceCache    = nil;

@interface MetalDeviceCacheItem : NSObject

@property (readonly)    id<MTLDevice>                           gpuDevice;
@property (readonly)    std::map<PipelineTypes, id<MTLRenderPipelineState>> pipelines;
@property (retain)      NSMutableArray<NSMutableDictionary*>*   commandQueueCache;
@property (readonly)    NSLock*                                 commandQueueCacheLock;
@property (readonly)    MTLPixelFormat                          pixelFormat;

- (instancetype)initWithDevice:(id<MTLDevice>)device
                   pixelFormat:(MTLPixelFormat)pixFormat;
- (id<MTLCommandQueue>)getNextFreeCommandQueue;
- (void)returnCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (BOOL)containsCommandQueue:(id<MTLCommandQueue>)commandQueue;

@end

@implementation MetalDeviceCacheItem

- (instancetype)initWithDevice:(id<MTLDevice>)device
                   pixelFormat:(MTLPixelFormat)pixFormat;
{
    self = [super init];
    
    if (self != nil)
    {
        _gpuDevice = [device retain];
        
        _commandQueueCache = [[NSMutableArray alloc] initWithCapacity:kMaxCommandQueues];
        for (NSUInteger i = 0; (_commandQueueCache != nil) && (i < kMaxCommandQueues); i++)
        {
            NSMutableDictionary*   commandDict = [NSMutableDictionary dictionary];
            [commandDict setObject:[NSNumber numberWithBool:NO]
                            forKey:kKey_InUse];
            
            id<MTLCommandQueue> commandQueue    = [_gpuDevice newCommandQueue];
            [commandDict setObject:commandQueue
                            forKey:kKey_CommandQueue];
            
            [_commandQueueCache addObject:commandDict];
        }
        
        id<MTLLibrary> defaultLibrary = [[_gpuDevice newDefaultLibrary] autorelease];
        id<MTLFunction> vertexFunction = [[defaultLibrary newFunctionWithName:@"vertexShader"] autorelease];
        id<MTLFunction> fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentBrightnessShader"] autorelease];
        
        MTLRenderPipelineDescriptor *brightnessPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        brightnessPipelineStateDescriptor.label = @"Simple Pipeline";
        brightnessPipelineStateDescriptor.vertexFunction = vertexFunction;
        brightnessPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        brightnessPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        _pixelFormat = pixFormat;
        
        NSError*    error = nil;
        _pipelines[PT_Brightness] = [_gpuDevice newRenderPipelineStateWithDescriptor:brightnessPipelineStateDescriptor
                                                                              error:&error];

        
        if (error != nil)
        {
            NSLog (@"Error generating brightness pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentNegativeShader"] autorelease];
        
        MTLRenderPipelineDescriptor *negativePipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        negativePipelineStateDescriptor.label = @"Simple Pipeline";
        negativePipelineStateDescriptor.vertexFunction = vertexFunction;
        negativePipelineStateDescriptor.fragmentFunction = fragmentFunction;
        negativePipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_Negative] = [_gpuDevice newRenderPipelineStateWithDescriptor:negativePipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentGaussianBlurShader"] autorelease];
        
        MTLRenderPipelineDescriptor *gaussianBlurPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        gaussianBlurPipelineStateDescriptor.label = @"Simple Pipeline";
        gaussianBlurPipelineStateDescriptor.vertexFunction = vertexFunction;
        gaussianBlurPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        gaussianBlurPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_GaussianBlur] = [_gpuDevice newRenderPipelineStateWithDescriptor:gaussianBlurPipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentKawaseBlurShader"] autorelease];
        
        MTLRenderPipelineDescriptor *kawaseBlurPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        kawaseBlurPipelineStateDescriptor.label = @"Simple Pipeline";
        kawaseBlurPipelineStateDescriptor.vertexFunction = vertexFunction;
        kawaseBlurPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        kawaseBlurPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_KawaseBlur] = [_gpuDevice newRenderPipelineStateWithDescriptor:kawaseBlurPipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentBoxBlurShader"] autorelease];
        
        MTLRenderPipelineDescriptor *boxBlurPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        boxBlurPipelineStateDescriptor.label = @"Simple Pipeline";
        boxBlurPipelineStateDescriptor.vertexFunction = vertexFunction;
        boxBlurPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        boxBlurPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_BoxBlur] = [_gpuDevice newRenderPipelineStateWithDescriptor:boxBlurPipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentDefaultShader"] autorelease];
        
        MTLRenderPipelineDescriptor *defaultPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        defaultPipelineStateDescriptor.label = @"Simple Pipeline";
        defaultPipelineStateDescriptor.vertexFunction = vertexFunction;
        defaultPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        defaultPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_None] = [_gpuDevice newRenderPipelineStateWithDescriptor:defaultPipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        
        fragmentFunction = [[defaultLibrary newFunctionWithName:@"fragmentOilPaintingShader"] autorelease];
        
        MTLRenderPipelineDescriptor *oilPaintingPipelineStateDescriptor = [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
        oilPaintingPipelineStateDescriptor.label = @"Simple Pipeline";
        oilPaintingPipelineStateDescriptor.vertexFunction = vertexFunction;
        oilPaintingPipelineStateDescriptor.fragmentFunction = fragmentFunction;
        oilPaintingPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixFormat;
        
        error = nil;
        _pipelines[PT_OilPainting] = [_gpuDevice newRenderPipelineStateWithDescriptor:oilPaintingPipelineStateDescriptor
                                                                              error:&error];
        
        if (error != nil)
        {
            NSLog (@"Error generating negative pipeline state: %@", error);
        }
        
        
        if (_commandQueueCache != nil)
        {
            _commandQueueCacheLock = [[NSLock alloc] init];
        }
        
        if ((_gpuDevice == nil) || (_commandQueueCache == nil) || (_commandQueueCacheLock == nil)
            || (_pipelines[PT_Brightness] == nil) || (_pipelines[PT_Negative] == nil) 
            || (_pipelines[PT_GaussianBlur] == nil) || (_pipelines[PT_None] == nil)
            || (_pipelines[PT_KawaseBlur] == nil) || (_pipelines[PT_BoxBlur] == nil)
            || (_pipelines[PT_OilPainting] == nil))
        {
            NSLog (@"tu nie dziala %@", error);
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_gpuDevice release];
    [_commandQueueCache release];
    [_commandQueueCacheLock release];
    for(auto && [key, val]: _pipelines)
        [_pipelines[key] release];
    
    
    [super dealloc];
}

- (id<MTLCommandQueue>)getNextFreeCommandQueue
{
    id<MTLCommandQueue> result  = nil;
    
    [_commandQueueCacheLock lock];
    NSUInteger  index   = 0;
    while ((result == nil) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueue    = [_commandQueueCache objectAtIndex:index];
        NSNumber*               inUse               = [nextCommandQueue objectForKey:kKey_InUse];
        if (![inUse boolValue])
        {
            [nextCommandQueue setObject:[NSNumber numberWithBool:YES]
                                 forKey:kKey_InUse];
            result = [nextCommandQueue objectForKey:kKey_CommandQueue];
        }
        index++;
    }
    [_commandQueueCacheLock unlock];
    
    return result;
}

- (void)returnCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    [_commandQueueCacheLock lock];
    
    BOOL        found   = false;
    NSUInteger  index   = 0;
    while ((!found) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueuDict = [_commandQueueCache objectAtIndex:index];
        id<MTLCommandQueue>     nextCommandQueue    = [nextCommandQueuDict objectForKey:kKey_CommandQueue];
        if (nextCommandQueue == commandQueue)
        {
            found = YES;
            [nextCommandQueuDict setObject:[NSNumber numberWithBool:NO]
                                    forKey:kKey_InUse];
        }
        index++;
    }
    
    [_commandQueueCacheLock unlock];
}

- (BOOL)containsCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    BOOL        found   = NO;
    NSUInteger  index   = 0;
    while ((!found) && (index < kMaxCommandQueues))
    {
        NSMutableDictionary*    nextCommandQueuDict = [_commandQueueCache objectAtIndex:index];
        id<MTLCommandQueue>     nextCommandQueue    = [nextCommandQueuDict objectForKey:kKey_CommandQueue];
        if (nextCommandQueue == commandQueue)
        {
            found = YES;
        }
        index++;
    }
    
    return found;
}

@end

@implementation MetalDeviceCache

+ (MTLPixelFormat)MTLPixelFormatForImageTile:(FxImageTile*)imageTile
{
    MTLPixelFormat  result  = MTLPixelFormatRGBA16Float;
    
    switch (imageTile.ioSurface.pixelFormat)
    {
        case kCVPixelFormatType_128RGBAFloat:
            result = MTLPixelFormatRGBA32Float;
            break;
            
        case kCVPixelFormatType_32BGRA:
            result = MTLPixelFormatBGRA8Unorm;
            break;
            
        default:
            break;
    }
    
    return result;
}

+ (MetalDeviceCache*)deviceCache;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gDeviceCache = [[MetalDeviceCache alloc] init];
    });
    
    return gDeviceCache;
}

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
        
        deviceCaches = [[NSMutableArray alloc] initWithCapacity:devices.count];
        
        for (id<MTLDevice> nextDevice in devices)
        {
            MetalDeviceCacheItem*  newCacheItem    = [[[MetalDeviceCacheItem alloc] initWithDevice:nextDevice
                                                                                       pixelFormat:MTLPixelFormatRGBA16Float]
                                                      autorelease];
            [deviceCaches addObject:newCacheItem];
        }
        
        [devices release];
    }
    
    return self;
}

- (void)dealloc
{
    [deviceCaches release];
    
    [super dealloc];
}

- (id<MTLDevice>)deviceWithRegistryID:(uint64_t)registryID
{
    for (MetalDeviceCacheItem* nextCacheItem in deviceCaches)
    {
        if (nextCacheItem.gpuDevice.registryID == registryID)
        {
            return nextCacheItem.gpuDevice;
        }
    }
    
    return nil;
}

- (id<MTLRenderPipelineState>)pipelineStateWithRegistryID:(uint64_t)registryID
                                              pixelFormat:(MTLPixelFormat)pixFormat
                                             pipelineType:(PipelineTypes)pipType;
{
    for (MetalDeviceCacheItem* nextCacheItem in deviceCaches)
    {
        if ((nextCacheItem.gpuDevice.registryID == registryID)  &&
            (nextCacheItem.pixelFormat == pixFormat))
        {
            switch (pipType) {
                case PT_Brightness:
                    return nextCacheItem.pipelines[PT_Brightness];
                    break;
                    
                case PT_Negative:
                    return nextCacheItem.pipelines[PT_Negative];
                    break;
                    
                case PT_GaussianBlur:
                    return nextCacheItem.pipelines[PT_GaussianBlur];
                    break;
                    
                case PT_KawaseBlur:
                    return nextCacheItem.pipelines[PT_KawaseBlur];
                    break;
                    
                case PT_BoxBlur:
                    return nextCacheItem.pipelines[PT_BoxBlur];
                    break;
                    
                case PT_None:
                    return nextCacheItem.pipelines[PT_None];
                    break;
                    
                case PT_OilPainting:
                    return nextCacheItem.pipelines[PT_OilPainting];
                    break;
                    
                default:
                    break;
            }
        }
    }
    // Didn't find one, so create one with the right settings
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
    id<MTLDevice>   device  = nil;
    for (id<MTLDevice> nextDevice in devices)
    {
        if (nextDevice.registryID == registryID)
        {
            device = nextDevice;
        }
    }
    
    id<MTLRenderPipelineState>  result  = nil;
    if (device != nil)
    {
        MetalDeviceCacheItem*   newCacheItem    = [[[MetalDeviceCacheItem alloc] initWithDevice:device
                                                                                    pixelFormat:pixFormat]
                                                    autorelease];
        if (newCacheItem != nil)
        {
            [deviceCaches addObject:newCacheItem];
            
            switch (pipType) {
                case PT_Brightness:
                    result = newCacheItem.pipelines[PT_Brightness];
                    break;
                    
                case PT_Negative:
                    return newCacheItem.pipelines[PT_Negative];
                    break;
                    
                case PT_GaussianBlur:
                    return newCacheItem.pipelines[PT_GaussianBlur];
                    break;
                    
                case PT_KawaseBlur:
                    return newCacheItem.pipelines[PT_KawaseBlur];
                    break;
                    
                case PT_BoxBlur:
                    return newCacheItem.pipelines[PT_BoxBlur];
                    break;
                    
                case PT_None:
                    return newCacheItem.pipelines[PT_None];
                    break;
                    
                case PT_OilPainting:
                    return newCacheItem.pipelines[PT_OilPainting];
                    break;
                    
                default:
                    break;
            }
        }
    }
    [devices release];
    return result;
}

- (id<MTLCommandQueue>)commandQueueWithRegistryID:(uint64_t)registryID
                                      pixelFormat:(MTLPixelFormat)pixFormat;
{
    for (MetalDeviceCacheItem* nextCacheItem in deviceCaches)
    {
        if ((nextCacheItem.gpuDevice.registryID == registryID) &&
            (nextCacheItem.pixelFormat == pixFormat))
        {
            return [nextCacheItem getNextFreeCommandQueue];
        }
    }
    
    // Didn't find one, so create one with the right settings
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
    id<MTLDevice>   device  = nil;
    for (id<MTLDevice> nextDevice in devices)
    {
        if (nextDevice.registryID == registryID)
        {
            device = nextDevice;
        }
    }
    
    id<MTLCommandQueue>  result  = nil;
    if (device != nil)
    {
        MetalDeviceCacheItem*   newCacheItem    = [[[MetalDeviceCacheItem alloc] initWithDevice:device
                                                                                    pixelFormat:pixFormat]
                                                   autorelease];
        if (newCacheItem != nil)
        {
            [deviceCaches addObject:newCacheItem];
            result = [newCacheItem getNextFreeCommandQueue];
        }
    }
    [devices release];
    return result;
}

- (void)returnCommandQueueToCache:(id<MTLCommandQueue>)commandQueue;
{
    for (MetalDeviceCacheItem* nextCacheItem in deviceCaches)
    {
        if ([nextCacheItem containsCommandQueue:commandQueue])
        {
            [nextCacheItem returnCommandQueue:commandQueue];
            break;
        }
    }
}

@end