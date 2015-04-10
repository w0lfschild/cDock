//
//  ZKSwizzle.h
//  ZKSwizzle
//
//  Created by Alexander S Zielenski on 7/24/14.
//  Copyright (c) 2014 Alexander S Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// This is a class for streamlining swizzling. Simply create a new class of any name you want and
// this will swizzle any methods with a prefix defined in the +prefix method

// Example:
/*
 
 @interface ZKHookClass : NSObject
 
 - (NSString *)description; // hooks -description on NSObject
 - (void)addedMethod; // all subclasses of NSObject now respond to -addedMethod
 
 @end
 
 @implementation ZKHookClass
 
 ...
 
 @end
 
 [ZKSwizzle swizzleClass:ZKClass(ZKHookClass) forClass:ZKClass(destination)];
 
 */

// Gets the a class with the name CLASS
#define ZKClass(CLASS) objc_getClass(#CLASS)

// returns the value of an instance variable.
#if !__has_feature(objc_arc)
    #define ZKHookIvar(OBJECT, TYPE, NAME) (*(TYPE *)ZKIvarPointer(OBJECT, NAME))
#else
    #define ZKHookIvar(OBJECT, TYPE, NAME) \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wignored-attributes\"") \
            (*(__unsafe_unretained TYPE *)ZKIvarPointer(OBJECT, NAME)) \
        _Pragma("clang diagnostic pop")
#endif
// returns the original implementation of the swizzled function or null or not found
#if !__has_feature(objc_arc)
    #define ZKOrig(...) (ZKOriginalImplementation(self, _cmd, __PRETTY_FUNCTION__))(self, _cmd, ##__VA_ARGS__)
#else
    #define ZKOrig(TYPE, ...) ((TYPE (*)(id, SEL, ...))(ZKOriginalImplementation(self, _cmd, __PRETTY_FUNCTION__)))(self, _cmd, ##__VA_ARGS__)
#endif
// returns the original implementation of the superclass of the object swizzled
#if !__has_feature(objc_arc)
    #define ZKSuper(...) (ZKSuperImplementation(self, _cmd))(self, _cmd, ##__VA_ARGS__)
#else
    #define ZKSuper(TYPE, ...) ((TYPE (*)(id, SEL, ...))(ZKSuperImplementation(self, _cmd)))(self, _cmd, ##__VA_ARGS__)
#endif

#define ZKSwizzle(SOURCE, DESTINATION) [ZKSwizzle swizzleClass:ZKClass(SOURCE) forClass:ZKClass(DESTINATION)]
#define ZKSwizzleClass(SOURCE) [ZKSwizzle swizzleClass:ZKClass(SOURCE)]

// thanks OBJC_OLD_DISPATCH_PROTOTYPES=0
typedef id (*ZKIMP)(id, SEL, ...);

// returns a pointer to the instance variable "name" on the object
void *ZKIvarPointer(id self, const char *name);
// returns the original implementation of a method with selector "sel" of an object hooked by the methods below
ZKIMP ZKOriginalImplementation(id self, SEL sel, const char *info);
// returns the implementation of a method with selector "sel" of the superclass of object
ZKIMP ZKSuperImplementation(id object, SEL sel);

@interface ZKSwizzle : NSObject
// hooks all the implemented methods of source with destination
// adds any methods that arent implemented on destination to destination that are implemented in source
+ (BOOL)swizzleClass:(Class)source forClass:(Class)destination;

// Calls above method with the superclass of source for desination
+ (BOOL)swizzleClass:(Class)source;

@end
