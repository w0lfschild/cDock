#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include "constants.h"

extern DKDockSize DKDockSizeForIconSize(CGFloat iconSize);

@interface BlackDock : NSObject {
	CALayer *rootLayer;
	CALayer *floorLayer;
	CALayer *separatorLayer;
    CALayer *indicatorLayer;
    CALayer *tileLayer;
}

@property (retain) CALayer *rootLayer;
@property (retain) CALayer *floorLayer;
@property (retain) CALayer *separatorLayer;
@property (retain) CALayer *indicatorLayer;
@property (retain) CALayer *tileLayer;

+ (BlackDock *)sharedInstance;
- (void)setUp;

@end
