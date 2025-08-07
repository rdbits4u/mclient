
#import <Cocoa/Cocoa.h>
#import "rdpc_session.h"

@interface MClientAppDelegate : NSObject <NSApplicationDelegate>
{
    NSApplication* app;
    NSString* appName;
    NSString* appVersion;
    RDPSession* session;
}

-(void)setApp:(NSApplication*)aapp;
-(void)setAppName:(NSString*)aappName;
-(void)setAppVersion:(NSString*)aappVersion;

@end
