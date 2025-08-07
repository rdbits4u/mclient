
#import "rdpc_session.h"
#import "mclient_view.h"

//*************************************************************************
static void
socketCallback(CFSocketRef theSocketRef,
               CFSocketCallBackType theCallbackType,
               CFDataRef theAddress,
               const void* theData,
               void* theInfo)
{
    RDPSession* session;
    switch (theCallbackType)
    {
        case kCFSocketReadCallBack:
            session = (RDPSession*)theInfo;
            [session doRead];
            break;
        case kCFSocketWriteCallBack:
            session = (RDPSession*)theInfo;
            [session doWrite];
            break;
        default:
            NSLog(@"socketCallback: unknown");
            break;
    }
}

//*************************************************************************
// int (*log_msg)(struct rdpc_t* rdpc, const char* msg);
static int
cb_rdpc_log_msg(struct rdpc_t* rdpc, const char* msg)
{
    NSLog(@"cb_rdpc_log_msg: %s", msg);
    return 0;
}

//*************************************************************************
// int (*send_to_server)(struct rdpc_t* rdpc, void* data, uint32_t bytes);
static int
cb_rdpc_send_to_server(struct rdpc_t* rdpc, void* data, uint32_t bytes)
{
    NSLog(@"cb_rdpc_send_to_server:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session sendToServer:data :bytes];
        }
    }
    return 0;
}

//*************************************************************************
// int (*set_surface_bits)(struct rdpc_t* rdpc,
//                        struct bitmap_data_t* bitmap_data);
static int
cb_rdpc_set_surface_bits(struct rdpc_t* rdpc,
                         struct bitmap_data_t* bitmap_data)
{
    NSLog(@"cb_rdpc_set_surface_bits:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session setSurfaceBits:bitmap_data];
        }
    }
    return 0;
}

//*************************************************************************
// int (*frame_marker)(struct rdpc_t* rdpc, uint16_t frame_action,
//                     uint32_t frame_id);
static int
cb_rdpc_frame_marker(struct rdpc_t* rdpc, uint16_t frame_action,
                     uint32_t frame_id)
{
    NSLog(@"cb_rdpc_frame_marker:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session frameMarker:frame_action :frame_id];
        }
    }
    return 0;
}

@implementation RDPConnect

//*************************************************************************
-(void)setServerName:(NSString*)aserverName
{
    serverName = [NSString stringWithString:aserverName];
}

//*************************************************************************
-(NSString*)getServerName
{
    return serverName;
}

//*************************************************************************
-(void)setServerPort:(NSString*)aserverPort
{
    serverPort = [NSString stringWithString:aserverPort];
}

//*************************************************************************
-(NSString*)getServerPort
{
    return serverPort;
}

@end

@implementation RDPSession

//*************************************************************************
-(RDPSession*)initWithSettings
        :(struct rdpc_settings_t*)asettings
        :(RDPConnect*)aconnectInfo
{
    NSLog(@"RDPSession initWithSettings:");
    self = [super init];
    if (self)
    {
        // setup rdpc
        int rv = rdpc_create(asettings, &rdpc);
        NSLog(@"RDPSession initWithSettings: rdpc_create rv %d", rv);
        if (rv != LIBRDPC_ERROR_NONE)
        {
            return nil;
        }
        rdpc->user = self;
        rdpc->log_msg = cb_rdpc_log_msg;
        rdpc->send_to_server = cb_rdpc_send_to_server;
        rdpc->set_surface_bits = cb_rdpc_set_surface_bits;
        rdpc->frame_marker = cb_rdpc_frame_marker;

        connectInfo = aconnectInfo;
        in_data_size = 128 * 1024;
        in_data = malloc(in_data_size);
    }
    return self;
}

//*************************************************************************
-(int)sendToServer:(void*)adata :(uint32_t)abytes
{
    NSLog(@"sendToServer:");
    if (abytes < 1)
    {
        return 0;
    }
    char* save_data = (char*)adata;
    uint32_t save_bytes = abytes;
    if (send_head == NULL && 1)
    {
        int send_rv;
        while ((send_rv = send(sck, adata, abytes, 0)) == -1)
        {
            if (errno == EINTR) continue;
            if (errno == EINPROGRESS) break; // ok
            return 1;
        }
        NSLog(@"sendToServer: abytes %d send_rv %d", abytes, send_rv);
        if (send_rv > 0)
        {
            if (send_rv >= abytes)
            {
                // all sent, ok
                return 0;
            }
            save_data += send_rv;
            save_bytes -= send_rv;
        }
    }
    char* send_data = (char*)malloc(save_bytes);
    if (send_data == NULL)
    {
        return 2;
    }
    struct send_t* send_obj = (struct send_t*)calloc(1, sizeof(struct send_t));
    if (send_obj == NULL)
    {
        free(send_data);
        return 3;
    }
    memcpy(send_data, save_data, save_bytes);
    send_obj->out_data_bytes = save_bytes;
    send_obj->out_data = send_data;
    if (send_tail != NULL)
    {
        send_tail->next = send_obj;
        send_tail = send_obj;
    }
    else
    {
        send_head = send_obj;
        send_tail = send_obj;
    }
    [self setupRunLoop];
    return 0;
}

//*************************************************************************
-(int)setSurfaceBits:(struct bitmap_data_t*)abitmap_data
{
    NSLog(@"RDPSession setSurfaceBits:");
    return 0;
}

-(int)frameMarker:(uint16_t)frame_action :(uint32_t)frame_id
{
    NSLog(@"RDPSession frameMarker:");
    if (frame_action == SURFACECMD_FRAMEACTION_END)
    {
        rdpc_send_frame_ack(rdpc, frame_id);
    }
    return 0;
}

//*************************************************************************
-(int)connectToServer
{
    NSLog(@"RDPSession connectToServer:");

    NSString* serverName = [connectInfo getServerName];
    NSString* serverPort = [connectInfo getServerPort];

    struct sockaddr_in serv_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons([serverPort intValue]);
    NSLog(@"connectToServer: connecting to %s port %d",
            [serverName UTF8String], [serverPort intValue]);
    if (inet_pton(AF_INET, [serverName UTF8String], &serv_addr.sin_addr) <= 0)
    {
        return 1;
    }

    sck = socket(AF_INET, SOCK_STREAM, 0);
    if (sck == -1)
    {
        return 2;
    }
    // set non blocking
    int val1;
    while ((val1 = fcntl(sck, F_GETFL, 0)) == -1)
    {
        if (errno == EINTR) continue;
        return 3;
    }
    if ((val1 & O_NONBLOCK) == 0)
    {
        val1 = val1 | O_NONBLOCK;
        fcntl(sck, F_SETFL, val1);
    }
    // connect
    while ((val1 = connect(sck, (struct sockaddr *)&serv_addr, sizeof(serv_addr))) == -1)
    {
        if (errno == EINTR) continue;
        if (errno == EINPROGRESS) break; // ok
        return 4;
    }
    return 0;
}

//*************************************************************************
-(int)readProcessServerData
{
    NSLog(@"readProcessServerData:");
    int to_read = in_data_size - recv_start;
    int recv_rv;
    int val1;
    while ((recv_rv = recv(sck, in_data + recv_start, to_read, 0)) == -1)
    {
        if (errno == EINTR) continue;
        if (errno == EINPROGRESS) return 0; // ok
        return 1;
    }
    NSLog(@"readProcessServerData: recv_rv %d", recv_rv);
    if (recv_rv > 0)
    {
        if (!connected)
        {
            return 2;
        }
        int end = recv_start + recv_rv;
        uint32_t bp;
        int rv;
        while (end > 0)
        {
            bp = 0;
            rv = rdpc_process_server_data(rdpc, in_data, end, &bp);
            if (rv == LIBRDPC_ERROR_NONE)
            {
                // copy any left over data up to front of in_data
                memmove(in_data, in_data + bp, end - bp);
                end -= bp;
                recv_start = end;
            }
            else if (rv == LIBRDPC_ERROR_NEED_MORE)
            {
                recv_start = end;
                break;
            }
            else
            {
                return 3;
            }
        }
    }
    else
    {
        return 4;
    }
    return 0;
}

//*************************************************************************
-(int)processWriteServerData
{
    NSLog(@"processWriteServerData:");
    if (!connected)
    {
        connected = true;


        int rv = rdpc_start(rdpc);
        if (rv != LIBRDPC_ERROR_NONE)
        {
            return 1;
        }

        // create window
        NSWindow* window = [NSWindow alloc];
        NSWindowStyleMask mask = NSTitledWindowMask | NSResizableWindowMask |
                NSMiniaturizableWindowMask | NSClosableWindowMask;
        [window
            initWithContentRect:NSMakeRect(0, 0, 1024, 768)
            styleMask:mask
            backing:NSBackingStoreBuffered
            defer:NO];
        [window setTitle:appName];
        [window center];
        [window makeKeyAndOrderFront:nil];
        //[window setDelegate:[app delegate]];
        [window setAcceptsMouseMovedEvents:TRUE];
        // create NSView
        MClientView* view = [MClientView alloc];
        [view initWithFrame:NSMakeRect(0, 0, 1, 1)];
        [[window contentView] addSubview:view];
        [view setSession:self];

    }
    while (send_head != NULL)
    {
        struct send_t* send_obj = send_head;
        int send_rv;
        char* data =send_obj->out_data + send_obj->sent;
        size_t bytes = send_obj->out_data_bytes - send_obj->sent;
        while ((send_rv = send(sck, data, bytes, 0)) == -1)
        {
            if (errno == EINTR) continue;
            if (errno == EINPROGRESS) break; // ok
            return 2;
        }
        NSLog(@"processWriteServerData: bytes %ld send_rv %d", bytes, send_rv);
        if (send_rv > 0)
        {
            send_obj->sent += send_rv;
            if (send_obj->sent >= send_obj->out_data_bytes)
            {
                send_head = send_head->next;
                if (send_head == NULL)
                {
                    // if send_head is null, set send_tail to null
                    send_tail = NULL;
                }
                free(send_obj->out_data);
                free(send_obj);
            }
        }
        else
        {
            break;
        }
    }
    return 0;
}

//*************************************************************************
-(void)sendMouseMovedEvent:(uint16_t)x :(uint16_t)y
{
    rdpc_send_mouse_event(rdpc, PTRFLAGS_MOVE, x, y);
}

//*************************************************************************
-(void)sendMouseDownEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y
{
    uint16_t flags = PTRFLAGS_DOWN;
    switch (but) 
    {
        case 1: flags |= PTRFLAGS_BUTTON1; break;
        case 2: flags |= PTRFLAGS_BUTTON2; break;
        case 3: flags |= PTRFLAGS_BUTTON3; break;
        default: return; 
    }
    rdpc_send_mouse_event(rdpc, flags, x, y);
}

//*************************************************************************
-(void)sendMouseUpEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y
{
    uint16_t flags = 0;
    switch (but) 
    {
        case 1: flags |= PTRFLAGS_BUTTON1; break;
        case 2: flags |= PTRFLAGS_BUTTON2; break;
        case 3: flags |= PTRFLAGS_BUTTON3; break;
        default: return; 
    }
    rdpc_send_mouse_event(rdpc, flags, x, y);
}

//*************************************************************************
-(void)setApp:(NSApplication*)aapp
{
    app = aapp;
}

//*************************************************************************
-(void)setAppName:(NSString*)aappName
{
    appName = [NSString stringWithString:aappName];
}

//*************************************************************************
-(void)setAppVersion:(NSString*)aappVersion
{
    appVersion = [NSString stringWithString:aappVersion];
}

//*************************************************************************
-(int)getSck
{
    NSLog(@"RDPSession getSck:");
    return sck;
}

//*************************************************************************
-(bool)wantWrite
{
    NSLog(@"RDPSession wantWrite:");
    if (!connected)
    {
        return true;
    }
    if (send_head != NULL)
    {
        return true;
    }
    return false;
}

//*************************************************************************
-(void)setupRunLoop
{
    NSLog(@"setupRunLoop:");
    bool want_write = [self wantWrite];
    NSLog(@"setupRunLoop: want_write %d setupWithWantWrite %d",
            (int)want_write, (int)setupWithWantWrite);
    if (runLoopSourceRef != NULL && (want_write == setupWithWantWrite))
    {
        // do not need to setup run loop
        return;
    }
    CFRunLoopRef runLoopRef = CFRunLoopGetMain();
    if (runLoopSourceRef != NULL)
    {
        NSLog(@"setupRunLoop: remove %p %p", runLoopSourceRef, socketRef);
        CFRunLoopSourceInvalidate(runLoopSourceRef);
        CFRelease(runLoopSourceRef);
        runLoopSourceRef = NULL;
    }
    if (socketRef != NULL)
    {
        CFSocketInvalidate(socketRef);
        CFRelease(socketRef);
        socketRef = NULL;
    }
    // create socket
    CFSocketContext context;
    memset(&context, 0, sizeof(context));
    context.info = self;
    setupWithWantWrite = false;
    CFOptionFlags sckFlags = kCFSocketReadCallBack;
    if (want_write)
    {
        setupWithWantWrite = true;
        sckFlags |= kCFSocketWriteCallBack;
    }
    socketRef = CFSocketCreateWithNative(kCFAllocatorDefault, sck,
            sckFlags, socketCallback, &context);
    if (socketRef == NULL)
    {
        [app terminate:self];
        return;
    }
    // check flags
    CFOptionFlags flags = CFSocketGetSocketFlags(socketRef);
    CFOptionFlags sflags = flags;
    if ((flags & kCFSocketCloseOnInvalidate) != 0)
    {
        flags &= ~kCFSocketCloseOnInvalidate;
    }
    if (want_write)
    {
        if ((flags & kCFSocketAutomaticallyReenableWriteCallBack) == 0)
        {
            flags |= kCFSocketAutomaticallyReenableWriteCallBack;
        }
    }
    if ((flags & kCFSocketAutomaticallyReenableReadCallBack) == 0)
    {
        flags |= kCFSocketAutomaticallyReenableReadCallBack;
    }
    if (sflags != flags)
    {
        NSLog(@"setupRunLoop: setting flags old 0x%X new 0x%X", sflags, flags);
        CFSocketSetSocketFlags(socketRef, flags);
    }
    // create run loop source
    runLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
            socketRef, 0);
    if (runLoopSourceRef == NULL)
    {
        [app terminate:self];
        return;
    }
    // add to run loop
    NSLog(@"setupRunLoop: adding %p %p", runLoopSourceRef, socketRef);
    CFRunLoopAddSource(runLoopRef, runLoopSourceRef, kCFRunLoopDefaultMode);

}

//*************************************************************************
-(void)doRead;
{
    NSLog(@"doRead:");
    if ([self readProcessServerData] != 0)
    {
        [app terminate:self];
        return;
    }
    [self setupRunLoop];
}

//*************************************************************************
-(void)doWrite;
{
    NSLog(@"doWrite:");
    if ([self processWriteServerData] != 0)
    {
        [app terminate:self];
        return;
    }
    [self setupRunLoop];
}

@end
