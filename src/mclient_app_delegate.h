
#import <Cocoa/Cocoa.h>
#import "rdpc_session.h"

@interface MClientAppDelegate : NSObject <NSApplicationDelegate>
{
    NSApplication* app;
    NSString* appName;
    NSString* appVersion;
    RDPSession* session;
    RDPConnect* connectInfo;
    struct rdpc_settings_t* settings;
}

-(void)setApp:(NSApplication*)aapp;
-(void)setAppName:(NSString*)aappName;
-(void)setAppVersion:(NSString*)aappVersion;
-(int)processArgs:(int)argc :(char**)argv;

@end
