//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  3 2014 10:55:11).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@class ECSBDragCapture, ECSBSpringboard, NSObject<OS_dispatch_source>;

@interface ECSBEventHandler : NSObject
{
    ECSBSpringboard *_springBoard;
    ECSBDragCapture *_dragCapture;
    struct CGPoint _startLocation;
    unsigned long long _startTime;
    NSObject<OS_dispatch_source> *_deletingTimer;
    NSObject<OS_dispatch_source> *_springGroupTimer;
    NSObject<OS_dispatch_source> *_closeGroupTimer;
    unsigned int _allowDeleting:1;
    unsigned int _deleting:1;
    unsigned int _didStartDeleting:1;
    unsigned int _hideShownGroup:1;
    unsigned int _didDrag:1;
    unsigned int _dragCanceled:1;
    unsigned int _isAnimatingGroup:1;
    unsigned int _didDragIntoGroup:1;
}

@property(retain, nonatomic) ECSBDragCapture *dragCapture; // @synthesize dragCapture=_dragCapture;
@property(readonly, nonatomic) __weak ECSBSpringboard *springboard; // @synthesize springboard=_springBoard;
- (void).cxx_destruct;
- (void)cancelTimers;
- (_Bool)flagsChanged:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)dragDropped:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)dragExited:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)dragMoved:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)dragEntered:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)leftMouseUp:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)leftMouseDragged:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
- (_Bool)leftMouseDown:(id)arg1 inLayer:(id)arg2 ofPage:(id)arg3;
@property(readonly, nonatomic) _Bool dragging; // @dynamic dragging;
- (void)dealloc;
- (id)initWithSpringboard:(id)arg1;

@end

