
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

//*****************************************************************************
// callback
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

//*****************************************************************************
// callback
// int (*log_msg)(struct rdpc_t* rdpc, const char* msg);
static int
cb_rdpc_log_msg(struct rdpc_t* rdpc, const char* msg)
{
    NSLog(@"cb_rdpc_log_msg: %s", msg);
    return LIBRDPC_ERROR_NONE;
}

//*****************************************************************************
// callback
// int (*send_to_server)(struct rdpc_t* rdpc, void* data, uint32_t bytes);
static int
cb_rdpc_send_to_server(struct rdpc_t* rdpc, void* data, uint32_t bytes)
{
    NSLog(@"cb_rdpc_send_to_server:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            if (data != NULL)
            {
                RDPSession* session = (RDPSession*)(rdpc->user);
                [session sendToServer:data :bytes];
                return LIBRDPC_ERROR_NONE;
            }
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
// callback
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
            if (bitmap_data != NULL)
            {
                RDPSession* session = (RDPSession*)(rdpc->user);
                [session setSurfaceBits:bitmap_data];
                return LIBRDPC_ERROR_NONE;
            }
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
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
            return LIBRDPC_ERROR_NONE;
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
// callback
// int (*pointer_update)(struct rdpc_t* rdpc,
//                       struct pointer_t* pointer);
static int
cb_rdpc_pointer_update(struct rdpc_t* rdpc,
                       struct pointer_t* pointer)
{
    NSLog(@"cb_rdpc_pointer_update:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            if (pointer != NULL)
            {
                RDPSession* session = (RDPSession*)(rdpc->user);
                [session pointerUpdate:pointer];
                return LIBRDPC_ERROR_NONE;
            }
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
// callback
// int (*pointer_cached)(struct rdpc_t* rdpc,
//                       uint16_t cache_index);
static int
cb_rdpc_pointer_cached(struct rdpc_t* rdpc, uint16_t cache_index)
{
    NSLog(@"cb_rdpc_pointer_cached:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session pointerCached:cache_index];
            return LIBRDPC_ERROR_NONE;
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
static int
l_poll(struct pollfd *fds, nfds_t nfds, int timeout)
{
    int rv;
    while ((rv = poll(fds, nfds, timeout)) == -1)
    {
        if (errno == EINTR) continue;
        break;
    }
    return rv;
}

//*****************************************************************************
static int
l_send(int sck, const char* data, size_t bytes)
{
    int send_rv;
    while ((send_rv = send(sck, data, bytes, 0)) == -1)
    {
        if (errno == EINTR) continue;
        if (errno == EINPROGRESS) return 0; // ok
        return -1;
    }
    return send_rv == 0 ? -1 : send_rv;
}

//*****************************************************************************
static int
l_recv(int sck, char* data, size_t bytes)
{
    int recv_rv;
    while ((recv_rv = recv(sck, data, bytes, 0)) == -1)
    {
        if (errno == EINTR) continue;
        if (errno == EINPROGRESS) return 0; // ok
        return -1;
    }
    return recv_rv == 0 ? -1 : recv_rv;
}

//*****************************************************************************
static int
l_fcntl(int fd, int op, int val)
{
    int rv;
    while ((rv = fcntl(fd, op, val)) == -1)
    {
        if (errno == EINTR) continue;
        break;
    }
    return rv;
}

//*****************************************************************************
static int
l_connect(int sck, const struct sockaddr* addr, socklen_t addr_size)
{
    int rv;
    while ((rv = connect(sck, addr, addr_size)) == -1)
    {
        if (errno == EINTR) continue;
        if (errno == EINPROGRESS) return 0; // ok
    }
    return rv;
}

//*****************************************************************************
static bool
can_recv(int asck)
{
    struct pollfd polfds[2];
    memset(polfds, 0, sizeof(polfds));
    polfds[0].fd = asck;
    polfds[0].events = POLLIN;
    int poll_rv = l_poll(polfds, 1, 0);
    if (poll_rv > 0)
    {
        if ((polfds[0].revents & POLLIN) != 0)
        {
            return true;
        }
    }
    return false;
}

//*****************************************************************************
static bool
can_send(int asck)
{
    struct pollfd polfds[2];
    memset(polfds, 0, sizeof(polfds));
    polfds[0].fd = asck;
    polfds[0].events = POLLOUT;
    int poll_rv = l_poll(polfds, 1, 0);
    if (poll_rv > 0)
    {
        if ((polfds[0].revents & POLLOUT) != 0)
        {
            return true;
        }
    }
    return false;
}

@implementation RDPConnect

//*****************************************************************************
-(void)setServerName:(NSString*)aserverName
{
    serverName = [NSString stringWithString:aserverName];
}

//*****************************************************************************
-(NSString*)getServerName
{
    return serverName;
}

//*****************************************************************************
-(void)setServerPort:(NSString*)aserverPort
{
    serverPort = [NSString stringWithString:aserverPort];
}

//*****************************************************************************
-(NSString*)getServerPort
{
    return serverPort;
}

@end

@implementation RDPSession

//*****************************************************************************
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
        rdpc->pointer_update = cb_rdpc_pointer_update;
        rdpc->pointer_cached = cb_rdpc_pointer_cached;

        connectInfo = aconnectInfo;
        [connectInfo retain];
        in_data_size = 128 * 1024;
        in_data = (char*)malloc(in_data_size);
    }
    return self;
}

//*****************************************************************************
-(int)sendToServer:(void*)adata :(uint32_t)abytes
{
    NSLog(@"sendToServer:");
    if (abytes < 1)
    {
        return 0;
    }
    char* save_data = (char*)adata;
    size_t save_bytes = abytes;
    size_t sent = 0;
    if ((send_head == NULL) && can_send(sck))
    {
        int send_rv = l_send(sck, save_data, save_bytes);
        if (send_rv == -1)
        {
            return 1;
        }
        NSLog(@"sendToServer: save_bytes %ld send_rv %d", save_bytes, send_rv);
        if (send_rv > 0)
        {
            sent += send_rv;
            if (sent >= save_bytes)
            {
                // all sent, ok
                return 0;
            }
            save_data += sent;
            save_bytes -= sent;
        }
    }
    struct send_t* send_obj = (struct send_t*)
            malloc(sizeof(struct send_t) + save_bytes);
    if (send_obj == NULL)
    {
        return 2;
    }
    memset(send_obj, 0, sizeof(struct send_t));
    char* send_data = (char*)(send_obj + 1);
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

//*****************************************************************************
-(int)setSurfaceBits:(struct bitmap_data_t*)abitmap_data
{
    NSLog(@"RDPSession setSurfaceBits:");
    if (abitmap_data->codec_id == 0)
    {
    }
    return 0;
}

//*****************************************************************************
-(int)frameMarker:(uint16_t)frame_action :(uint32_t)frame_id
{
    NSLog(@"RDPSession frameMarker:");
    if (frame_action == SURFACECMD_FRAMEACTION_END)
    {
        rdpc_send_frame_ack(rdpc, frame_id);
    }
    return 0;
}

//*****************************************************************************
-(int)pointerUpdate:(struct pointer_t*)apointer
{
    NSLog(@"RDPSession pointerUpdate:");
    return 0;
}

//*****************************************************************************
-(int)pointerCached:(uint16_t)cache_index
{
    NSLog(@"RDPSession pointerCached:");
    return 0;
}

//*****************************************************************************
-(int)connectToServer
{
    struct sockaddr_un unix_addr;
    struct sockaddr_in serv_addr;
    struct sockaddr* addr;
    long addr_size;

    NSLog(@"RDPSession connectToServer:");
    NSString* serverName = [connectInfo getServerName];
    NSString* serverPort = [connectInfo getServerPort];
    if (serverName == nil)
    {
        // unix domain socket
        memset(&unix_addr, 0, sizeof(unix_addr));
        addr = (struct sockaddr*)&unix_addr;
        addr_size = sizeof(unix_addr);
        snprintf(unix_addr.sun_path, sizeof(unix_addr.sun_path), "%s",
                [serverPort UTF8String]);
        sck = socket(PF_LOCAL, SOCK_STREAM, 0);
    }
    else
    {
        memset(&serv_addr, 0, sizeof(serv_addr));
        addr = (struct sockaddr*)&serv_addr;
        addr_size = sizeof(serv_addr);
        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port = htons([serverPort intValue]);
        NSLog(@"connectToServer: connecting to %s port %d",
                [serverName UTF8String], [serverPort intValue]);
        if (inet_pton(AF_INET, [serverName UTF8String],
                &serv_addr.sin_addr) <= 0)
        {
            return 1;
        }
        sck = socket(AF_INET, SOCK_STREAM, 0);
    }

    if (sck == -1)
    {
        return 2;
    }
    // set non blocking
    int val1 = l_fcntl(sck, F_GETFL, 0);
    if (val1 == -1)
    {
        return 3;
    }
    if ((val1 & O_NONBLOCK) == 0)
    {
        val1 = val1 | O_NONBLOCK;
        l_fcntl(sck, F_SETFL, val1);
    }
    // connect
    val1 = l_connect(sck, addr, addr_size);
    if (val1 == -1)
    {
        return 4;
    }
    return 0;
}

//*****************************************************************************
-(int)readProcessServerData
{
    NSLog(@"readProcessServerData:");
    if (!can_recv(sck))
    {
        return 0;
    }
    size_t to_read = in_data_size - recv_start;
    int recv_rv = l_recv(sck, in_data + recv_start, to_read);
    if (recv_rv == -1)
    {
        return 1;
    }
    NSLog(@"readProcessServerData: recv_rv %d", recv_rv);
    if (recv_rv > 0)
    {
        if (!connected)
        {
            return 2;
        }
        size_t end = recv_start + recv_rv;
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
    return 0;
}

//*****************************************************************************
-(int)processWriteServerData
{
    NSLog(@"processWriteServerData:");
    if (!can_send(sck))
    {
        return 0;
    }
    if (!connected)
    {
        connected = true;
        int rv = rdpc_start(rdpc);
        if (rv != LIBRDPC_ERROR_NONE)
        {
            return 1;
        }
        int width = rdpc->cgcc.core.desktopWidth;
        int height = rdpc->cgcc.core.desktopHeight;
        [self createWindow:width :height];
    }
    if (send_head != NULL)
    {
        struct send_t* send_obj = send_head;
        char* data = send_obj->out_data + send_obj->sent;
        size_t bytes = send_obj->out_data_bytes - send_obj->sent;
        int send_rv = l_send(sck, data, bytes);
        if (send_rv == -1)
        {
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
                free(send_obj);
            }
        }
    }
    return 0;
}

//*****************************************************************************
-(void)sendMouseMovedEvent:(uint16_t)x :(uint16_t)y
{
    rdpc_send_mouse_event(rdpc, PTRFLAGS_MOVE, x, y);
}

//*****************************************************************************
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

//*****************************************************************************
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

//*****************************************************************************
-(void)setApp:(NSApplication*)aapp
{
    app = aapp;
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
-(void)setupRunLoop
{
    bool want_write = (connected == false) || (send_head != NULL);
    if ((runLoopSourceRef != NULL) && (want_write == setupWithWantWrite))
    {
        // do not need to setup run loop
        return;
    }
    if (runLoopSourceRef != NULL)
    {
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
    setupWithWantWrite = want_write;
    CFOptionFlags sckFlags = want_write ?
            (kCFSocketReadCallBack | kCFSocketWriteCallBack) :
            kCFSocketReadCallBack;
    socketRef = CFSocketCreateWithNative(kCFAllocatorDefault, sck,
            sckFlags, socketCallback, &context);
    if (socketRef == NULL)
    {
        [app terminate:self];
        return;
    }
    // check flags
    CFOptionFlags flags = CFSocketGetSocketFlags(socketRef);
    flags &= ~kCFSocketCloseOnInvalidate;
    if (want_write)
    {
        flags |= kCFSocketAutomaticallyReenableWriteCallBack;
    }
    CFSocketSetSocketFlags(socketRef, flags);
    // create run loop source
    runLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
            socketRef, 0);
    if (runLoopSourceRef == NULL)
    {
        [app terminate:self];
        return;
    }
    // add to run loop
    CFRunLoopRef runLoopRef = CFRunLoopGetMain();
    CFRunLoopAddSource(runLoopRef, runLoopSourceRef, kCFRunLoopDefaultMode);
}

//*****************************************************************************
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

//*****************************************************************************
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

//*****************************************************************************
-(int)createWindow:(int)awidth :(int)aheight
{
    NSLog(@"createWindow:");
    // create window
    NSWindow* window = [NSWindow alloc];
    NSWindowStyleMask mask = NSTitledWindowMask | NSResizableWindowMask |
            NSMiniaturizableWindowMask | NSClosableWindowMask;
    [window
        initWithContentRect:NSMakeRect(0, 0, awidth, aheight)
        styleMask:mask
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setTitle:appName];
    [window center];
    [window makeKeyAndOrderFront:nil];
    [window setAcceptsMouseMovedEvents:TRUE];
    // create NSView
    view = [MClientView alloc];
    [view initWithFrame:NSMakeRect(0, 0, 1, 1)];
    [view setSession:self];
    [[window contentView] addSubview:view];
}

@end
