//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  3 2014 10:55:11).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class NSString;

@protocol WVRecentsDataSourceClient <NSObject>
- (void)setRecentsValue:(id)arg1 forKey:(NSString *)arg2 atIndex:(unsigned long long)arg3 withDataSource:(id <WVRecentsDataSource>)arg4;
- (void)recentsDataSourceInvalidatedForRange:(struct _NSRange)arg1 withDataSource:(id <WVRecentsDataSource>)arg2;
- (void)recentsDataSourceInvalidated:(id <WVRecentsDataSource>)arg1;
@end

