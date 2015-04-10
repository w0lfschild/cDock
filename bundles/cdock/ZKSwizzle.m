//
//  ZKSwizzle.m
//  ZKSwizzle
//
//  Created by Alexander S Zielenski on 7/24/14.
//  Copyright (c) 2014 Alexander S Zielenski. All rights reserved.
//

#import "ZKSwizzle.h"

#define kZKOrigPrefix @"_ZK_old_"

// give it the swizzle sourceclass and it will give back a selector
// prefixed with the ZKPrefix and the name of the swizzle source class
static SEL destinationSelectorForClassAndSelector(Class cls, SEL sel) {
    return NSSelectorFromString([kZKOrigPrefix stringByAppendingFormat:@"%s_%@", class_getName(cls), NSStringFromSelector(sel)]);
}

void *ZKIvarPointer(id self, const char *name) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
    return ivar == NULL ? NULL : (__bridge void *)self + ivar_getOffset(ivar);
}

// takes __PRETTY_FUNCTION__ for info which gives the name of the swizzle source class
/*
 We need to get the name of the swizzle source class so we can namespace original function implementations correctly
 If we subclassed a class we already swizzled and both implementations called ZKOrig without namespacing it would
 cause an infinite loop of calling the same method this way the original method of the superclass gets placed in 
 _ZK_old_Superclass_selectorName and the original method of its subclass which would be the implementation of the swizzled
 superclass gets placed in _ZK_old_Subclass_selectorName. For example:
 
 Assume that Superclass is a class which implements -swizzledMethod and Subclass is a subclass of Superclass
 which doesn't override -swizzledMethod, meaning when we place the original method into another selector while swizzling,
 it uses Superclass's implementation which has been swizzled

 // ZKOrig calls are expanded in this example
 @implementation Superclass
 - (void)swizzledMethod {
    // call the original method which Superclass swizzles
    [self _ZK_old_Superclass_swizzledMethod];
 }
 @end

 @implementation Subclass
 - (void)swizzledMethod {
    // call the superclass implementation of swizzledMethod since it isnt redefined on the original Subclass
    [self _ZK_old_Subclass_swizzledMethod];
 }
 @end
 
 A stack trace of calling -swizzledMethod on Subclass would look like this:
 
 -swizzledMethod
 -_ZK_old_Subclass_swizzledMethod
 -_ZK_old_Superclass_swizzledMethod
 
 */
ZKIMP ZKOriginalImplementation(id self, SEL sel, const char *info) {
    if (sel == NULL)
        return NULL;

    NSString *sig = @(info + 2);
    NSRange brk = [sig rangeOfString:@" "];
    sig = [sig substringToIndex:brk.location];

    Class cls = objc_getClass(sig.UTF8String);
    Class dest = object_getClass(self);
    if (cls == NULL || dest == NULL)
        return NULL;

    SEL oldSel = destinationSelectorForClassAndSelector(cls, sel);
    // works for class methods and instance methods because we call object_getClass
    // which gives us a metaclass if the object is a Class which a Class is an instace of
    Method method = class_getInstanceMethod(dest, oldSel);
    if (method == NULL)
        return NULL;
    
    return (ZKIMP)method_getImplementation(method);
}

ZKIMP ZKSuperImplementation(id object, SEL sel) {
    Class cls = object_getClass(object);
    if (cls == NULL)
        return NULL;

    BOOL classMethod = NO;
    if (class_isMetaClass(cls)) {
        cls = object;
        classMethod = YES;
    }
    
    cls = class_getSuperclass(cls);
    
    // This is a root class, it has no super class
    if (cls == NULL) {
        return NULL;
    }
    
    Method method = classMethod ?  class_getClassMethod(cls, sel) : class_getInstanceMethod(cls, sel);
    if (method == NULL)
        return NULL;
    
    return (ZKIMP)method_getImplementation(method);
}

static BOOL enumerateMethods(Class, Class);

@implementation ZKSwizzle

+ (BOOL)swizzleClass:(Class)source {
    return [self swizzleClass:source forClass:[source superclass]];
}

+ (BOOL)swizzleClass:(Class)source forClass:(Class)destination {
    BOOL success = enumerateMethods(destination, source);
    // The above method only gets instance variables. Do the same method for the metaclass of the class
    success     &= enumerateMethods(object_getClass(destination), object_getClass(source));
    
    return success;
}
@end

static BOOL enumerateMethods(Class destination, Class source) {
    unsigned int methodCount;
    Method *methodList = class_copyMethodList(source, &methodCount);
    BOOL success = NO;
    
    for (int i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        SEL selector  = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);

        // We only swizzle methods that are implemented
        if (class_respondsToSelector(destination, selector)) {
            SEL destinationSelector = destinationSelectorForClassAndSelector(source, selector);
            Method originalMethod = class_getInstanceMethod(destination, selector);

            const char *originalType = method_getTypeEncoding(originalMethod);
            const char *newType = method_getTypeEncoding(method);
            if (strcmp(originalType, newType) != 0) {
                NSLog(@"ZKSwizzle: incompatible type encoding for %@. (expected %s, got %s)", methodName, originalType, newType);
                // Incompatible type encoding
                success = NO;
                continue;
            }
            
            // We are re-adding the destination selector because it could be on a superclass and not on the class itself. This method could fail
            class_addMethod(destination, selector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            // Add the implementation of the replaced method at the prefixed selector
            class_addMethod(destination, destinationSelector, method_getImplementation(method), method_getTypeEncoding(method));
            
            // Retrieve the two new methods at their respective paths
            Method m1 = class_getInstanceMethod(destination, selector);
            Method m2 = class_getInstanceMethod(destination, destinationSelector);
            
            method_exchangeImplementations(m1, m2);
            
            success &= YES;
        } else {
            // Add any extra methods to the class but don't swizzle them
            success &= class_addMethod(destination, selector, method_getImplementation(method), method_getTypeEncoding(method));
        }
    }
    
    unsigned int propertyCount;
    objc_property_t *propertyList = class_copyPropertyList(source, &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = propertyList[i];
        const char *name = property_getName(property);
        unsigned int attributeCount;
        objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);
        
        if (class_getProperty(destination, name) == NULL) {
            class_addProperty(destination, name, attributes, attributeCount);
        } else {
            class_replaceProperty(destination, name, attributes, attributeCount);
        }
        
        free(attributes);
    }
    
    free(propertyList);
    free(methodList);
    return success;
}
