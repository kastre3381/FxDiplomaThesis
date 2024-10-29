//
//  OSC.h
//  Wrapper Application
//
//  Created by Kacper  on 28/10/2024.
//

#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>

@interface OSC : NSObject<FxOnScreenControl_v4>
{
    id<PROAPIAccessing> apiManager;
    CGPoint lastObjectPosition;
}
@end


