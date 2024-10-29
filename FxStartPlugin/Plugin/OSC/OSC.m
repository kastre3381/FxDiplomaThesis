//
//  OSC.m
//  Wrapper Application
//
//  Created by Kacper  on 28/10/2024.
//

#import "OSC.h"
@implementation OSC
{
    NSLock* lock;
}

- (instancetype)initWithAPIManager:(id<PROAPIAccessing>)newAPIManager
{
    self = [super init];
    
    if (self != nil)
    {
        apiManager = newAPIManager;
        lock = [[NSLock alloc] init];
    }
    
    return self;
}

- (void) dealloc
{
    [lock release];
    [super dealloc];
}


- (void)drawOSCWithWidth:(NSInteger)width 
                  height:(NSInteger)height
              activePart:(NSInteger)activePart
        destinationImage:(FxImageTile *)destinationImage
                  atTime:(CMTime)time 
{
    
}

- (FxDrawingCoordinates)drawingCoordinates 
{
    return kFxDrawingCoordinates_CANVAS;
}

- (void)hitTestOSCAtMousePositionX:(double)mousePositionX 
                    mousePositionY:(double)mousePositionY
                        activePart:(NSInteger *)activePart
                            atTime:(CMTime)time
{
    
}

- (void)keyDownAtPositionX:(double)mousePositionX 
                 positionY:(double)mousePositionY
                keyPressed:(unsigned short)asciiKey
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                 didHandle:(BOOL *)didHandle
                    atTime:(CMTime)time
{
    
}

- (void)keyUpAtPositionX:(double)mousePositionX 
               positionY:(double)mousePositionY 
              keyPressed:(unsigned short)asciiKey
               modifiers:(FxModifierKeys)modifiers
             forceUpdate:(BOOL *)forceUpdate
               didHandle:(BOOL *)didHandle
                  atTime:(CMTime)time
{
    
}

- (void)mouseDownAtPositionX:(double)mousePositionX 
                   positionY:(double)mousePositionY
                  activePart:(NSInteger)activePart
                   modifiers:(FxModifierKeys)modifiers
                 forceUpdate:(BOOL *)forceUpdate
                      atTime:(CMTime)time
{
    
}

- (void)mouseDraggedAtPositionX:(double)mousePositionX 
                      positionY:(double)mousePositionY
                     activePart:(NSInteger)activePart
                      modifiers:(FxModifierKeys)modifiers
                    forceUpdate:(BOOL *)forceUpdate
                         atTime:(CMTime)time
{
    
}

- (void)mouseUpAtPositionX:(double)mousePositionX 
                 positionY:(double)mousePositionY
                activePart:(NSInteger)activePart
                 modifiers:(FxModifierKeys)modifiers
               forceUpdate:(BOOL *)forceUpdate
                    atTime:(CMTime)time
{
    
}

@end
