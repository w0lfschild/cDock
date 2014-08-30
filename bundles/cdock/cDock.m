//
//  cDock.m
//  cDock
//
//  Created by Wolfgang Baird
//  Copyright (c) 2014 Wolfgang Baird. All rights reserved.
//
//  Based on work by
//
//  Adam Bell - darkdock
//  cvz - blackdock
//

// imports
#import "cDock.h"
#import "fishhook.h"
#import <objc/objc-class.h>
#import <dlfcn.h>

// includes
#include <stdlib.h>

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

NSArray* readPrefs (void) {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    appSupport = [appSupport stringByAppendingPathComponent: @"cDock"];
    NSString *prefsPath = [appSupport stringByAppendingPathComponent:@"settings.plist"];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile: prefsPath];
    
    NSString *myFile = [appSupport stringByAppendingPathComponent: @"/themes/"];
    myFile = [myFile stringByAppendingPathComponent:[prefs objectForKey: @"theme"]];
    myFile = [myFile stringByAppendingPathComponent: @"/settings.txt"];
    
    NSString *contents = [NSString stringWithContentsOfFile:myFile encoding:NSUTF8StringEncoding error:NULL];
    NSArray *processed = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    //NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //NSString *settingFile = [NSString stringWithFormat:@"%@/cDock/dock_settings.txt", appSupport];
    //NSString *contents = [NSString stringWithContentsOfFile:settingFile encoding:NSUTF8StringEncoding error:NULL];
    //NSArray *processed = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return processed;
}

NSImage* getImg (NSString* item) {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    appSupport = [appSupport stringByAppendingPathComponent: @"cDock"];
    NSString *prefsPath = [appSupport stringByAppendingPathComponent:@"settings.plist"];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile: prefsPath];
    
    NSString *myFile = [appSupport stringByAppendingPathComponent: @"/themes/"];
    myFile = [myFile stringByAppendingPathComponent:[prefs objectForKey: @"theme"]];
    //myFile = [myFile stringByAppendingPathComponent: @"/"];
    
    //NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //NSString *appResources = [NSString stringWithFormat:@"%@/cDock/", appSupport];
    NSString *imageFile = [myFile stringByAppendingString:item];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    //NSString *docDir = [paths objectAtIndex:0];
    //NSString *docFile = [NSString stringWithFormat:@"%@/test_info.txt", docDir];
    //[imageFile writeToFile:docFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
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
    //CGRect rect = layer.bounds;
    NSArray *my_settings = readPrefs();
    NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
    int picture= validateInt(my_settings, 12);
// Corner radius:
    CGFloat cr = validateFloat(my_settings, 8, 1.);
    if (cr > 2.0)
        layer.cornerRadius = validateFloat(my_settings, 8, 1.) - 2.0;
    else
        layer.cornerRadius = validateFloat(my_settings, 8, 1.);
// Background
    if (picture == 0){
        layer.backgroundColor = CGColorCreateGenericRGB(validateFloat(my_settings, 0, 255.), validateFloat(my_settings, 1, 255.), validateFloat(my_settings, 2, 255.), validateFloat(my_settings, 3, 100.));
    } else {
        if (validateInt(my_settings, 19) == 1) {
            layer.contents = getImg(@"/3D.png");
        } else if (validateInt(my_settings, 20) == 0) {
            layer.contents = getImg(@"/background.png");
        } else {
            layer.backgroundColor = [[NSColor colorWithPatternImage:getImg(@"/background.png")] CGColor];
        }
        
        //Examples
        //layer.contentsCenter = CGRectMake(35/1280.0, 0.0, 1210/1280.0, 0.0);
        //layer.contentsGravity = kCAGravityResizeAspectFill;
        //layer.backgroundColor = [[NSColor colorWithPatternImage:getImg(@"background.png")] CGColor];
        layer.opacity = validateFloat(my_settings, 13, 100.);
    }
// Border
    if (osver.minorVersion < 10) {
        layer.borderColor = CGColorCreateGenericRGB(validateFloat(my_settings, 4, 255.), validateFloat(my_settings, 5, 255.), validateFloat(my_settings, 6, 255.), validateFloat(my_settings, 7, 100.));
        layer.borderWidth = validateFloat(my_settings, 9, 1.);
        layer.masksToBounds = NO;
        layer.shadowOffset = CGSizeMake(0, 0);
        layer.shadowRadius = validateFloat(my_settings, 10, 1.);
        layer.shadowOpacity = validateFloat(my_settings, 11, 100.);
    } else {
        layer.borderColor = CGColorCreateGenericGray(0.0, 0.0);
        layer.borderWidth = validateFloat(my_settings, 9, 1.);
    }
	return layer;
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
    NSOperatingSystemVersion osver = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (osver.majorVersion >= 10) {
        if (osver.minorVersion >= 10) {
            orig_CFPreferencesCopyAppValue = dlsym(RTLD_DEFAULT, "CFPreferencesCopyAppValue");
            rebind_symbols((struct rebinding[1]){{"CFPreferencesCopyAppValue", hax_CFPreferencesCopyAppValue}}, 1);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("AppleInterfaceThemeChangedNotification"), (void *)0x1, NULL, YES);
            });
            CALayer *floor_backup = [BlackDockFloorLayer layer];
            CALayer *border_backup = [BlackDockBorderLayer layer];
            Class dockFloorLayer = NSClassFromString(@"DOCKFloorLayer");
            for (layer in arr)
                if ([layer isKindOfClass:dockFloorLayer])
                    break;
            layer.sublayers = nil;
            [layer addSublayer:floor_backup];
            [layer addSublayer:border_backup];
            [floor_backup resizeWithOldSuperlayerSize:CGSizeZero];
            [border_backup resizeWithOldSuperlayerSize:CGSizeZero];
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
