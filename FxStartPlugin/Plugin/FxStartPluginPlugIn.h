//
//  FxStartPluginPlugIn.h
//  FxStartPlugin
//
//  Created by Kacper  on 03/09/2024.
//

#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>
#import "ParameterFlags.h"

@interface FxStartPluginPlugIn : NSObject <FxTileableEffect>
@property (assign) id<PROAPIAccessing> apiManager;
@property (assign) NSArray* menuEntries;
@property (assign) NSArray* blurEntries;
@property (assign) NSArray* oscentries;
@property (assign) NSArray* specialEffectsEntries;
@end
