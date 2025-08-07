
#import "mclient_app_delegate.h"

#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>

@implementation MClientAppDelegate

-(MClientAppDelegate*)init
{
    NSLog(@"MClientAppDelegate init:");
    self = [super init];
    if (self)
    {
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    NSLog(@"mainapplicationDidFinishLaunching:");
    NSLog(@"mainapplicationDidFinishLaunching: %@", [NSThread currentThread]);
    int rv = rdpc_init();
    NSLog(@"mainapplicationDidFinishLaunching: rdpc_init rv %d", rv);
    rv = svc_init();
    NSLog(@"mainapplicationDidFinishLaunching: svc_init rv %d", rv);
    rv = cliprdr_init();
    NSLog(@"mainapplicationDidFinishLaunching: cliprdr_init rv %d", rv);
    rv = rdpsnd_init();
    NSLog(@"mainapplicationDidFinishLaunching: rndsnd_init rv %d", rv);

    RDPConnect* connectInfo = [RDPConnect new];
    [connectInfo setServerName:@"127.0.0.1"];
    [connectInfo setServerPort:@"13389"];

    struct rdpc_settings_t settings;
    memset(&settings, 0, sizeof(settings));
    settings.bpp = 32;
    settings.width = 1024;
    settings.height = 768;
    settings.dpix = 96;
    settings.dpiy = 96;
    settings.keyboard_layout = 0x0409;
    settings.rfx = 1;
    settings.use_frame_ack = 1;
    settings.frames_in_flight = 5;
    settings.username[0] = 'j';
    settings.username[1] = 'a';
    settings.username[2] = 'y';
    settings.username[3] = 0;
    settings.clientname[0] = 'f';
    settings.clientname[1] = 'a';
    settings.clientname[2] = 'y';
    settings.clientname[3] = 0;
    settings.password[0] = 't';
    settings.password[1] = 'u';
    settings.password[2] = 'c';
    settings.password[3] = 'k';
    settings.password[4] = 'e';
    settings.password[5] = 'r';
    settings.password[6] = 0;

    session = [[RDPSession alloc] initWithSettings:&settings :connectInfo];
    if (session == nil)
    {
        [app terminate:self];
        return;
    }
    [session setApp:app];
    [session setAppName:appName];
    [session setAppVersion:appVersion];
    int connect_rv = [session connectToServer];
    NSLog(@"connectToServer rv %d", connect_rv);
    if (connect_rv != 0)
    {
        [app terminate:self];
        return;
    }

    [session setupRunLoop];

}

-(void)applicationWillTerminate:(NSNotification*)aNotification
{
    NSLog(@"applicationWillTerminate");
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    NSLog(@"applicationShouldTerminateAfterLastWindowClosed");
    return YES;
}

-(void)setApp:(NSApplication*)aapp
{
    app = aapp;
}

-(void)setAppName:(NSString*)aappName
{
    appName = [NSString stringWithString:aappName];
}

-(void)setAppVersion:(NSString*)aappVersion
{
    appVersion = [NSString stringWithString:aappVersion];
}

@end
