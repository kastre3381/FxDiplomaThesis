//
//  FxStartPluginPlugIn.h
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>

@interface FxStartPluginPlugIn : NSObject <FxTileableEffect>
@property (assign) id<PROAPIAccessing> apiManager;
@end
