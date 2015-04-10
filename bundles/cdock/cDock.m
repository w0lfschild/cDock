//
//  cDock.m
//  cDock
//
//  Created by Wolfgang Baird
//  Copyright (c) 2015 Wolfgang Baird. All rights reserved.
//
//  Based on work by
//
//  Adam Bell       - darkdock
//  cvz             - blackdock
//  Alex Zielenski  - dockify
//

// imports
#import "cDock.h"
#import "fishhook.h"
#import "ZKSwizzle.h"
#import "constants.h"
#import <objc/objc-class.h>
#import <dlfcn.h>

// includes
#include <stdlib.h>

extern DKDockSize DKDockSizeForIconSize(CGFloat iconSize) {
    if (iconSize <= 44) {
        return DKDockSizeSmall;
    } else if (iconSize <= 72) {
        return DKDockSizeMedium;
    } else if (iconSize <= 100) {
        return DKDockSizeLarge;
    }
    return DKDockSizeExtraLarge;
}

void SwizzleInstanceMethod (Class cls, SEL old, SEL new) {
	Method mold = class_getInstanceMethod(cls, old);
	Method mnew = class_getInstanceMethod(cls, new);
	if (mold && mnew) {
		if (class_addMethod(cls, old, method_getImplementation(mold), method_getTypeEncoding(mold))) {
			mold = class_getInstanceMethod(cls, old);
		}
		if (class_addMethod(cls, new, method_getImplementation(mnew), method_getTypeEncoding(mnew))) {
			mnew = class_getInstanceMethod(cls, new);
		}
		method_exchangeImplementations(mold, mnew);
	}
}

void errorReport (NSArray* test) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *docFile = [NSString stringWithFormat:@"%@/test_info.txt", docDir];
    NSString *mystr = [NSString stringWithFormat:@"%lu",[test count]];
    [mystr writeToFile:docFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

void printSTR (NSString* test) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *docFile = [NSString stringWithFormat:@"%@/test_info.txt", docDir];
    [test writeToFile:docFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

NSArray* readPrefs (void) {
    NSString *current_theme = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"org.w0lf.cDock"] objectForKey: @"theme"];
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *myFile = [[NSArray arrayWithObjects:appSupport, @"cDock/themes", current_theme, @"settings.txt", nil] componentsJoinedByString:@"/"];
    NSString *contents = [NSString stringWithContentsOfFile:myFile encoding:NSUTF8StringEncoding error:NULL];
    NSArray *processed = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return processed;
}

NSImage* getImg (NSString* item) {
    NSString *current_theme = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"org.w0lf.cDock"] objectForKey: @"theme"];
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imageFile = [[NSArray arrayWithObjects:appSupport, @"cDock/themes", current_theme, item, nil] componentsJoinedByString:@"/"];
    NSImage *newImage = [[[NSImage alloc] initWithContentsOfFile:imageFile] autorelease];
    return newImage;
}

int validateInt (NSArray* arr, int check) {
    if ([arr count] > check) return [arr[check] integerValue];
    return 0;
}

CGFloat validateFloat (NSArray* arr, int check, CGFloat div) {
    if ([arr count] > check) return ([arr[check] integerValue] / div);
    return 0.0;
}

@interface BlackDockIndicatorLayer : CALayer
@end

@implementation BlackDockIndicatorLayer

- (void)resizeWithOldSuperlayerSize:(CGSize)size
{
    self.backgroundColor = NSColor.clearColor.CGColor;
    self.cornerRadius = 0.0;

    NSImage *image = getImg(@"test.png");
    NSImageRep *rep = [[image representations] objectAtIndex:0];

    self.contents = (__bridge id)image;
    self.contentsGravity = kCAGravityBottom;
    self.frame = CGRectMake(self.frame.origin.x, 0, rep.pixelsWide / self.contentsScale, rep.pixelsHigh / self.contentsScale);
}
    
@end

@interface BlackDockBorderLayer : CALayer
@end

@implementation BlackDockBorderLayer

- (void)resizeWithOldSuperlayerSize:(CGSize)size
{
    NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSArray *my_settings = readPrefs();
    CALayer *layer = self.superlayer;
    if (layer) {
        NSInteger orientation;
        if (object_getInstanceVariable(layer, "_orientation", (void **)&orientation)) {
            CGRect rect = layer.bounds;
            // 0:bottom, 1:left, 2:right
            if (orientation == 0) {
                if (osver.minorVersion < 10) {
                    rect.size.height *= 1.65;
                    rect.size.height += self.cornerRadius;
                    rect.size.height += self.borderWidth * 2;
                    if (self.cornerRadius == 0)
                        rect.size.height += 2;
                    rect.size.width += -18.00;
                    rect.size.width += self.borderWidth * 2;
                    rect.origin.y -= self.borderWidth;
                    rect.origin.y -= self.cornerRadius;
                    rect.origin.x += 10 - self.borderWidth;
                } else {
                    rect.size.height += self.cornerRadius;
                    rect.size.height += self.borderWidth * 2;
                    rect.size.width += self.borderWidth * 2;
                    rect.origin.y -= self.borderWidth;
                    rect.origin.y -= self.cornerRadius;
                }
                
                // Test
                if (validateInt(my_settings, 21) == 1) {
                    int _swidth = [[NSScreen mainScreen] frame].size.width + 500;
                    int _shift = (_swidth / 2) - (rect.size.width / 2);
                    rect.size.width = _swidth;
                    rect.origin.x = 0;
                    rect.origin.x -= _shift;
                    rect.origin.x -= self.borderWidth;
                }
                // Test
                
            } else {
                rect.size.height += self.borderWidth * 2;
                rect.size.width += self.cornerRadius;
                rect.size.width += self.borderWidth * 2;
                rect.origin.y -= self.borderWidth;
                //Left
                if (orientation == 1) {
                    rect.origin.x -= self.cornerRadius;
                    rect.origin.x -= self.borderWidth;
                }
                //Right
                if (orientation == 2)
                    rect.origin.x -= self.borderWidth;
                
                // Test
                if (validateInt(my_settings, 21) == 1) {
                    int _sheight = [[NSScreen mainScreen] frame].size.height + 500;
                    int _shift = (_sheight / 2) - (rect.size.height / 2);
                    rect.size.height = _sheight;
                    rect.origin.y = 0;
                    rect.origin.y -= _shift;
                }
                // Test
            }
            // User defined position adjustment
            rect.size.width += validateInt(my_settings, 14);
            rect.size.height += validateInt(my_settings, 15);
            rect.origin.x += validateInt(my_settings, 16);
            rect.origin.y += validateInt(my_settings, 17);
            self.frame = rect;
        }
    }
}

+ (id)layer
{
    CALayer *layer = [super layer];
    NSArray *my_settings = readPrefs();
    CGColorRef color;
    // Corner radius:
    layer.cornerRadius = validateFloat(my_settings, 8, 1.);
    // Background
    layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRelease(color);
    
    // Border
    color = CGColorCreateGenericRGB(validateFloat(my_settings, 4, 255.), validateFloat(my_settings, 5, 255.), validateFloat(my_settings, 6, 255.), validateFloat(my_settings, 7, 100.));
    layer.borderColor = color;
    CGColorRelease(color);
    // Width of border:
    layer.borderWidth = validateFloat(my_settings, 9, 1.);
    // Shadows:
    layer.masksToBounds = NO;
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowRadius = validateFloat(my_settings, 10, 1.);
    layer.shadowOpacity = validateFloat(my_settings, 11, 100.);
    return layer;
}

@end

@interface BlackDockSeparatorLayer : CALayer

@end

@implementation BlackDockSeparatorLayer

+ (id)layer
{
	CALayer *layer = [super layer];
	layer.contents = getImg(@"separator.png");
	layer.contentsGravity = kCAGravityResizeAspect;
	return layer;
}

- (void)resizeWithOldSuperlayerSize:(CGSize)size
{
    CGRect rect = self.superlayer.frame;
	rect.origin.x = 2;
	rect.origin.y *= -1;
	CALayer *floorLayer = [[BlackDock sharedInstance] floorLayer];
	rect.size.height = [floorLayer frame].size.height - floorLayer.cornerRadius;
	self.frame = rect;
}

@end

@interface BlackDockFloorLayer : CALayer
@end

@implementation BlackDockFloorLayer

- (void)resizeWithOldSuperlayerSize:(CGSize)size
{
    NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSArray *my_settings = readPrefs();
    CALayer *layer = self.superlayer;
    
    if (layer) {
        NSInteger orientation;
        if (object_getInstanceVariable(layer, "_orientation", (void **)&orientation)) {
            CGRect rect = layer.bounds;
            // 0:bottom, 1:left, 2:right
            if (orientation == 0) {
                if (osver.minorVersion < 10) {
                    rect.size.height *= 1.65;
                    rect.size.height += self.cornerRadius;
                    rect.size.height += self.borderWidth * 2;
                    if (self.cornerRadius == 0)
                        rect.size.height += 2;
                    rect.size.width += -18.00;
                    if (osver.minorVersion < 10)
                        rect.size.width += self.borderWidth * 2;
                    rect.origin.y -= self.borderWidth * 2;
                    rect.origin.y -= self.cornerRadius;
                    rect.origin.x += 10;
                    if (osver.minorVersion < 10)
                        rect.origin.x -= self.borderWidth;
                } else {
                    // 3D dock only
                    if (validateInt(my_settings, 19) == 1)
                    {
                        rect.size.width += rect.size.width/50;
                        rect.origin.x -= (rect.size.width/50)/2;
                    }
                    
                    rect.size.height += self.cornerRadius;
                    rect.origin.y -= self.cornerRadius;
                    rect.origin.x += self.borderWidth;
                }
                //Fill Screen
                if (validateInt(my_settings, 21) == 1) {
                    int _swidth = [[NSScreen mainScreen] frame].size.width + 500;
                    int _shift = (_swidth / 2) - (rect.size.width / 2);
                    rect.size.width = _swidth;
                    rect.origin.x = 0;
                    rect.origin.x -= _shift;
                }
            } else {
                if (osver.minorVersion < 10) {
                    rect.size.height += self.borderWidth * 2;
                    rect.origin.y -= self.borderWidth;
                }
                rect.size.width += self.cornerRadius;
                rect.size.width += self.borderWidth * 2;
                //Left
                if (orientation == 1) {
                    if (osver.minorVersion >= 10)
                        rect.origin.x -= self.borderWidth;
                    rect.origin.x -= self.cornerRadius;
                    rect.origin.x -= self.borderWidth;
                }
                //Right
                if (orientation == 2)
                    if (osver.minorVersion < 10)
                        rect.origin.x -= self.borderWidth;
                //Fill Screen
                if (validateInt(my_settings, 21) == 1) {
                    int _sheight = [[NSScreen mainScreen] frame].size.height + 500;
                    int _shift = (_sheight / 2) - (rect.size.height / 2);
                    rect.size.height = _sheight;
                    rect.origin.y = 0;
                    rect.origin.y -= _shift;
                }
            }
            // User defined position adjustment
            rect.size.width += validateInt(my_settings, 14);
            rect.size.height += validateInt(my_settings, 15);
            rect.origin.x += validateInt(my_settings, 16);
            rect.origin.y += validateInt(my_settings, 17);
            self.frame = rect;
            
            // Coloring
            NSInteger orientation = 0;
            NSInteger nada = 0;
            if (layer)
                if (object_getInstanceVariable(layer, "_orientation", (void **)&orientation))
                    nada=69;
                    
            //CGRect rect = layer.bounds;
            NSArray *my_settings = readPrefs();
            NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
            int picture= validateInt(my_settings, 12);
            // Corner radius:
            CGFloat cr = validateFloat(my_settings, 8, 1.);
            if (cr > 2.0)
                self.cornerRadius = validateFloat(my_settings, 8, 1.) - 2.0;
            else
                self.cornerRadius = validateFloat(my_settings, 8, 1.);
            // Background
            if (validateInt(my_settings, 19) == 1) {
                if (orientation == 0)
                    self.contents = getImg(@"3D.png");
                    self.opacity = validateFloat(my_settings, 13, 100.);
            } else {
                if (picture == 0){
                    self.backgroundColor = CGColorCreateGenericRGB(validateFloat(my_settings, 0, 255.), validateFloat(my_settings, 1, 255.), validateFloat(my_settings, 2, 255.), validateFloat(my_settings, 3, 100.));
                } else {
                    if (validateInt(my_settings, 20) == 0) {
                        self.contents = getImg(@"background.png");
                        self.contentsGravity = kCAGravityResize;
                        //self.contentsGravity = kCAGravityResizeAspect;
                    } else {
                        self.backgroundColor = [[NSColor colorWithPatternImage:getImg(@"background.png")] CGColor];
                    }
                    self.opacity = validateFloat(my_settings, 13, 100.);
                }
            }
            // Border
            if (osver.minorVersion < 10) {
                self.borderColor = CGColorCreateGenericRGB(validateFloat(my_settings, 4, 255.), validateFloat(my_settings, 5, 255.), validateFloat(my_settings, 6, 255.), validateFloat(my_settings, 7, 100.));
                self.borderWidth = validateFloat(my_settings, 9, 1.);
                self.masksToBounds = NO;
                self.shadowOffset = CGSizeMake(0, 0);
                self.shadowRadius = validateFloat(my_settings, 10, 1.);
                self.shadowOpacity = validateFloat(my_settings, 11, 100.);
            } else {
                self.borderColor = CGColorCreateGenericGray(0.0, 0.0);
                self.borderWidth = validateFloat(my_settings, 9, 1.);
            }
        }
    }
}

+ (id)layer
{
    CALayer *layer = [super layer];
	return layer;
}

@end

@implementation CALayer (DKIndicatorLayer)

- (void)CDupdateIndicatorForSize:(float)arg1 {
    [self CDupdateIndicatorForSize:arg1];
    
    Class cls = NSClassFromString(@"DOCKIndicatorLayer");
    SEL old = @selector(updateIndicatorForSize:);
    SEL new = @selector(CDupdateIndicatorForSize:);
    SwizzleInstanceMethod(cls, old, new);
    
    self.backgroundColor = NSColor.clearColor.CGColor;
    self.cornerRadius = 0.0;
    
    //DKDockSize size = DKDockSizeForIconSize(arg1);
    NSImage *image = getImg(@"test.png");
    NSImageRep *rep = [[image representations] objectAtIndex:0];
    //NSSize imageSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    
    self.contents = (__bridge id)image;
    self.contentsGravity = kCAGravityBottom;
    self.frame = CGRectMake(self.frame.origin.x, 0, rep.pixelsWide / self.contentsScale, rep.pixelsHigh / self.contentsScale);
}

@end

@implementation NSObject (BlackDock)

- (void)BlackDock_DOCKTileLayer_createShadowAndReflectionLayers
{
    //do nothing
}

- (void)BlackDock_DOCKFloorLayer_setGlobalSeparatorPosition:(double)arg1
{
	[self BlackDock_DOCKFloorLayer_setGlobalSeparatorPosition:arg1];
	
	Class cls = NSClassFromString(@"DOCKFloorLayer");
	SEL old = @selector(setGlobalSeparatorPosition:);
	SEL new = @selector(BlackDock_DOCKFloorLayer_setGlobalSeparatorPosition:);
	SwizzleInstanceMethod(cls, old, new);
	
	BlackDock *blackDock = [BlackDock sharedInstance];
	if (!blackDock.rootLayer) {
		blackDock.rootLayer = [(id)self superlayer];
		[blackDock performSelectorOnMainThread:@selector(setUp) withObject:nil waitUntilDone:NO];
	}
}

@end

@implementation BlackDock

@synthesize rootLayer;
@synthesize floorLayer;
@synthesize separatorLayer;
@synthesize tileLayer;
@synthesize indicatorLayer;

static id (*orig_CFPreferencesCopyAppValue)(CFStringRef key, CFStringRef applicationID);

id hax_CFPreferencesCopyAppValue(CFStringRef key, CFStringRef applicationID) {
    NSArray *my_settings = readPrefs();
    if ([(__bridge NSString *)key isEqualToString:@"AppleInterfaceTheme"] || [(__bridge NSString *)key isEqualToString:@"AppleInterfaceStyle"]) {
        if (validateInt(my_settings, 18) == 1)
            return @"Dark";
        else
            return @"Light";
    } else {
        return orig_CFPreferencesCopyAppValue(key, applicationID);
    }
}

+ (void)load
{
	Class cls = NSClassFromString(@"DOCKFloorLayer");
	SEL old = @selector(setGlobalSeparatorPosition:);
	SEL new = @selector(BlackDock_DOCKFloorLayer_setGlobalSeparatorPosition:);
	SwizzleInstanceMethod(cls, old, new);
	
	cls = NSClassFromString(@"DOCKPreferences");
	id dockPref = nil;
	SEL aSel = @selector(preferences);
	if ([cls respondsToSelector:aSel]) {
		dockPref = [cls performSelector:aSel];
	}
	if (dockPref) {
		NSString *key = @"showProcessIndicatorsPref";
		id val = [dockPref valueForKey:key];
		if (val) {
			[dockPref setValue:[NSNumber numberWithBool:![val boolValue]] forKey:key];
			[dockPref setValue:val forKey:key];
		}
	}
}

+ (BlackDock *)sharedInstance
{
	static BlackDock *blackDock = nil;
	if (!blackDock) {
		blackDock = [self new];
		[[NSUserDefaults standardUserDefaults] addObserver:blackDock forKeyPath:@"orientation" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return blackDock;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"orientation"]) {
		if (self.floorLayer.superlayer) {
			[self.floorLayer resizeWithOldSuperlayerSize:CGSizeZero];
		} else {
			[self setUp];
		}
	}
}

- (void)setUp
{
    CALayer *layer = self.rootLayer;
    NSArray *arr = layer.sublayers;
    NSArray *my_settings = readPrefs();
    NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (osver.majorVersion >= 10) {
        if (osver.minorVersion >= 10) {
            orig_CFPreferencesCopyAppValue = dlsym(RTLD_DEFAULT, "CFPreferencesCopyAppValue");
            rebind_symbols((struct rebinding[1]){{"CFPreferencesCopyAppValue", hax_CFPreferencesCopyAppValue}}, 1);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("AppleInterfaceThemeChangedNotification"), (void *)0x1, NULL, YES);
            });
            
            CALayer *floor_backup = [BlackDockFloorLayer layer];
            CALayer *border_backup = [BlackDockBorderLayer layer];
            
            Class dockFloorLayer = NSClassFromString(@"DOCKFloorLayer");
            for (layer in arr)
                if ([layer isKindOfClass:dockFloorLayer])
                    break;
            
            CALayer *separator;
            if (object_getInstanceVariable(layer, "_separatorLayer", (void **)&separator))
                separator.contents = nil;
            
            layer.sublayers = nil;
            
            [layer addSublayer:floor_backup];
            [layer addSublayer:border_backup];
            
            if (validateInt(my_settings, 22) == 1) [layer addSublayer:separator];
            
            [floor_backup resizeWithOldSuperlayerSize:CGSizeZero];
            [border_backup resizeWithOldSuperlayerSize:CGSizeZero];
            [separator resizeWithOldSuperlayerSize:CGSizeZero];
        }
        if (osver.minorVersion < 10) {
            if (!self.floorLayer) {
                self.floorLayer = [BlackDockFloorLayer layer];
                self.separatorLayer = [BlackDockSeparatorLayer layer];
                
                SEL aSel = @selector(removeShadowAndReflectionLayers);
                NSArray *tileLayers = [arr filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
                    return [evaluatedObject respondsToSelector:aSel];
                }]];
                [tileLayers makeObjectsPerformSelector:aSel];
                
                SEL bSel = @selector(removeIndicator);
                NSArray *indicatorLayers = [arr filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
                    return [evaluatedObject respondsToSelector:bSel];
                }]];
                [indicatorLayers makeObjectsPerformSelector:bSel];
                
                arr = layer.sublayers;
                
                Class cls = NSClassFromString(@"DOCKTileLayer");
                SEL old = @selector(createShadowAndReflectionLayers);
                SEL new = @selector(BlackDock_DOCKTileLayer_createShadowAndReflectionLayers);
                SwizzleInstanceMethod(cls, old, new);
            }
            Class dockFloorLayer = NSClassFromString(@"DOCKFloorLayer");
            for (layer in arr) {
                if ([layer isKindOfClass:dockFloorLayer]) {
                    break;
                }
            }
            if (layer) {
                BOOL flag;
                if (object_getInstanceVariable(layer, "_dontEverShowMirror", (void **)&flag)) {
                    if (!flag) {
                        object_setInstanceVariable(layer, "_dontEverShowMirror", (void *)YES);
                        SEL aSel = @selector(turnMirrorOff);
                        if ([layer respondsToSelector:aSel]) {
                            [layer performSelector:aSel];
                            [layer addSublayer:self.floorLayer];
                            [self.floorLayer resizeWithOldSuperlayerSize:CGSizeZero];
                            NSInteger orientation;
                            if (object_getInstanceVariable(layer, "_orientation", (void **)&orientation)) {
                                // 0:bottom, 1:left, 2:right
                                if (orientation == 0) {
                                    CALayer *separator;
                                    if (object_getInstanceVariable(layer, "_separatorLayer", (void **)&separator)) {
                                        [separator addSublayer:self.separatorLayer];
                                        [self.separatorLayer resizeWithOldSuperlayerSize:CGSizeZero];
                                        separator.contents = nil;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
