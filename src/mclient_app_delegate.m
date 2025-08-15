
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
#import <Cocoa/Cocoa.h>
#import "mclient_app_delegate.h"
#import "mclient_view.h"
#import "rdpc_session.h"
#import "mclient_log.h"

@implementation MClientAppDelegate

//*****************************************************************************
-(MClientAppDelegate*)init
{
    NSLog(@"MClientAppDelegate init:");
    self = [super init];
    if (self)
    {
    }
    return self;
}

//*****************************************************************************
-(void)dealloc
{
    NSLog(@"MClientAppDelegate dealloc:");
    [app release];
    [appName release];
    [appVersion release];
    [session release];
    [connectInfo release];
    [super dealloc];
}

//*****************************************************************************
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
    // create session
    session = [[RDPSession alloc] initWithSettings:settings :connectInfo];
    free(settings);
    settings = NULL;
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

//*****************************************************************************
-(void)applicationWillTerminate:(NSNotification*)aNotification
{
    NSLog(@"applicationWillTerminate");
}

//*****************************************************************************
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    NSLog(@"applicationShouldTerminateAfterLastWindowClosed");
    return YES;
}

//*****************************************************************************
-(void)setApp:(NSApplication*)aapp
{
    app = aapp;
    [app retain];
}

//*****************************************************************************
-(void)setAppName:(NSString*)aappName
{
    appName = [NSString stringWithString:aappName];
}

//*****************************************************************************
-(void)setAppVersion:(NSString*)aappVersion
{
    appVersion = [NSString stringWithString:aappVersion];
}

//*****************************************************************************
static const char*
last_strstr(const char* haystack, const char* needle)
{
    const char* rv = NULL;
    const char* pos = strstr(haystack, needle);
    while (pos != NULL)
    {
        rv = pos;
        pos = strstr(pos + 1, needle);
    }
    return rv;
}

//*****************************************************************************
-(int)processServerPort:(const char*)arg
{
    NSLog(@"processServerPort: arg %s", arg);
    if (arg[0] == '/')
    {
        NSLog(@"processServerPort: unix domain socket");
        NSString* str = [[NSString alloc] initWithUTF8String:arg];
        [connectInfo setServerPort:str];
        [str release];
    }
    else
    {
        NSString* str = [[NSString alloc] initWithUTF8String:arg];
        [connectInfo setServerName:str];
        [str release];
    }
    const char* col_pos = last_strstr(arg, ":");
    const char* brc_pos = last_strstr(arg, "]"); // bracket close
    const char* bro_pos = last_strstr(arg, "["); // bracket open
    // look for [aaaa:bbbb:cccc:dddd]:3389
    if ((col_pos != NULL) && (brc_pos != NULL) && (bro_pos != NULL) &&
        (col_pos > brc_pos))
    {
        char server[256];
        char port[256];
        long server_len = brc_pos - bro_pos;
        server_len = server_len > sizeof(server) ? sizeof(server) : server_len;
        snprintf(server, server_len, "%s", bro_pos + 1);
        snprintf(port, sizeof(port), "%s", col_pos + 1);
        NSString* server_str = [[NSString alloc] initWithUTF8String:server];
        NSString* port_str = [[NSString alloc] initWithUTF8String:port];
        NSLog(@"processServerPort: [server]:port [%s]:[%s]", server, port);
        [connectInfo setServerName:server_str];
        [connectInfo setServerPort:port_str];
        [server_str release];
        [port_str release];
    }
    // look for [aaaa:bbbb:cccc:dddd]
    else if ((brc_pos != NULL) && (bro_pos != NULL))
    {
        char server[256];
        long server_len = brc_pos - bro_pos;
        server_len = server_len > sizeof(server) ? sizeof(server) : server_len;
        snprintf(server, server_len, "%s", bro_pos + 1);
        NSString* server_str = [[NSString alloc] initWithUTF8String:server];
        NSLog(@"processServerPort: [server] %s", server);
        [connectInfo setServerName:server_str];
        [server_str release];
    }
    // look for 127.0.0.1:3389
    else if (col_pos != NULL)
    {
        char server[256];
        char port[256];
        long server_len = (col_pos - arg) + 1;
        server_len = server_len > sizeof(server) ? sizeof(server) : server_len;
        snprintf(server, server_len, "%s", arg);
        snprintf(port, sizeof(port), "%s", col_pos + 1);
        NSString* server_str = [[NSString alloc] initWithUTF8String:server];
        NSString* port_str = [[NSString alloc] initWithUTF8String:port];
        NSLog(@"processServerPort: server:port %s:%s", server, port);
        [connectInfo setServerName:server_str];
        [connectInfo setServerPort:port_str];
        [server_str release];
        [port_str release];
    }
    return 0;
}

//*****************************************************************************
-(int)processArgs:(int)argc :(const char**)argv
{
    NSLog(@"processArgs:");
    if (argc < 2)
    {
        return 1;
    }
    connectInfo = [RDPConnect new];
    if (connectInfo == nil)
    {
        return 1;
    }
    [connectInfo setServerPort:@"3389"];
    settings = (struct rdpc_settings_t*)calloc(1,
            sizeof(struct rdpc_settings_t));
    if (settings == NULL)
    {
        return 1;
    }
    settings->bpp = 32;
    settings->width = 1024;
    settings->height = 768;
    settings->dpix = 96;
    settings->dpiy = 96;
    settings->keyboard_layout = 0x0409;
    settings->rfx = 1;
    settings->jpg = 0;
    settings->use_frame_ack = 1;
    settings->frames_in_flight = 5;

    const char* env1 = getenv("USER");
    if (env1 != NULL)
    {
        snprintf(settings->username, sizeof(settings->username), "%s", env1);
        NSLog(@"processArgs: username from env is %s", settings->username);
    }
    char hostname[255];
    if (gethostname(hostname, 255) == 0)
    {
        snprintf(settings->clientname, sizeof(settings->clientname), "%s", hostname);
        NSLog(@"processArgs: clientname from host %s", settings->clientname);
    }

    int index;
    for (index = 1; index < argc; index++)
    {
        NSLog(@"processArgs arg index %d arg %s", index, argv[index]);
        if (strcmp(argv[index], "-h") == 0)
        {
            // show command line
        }
        else if (strcmp(argv[index], "-u") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->username, sizeof(settings->username),
                    "%s", argv[index]);
            NSLog(@"processArgs: username %s", settings->username);
        }
        else if (strcmp(argv[index], "-d") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->domain, sizeof(settings->domain),
                    "%s", argv[index]);
            NSLog(@"processArgs: domain %s", settings->domain);
        }
        else if (strcmp(argv[index], "-s") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->altshell, sizeof(settings->altshell),
                    "%s", argv[index]);
            NSLog(@"processArgs: altshell %s", settings->altshell);
        }
        else if (strcmp(argv[index], "-c") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->workingdir, sizeof(settings->workingdir),
                    "%s", argv[index]);
            NSLog(@"processArgs: workingdir %s", settings->workingdir);
        }
        else if (strcmp(argv[index], "-p") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->password, sizeof(settings->password),
                    "%s", argv[index]);
            NSLog(@"processArgs: password ***");
        }
        else if (strcmp(argv[index], "-n") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            snprintf(settings->clientname, sizeof(settings->clientname),
                    "%s", argv[index]);
            NSLog(@"processArgs: clientname %s", settings->clientname);
        }
        else if (strcmp(argv[index], "-g") == 0)
        {
            index++;
            if (index >= argc)
            {
                NSLog(@"processArgs not enough args");
                return 1;
            }
            char width[16];
            char height[16];
            const char* xpos = strstr(argv[index], "x");
            if (xpos == NULL)
            {
                NSLog(@"processArgs no x");
                return 1;
            }
            long width_len = xpos - argv[index] + 1;
            width_len = width_len > sizeof(width) ? sizeof(width) : width_len;
            snprintf(width, width_len, "%s", argv[index]);
            snprintf(height, sizeof(height), "%s", xpos + 1);
            NSLog(@"processArgs width %s height %s", width,  height);
            settings->width = atoi(width);
            settings->height = atoi(height);
        }
        else
        {
            [self processServerPort:argv[index]];
        }
    }
    return 0;
}

@end
