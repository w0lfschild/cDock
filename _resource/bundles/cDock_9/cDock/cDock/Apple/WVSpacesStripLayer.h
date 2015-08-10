//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  3 2014 10:55:11).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "CALayer.h"

#import "ECEventHandlingDelegate.h"
#import "ECKeyboardNavigating.h"

@class NSArray, NSMapTable, NSMutableArray, NSObject<OS_dispatch_source>, NSString, WVDisplay, WVSpace, WVSpacesAddLayer, WVSpacesItemLayer, WVSpacesStripDragManager;

@interface WVSpacesStripLayer : CALayer <ECEventHandlingDelegate, ECKeyboardNavigating>
{
    id <WVSpacesStripActionHandling> _handler;
    WVDisplay *_display;
    WVSpace *_selectedSpace;
    CALayer *_fishEyeEventLayer;
    CALayer *_spacesLayer;
    NSMutableArray *_spacesLayers;
    WVSpacesAddLayer *_addSpaceLayer;
    NSObject<OS_dispatch_source> *_fishTimer;
    BOOL _fishing;
    double _fishSize;
    double _fishStart;
    double _fishNow;
    double _fishFrom;
    double _fishTo;
    double _fishDur;
    double _fishCenter;
    struct CGRect _displayBounds;
    double _extraMargin;
    double _tileSize;
    double _maxSize;
    double _realScale;
    double _fullSize;
    BOOL _inMouseDownLayer;
    CALayer *_mouseDownLayer;
    WVSpacesItemLayer *_mouseEnteredSpaceLayer;
    NSObject<OS_dispatch_source> *_instaHoverTimer;
    NSObject<OS_dispatch_source> *_springTimer;
    WVSpacesItemLayer *_externalDragLayer;
    double _mouseDownOriginalX;
    WVSpacesStripDragManager *_spacesDragManager;
    struct CGPoint _spaceDraggedPosition;
    unsigned long long _addAnimationIndex;
    struct CGPoint _addAnimationStartPoint;
    double _addAnimationAngle;
    float _addDuration;
    double _minimumScale;
    BOOL _inLayer;
    BOOL _scaled;
    BOOL _instaHover;
    BOOL _showsDeleteButtons;
    BOOL _showsAddLayer;
    BOOL _showsAddLayerOnLeft;
    BOOL _magWithAnyScale;
    BOOL _dragInAddSpace;
    BOOL _inDrag;
    NSMapTable *_closeBoxToSpaceLayer;
    BOOL _removingSpace;
    BOOL _addingSpace;
    NSString *_spaceUUIDBeingAdded;
}

+ (double)heightForDisplayBounds:(struct CGRect)arg1;
@property(readonly, nonatomic) BOOL dragInAddSpace; // @synthesize dragInAddSpace=_dragInAddSpace;
@property(readonly, nonatomic) WVSpacesAddLayer *addSpaceLayer; // @synthesize addSpaceLayer=_addSpaceLayer;
@property(nonatomic) BOOL showsAddLayer; // @synthesize showsAddLayer=_showsAddLayer;
@property(nonatomic) BOOL magWithAnyScale; // @synthesize magWithAnyScale=_magWithAnyScale;
@property(nonatomic) BOOL showsDeleteButtons; // @synthesize showsDeleteButtons=_showsDeleteButtons;
@property(nonatomic) __weak WVSpace *selectedSpace; // @synthesize selectedSpace=_selectedSpace;
@property(readonly, nonatomic) NSArray *spaceLayers; // @synthesize spaceLayers=_spacesLayers;
@property(nonatomic) __weak WVDisplay *display; // @synthesize display=_display;
@property(readonly, nonatomic) __weak id <WVSpacesStripActionHandling> handler; // @synthesize handler=_handler;
- (void).cxx_destruct;
- (BOOL)navigate:(int)arg1 withEvent:(id)arg2;
- (void)windowDragEnded:(id)arg1;
- (void)windowDragStarted:(id)arg1;
- (BOOL)handleMouseDraggedAtGlobalLocation:(struct CGPoint)arg1;
- (BOOL)dragSpring:(id)arg1;
- (BOOL)leftMouseDragged:(id)arg1 inLayer:(id)arg2;
- (BOOL)leftMouseDraggedExited:(id)arg1 inLayer:(id)arg2;
- (BOOL)leftMouseDraggedEntered:(id)arg1 inLayer:(id)arg2;
- (BOOL)leftMouseUp:(id)arg1 inLayer:(id)arg2;
- (BOOL)leftMouseDown:(id)arg1 inLayer:(id)arg2;
- (BOOL)mouseExited:(id)arg1 inLayer:(id)arg2;
- (BOOL)mouseMoved:(id)arg1 inLayer:(id)arg2;
- (BOOL)_shouldShowAddButtonAtLocation:(struct CGPoint)arg1;
- (BOOL)_handleMouseMovedAtLocation:(struct CGPoint)arg1;
- (BOOL)mouseEntered:(id)arg1 inLayer:(id)arg2;
- (void)removeSpacesItemLayer:(id)arg1;
- (void)finalizeSpaceDropWithManager:(id)arg1 fromStripLayer:(id)arg2;
- (void)addSpacesItemLayer:(id)arg1 atGlobalPoint:(struct CGPoint)arg2 globalDestination:(struct CGPoint *)arg3;
- (void)cancelDrag;
- (void)_finalizeDragOfItem:(id)arg1 afterItemLayer:(id)arg2 dragManager:(id)arg3;
- (void)moveSpace:(id)arg1 afterSpace:(id)arg2;
- (void)_addCloseboxToLayer:(id)arg1 animate:(BOOL)arg2;
- (void)reloadSpaceNames;
- (id)spacesItemLayerAtLocation:(struct CGPoint)arg1;
- (id)spacesItemLayerForSpace:(id)arg1;
- (id)spacesItemForSpace:(id)arg1;
- (void)removeSpace:(id)arg1;
- (id)addSpace:(id)arg1 atIndex:(unsigned long long)arg2 withWindows:(id)arg3 animationDuration:(double *)arg4 animationCurve:(double *)arg5;
- (BOOL)_canAddSpace;
- (void)desktopForSpaceChanged:(id)arg1;
- (struct CGRect)globalRectForSpace:(id)arg1;
- (void)layout;
- (void)_initialLayout;
- (void)_layoutAddLayer:(BOOL)arg1;
- (void)_timedLayout;
- (void)_layout;
- (void)_layoutWithMag:(double)arg1;
- (void)_layoutWithoutMag;
- (void)_layoutIndexSetWithoutMag:(id)arg1;
- (double)_maxSize;
- (void)setWindowsPerSpace:(id)arg1 spaces:(id)arg2;
- (id)_spacesItemLayerForSpace:(id)arg1 title:(id)arg2 withWindows:(id)arg3;
@property(readonly, nonatomic) NSArray *spaces;
@property(readonly, nonatomic) BOOL dragging;
- (void)_layoutCloseboxes;
@property(nonatomic) unsigned long long selectedIndex;
@property(readonly, nonatomic) double scale;
- (void)dealloc;
- (id)initWithHandler:(id)arg1 display:(id)arg2 extraMargin:(double)arg3 addsOnLeft:(BOOL)arg4;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

