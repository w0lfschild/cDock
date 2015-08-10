//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  3 2014 10:55:11).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class CALayer, NSString;

@interface ECEvent : NSObject
{
    id _event;
    CALayer *_hitLayer;
    struct CGPoint _draggedDelta;
    NSString *_characters;
    id _session;
}

@property(nonatomic) struct CGPoint draggedDelta; // @synthesize draggedDelta=_draggedDelta;
@property(retain, nonatomic) CALayer *hitLayer; // @synthesize hitLayer=_hitLayer;
@property(readonly, nonatomic) __weak id session; // @synthesize session=_session;
@property(readonly, nonatomic) id event; // @synthesize event=_event;
- (void).cxx_destruct;
@property(readonly, nonatomic) long long gestureBehaviorType; // @dynamic gestureBehaviorType;
@property(readonly, nonatomic) long long stage; // @dynamic stage;
@property(readonly, nonatomic) double timestamp; // @dynamic timestamp;
@property(readonly, nonatomic) unsigned long long deviceID; // @dynamic deviceID;
@property(readonly, nonatomic) struct OpaqueCoreDrag *drag; // @dynamic drag;
@property(readonly, nonatomic) unsigned short notifyCode; // @dynamic notifyCode;
@property(readonly, nonatomic) unsigned int window; // @dynamic window;
@property(readonly, nonatomic) unsigned int connection; // @dynamic connection;
@property(readonly, nonatomic) unsigned long long momentumPhase; // @dynamic momentumPhase;
@property(readonly, nonatomic) unsigned long long scrollWheelPhase; // @dynamic scrollWheelPhase;
@property(readonly, nonatomic) unsigned long long gesturePhase; // @dynamic gesturePhase;
@property(readonly, nonatomic) int navigationGestureType; // @dynamic navigationGestureType;
@property(readonly, nonatomic) int gestureType; // @dynamic gestureType;
@property(readonly, nonatomic) BOOL scrollWheelReversed; // @dynamic scrollWheelReversed;
@property(readonly, nonatomic) BOOL isMomentum; // @dynamic isMomentum;
@property(readonly, nonatomic) BOOL isContinuous; // @dynamic isContinuous;
@property(readonly, nonatomic) double zoomValue; // @dynamic zoomValue;
@property(readonly, nonatomic) double deviceDeltaZ; // @dynamic deviceDeltaZ;
@property(readonly, nonatomic) double deviceDeltaY; // @dynamic deviceDeltaY;
@property(readonly, nonatomic) double deviceDeltaX; // @dynamic deviceDeltaX;
@property(readonly, nonatomic) double deltaZ; // @dynamic deltaZ;
@property(readonly, nonatomic) double mouseDeltaY; // @dynamic mouseDeltaY;
@property(readonly, nonatomic) double mouseDeltaX; // @dynamic mouseDeltaX;
@property(readonly, nonatomic) double deltaY; // @dynamic deltaY;
@property(readonly, nonatomic) double deltaX; // @dynamic deltaX;
@property(readonly, nonatomic) struct CGPoint windowLocation; // @dynamic windowLocation;
@property(readonly, nonatomic) struct CGPoint location; // @dynamic location;
@property(readonly, nonatomic) long long clickCount; // @dynamic clickCount;
@property(readonly, nonatomic) BOOL controlKeyDown; // @dynamic controlKeyDown;
@property(readonly, nonatomic) BOOL alternateKeyDown; // @dynamic alternateKeyDown;
@property(readonly, nonatomic) BOOL commandKeyDown; // @dynamic commandKeyDown;
@property(readonly, nonatomic) BOOL shiftKeyDown; // @dynamic shiftKeyDown;
@property(readonly, nonatomic) unsigned int flags; // @dynamic flags;
@property(readonly, nonatomic) unsigned long long time; // @dynamic time;
@property(readonly, nonatomic) NSString *characters; // @dynamic characters;
@property(readonly, nonatomic) unsigned short keyData; // @dynamic keyData;
@property(readonly, nonatomic) BOOL keyRepeat; // @dynamic keyRepeat;
@property(readonly, nonatomic) unsigned short charCode; // @dynamic charCode;
@property(readonly, nonatomic) int type; // @dynamic type;
- (void)invalidate;
- (id)initWithEvent:(id)arg1 session:(id)arg2;

@end

