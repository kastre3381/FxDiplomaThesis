#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import <Metal/Metal.h>

@interface OSC : NSObject <FxOnScreenControl_v4>
{
    id<PROAPIAccessing> apiManager;
    
    CGPoint lastObjectPosition;
}

@end
