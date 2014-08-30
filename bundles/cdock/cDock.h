#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface BlackDock : NSObject {
	CALayer *rootLayer;
	CALayer *floorLayer;
	CALayer *separatorLayer;
}

@property (retain) CALayer *rootLayer;
@property (retain) CALayer *floorLayer;
@property (retain) CALayer *separatorLayer;

+ (BlackDock *)sharedInstance;
- (void)setUp;

@end
