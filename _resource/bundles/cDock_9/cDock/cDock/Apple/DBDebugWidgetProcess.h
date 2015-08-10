//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  3 2014 10:55:11).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "DBWidgetProcess.h"

@class DBWidget, NSArray, NSURL;

@interface DBDebugWidgetProcess : DBWidgetProcess
{
    NSURL *_clientURL;
    unsigned int _clientSendRight;
    NSArray *_argv;
    NSArray *_envp;
    DBWidget *_widget;
    struct __CFRunLoopSource *_source;
}

@property(readonly, nonatomic) DBWidget *widget; // @synthesize widget=_widget;
@property(nonatomic) unsigned int clientPort; // @synthesize clientPort=_clientSendRight;
- (void).cxx_destruct;
- (int)_setHidden:(unsigned int)arg1;
@property(readonly, nonatomic) unsigned int serverPort; // @dynamic serverPort;
- (void)removeWidget:(id)arg1;
- (char **)envpForSpawn;
- (char **)argvForSpawn;
- (const char *)launchPath;
- (void)dealloc;
- (id)initWithClient:(id)arg1 widgetURL:(id)arg2 position:(struct CGPoint *)arg3 argv:(id)arg4 envp:(id)arg5 clientSendRight:(unsigned int)arg6;

@end

