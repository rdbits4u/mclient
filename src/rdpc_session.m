
#include <poll.h>
#include <librdpc.h>
#include <libsvc.h>
#include <libcliprdr.h>
#include <librdpsnd.h>
#include <rlecodec_decode.h>
#include <rfxcodec_decode.h>
#include <libdrdynvc.h>
#include <libedisp.h>

#import <Cocoa/Cocoa.h>
#import "mclient_app_delegate.h"
#import "mclient_view.h"
#import "mclient_window.h"
#import "rdpc_session.h"
#import "mclient_log.h"

#include "rdpc_session_cb.h"

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
        rdpc->bitmap_update = cb_rdpc_bitmap_update;
        rdpc->set_surface_bits = cb_rdpc_set_surface_bits;
        rdpc->frame_marker = cb_rdpc_frame_marker;
        rdpc->pointer_update = cb_rdpc_pointer_update;
        rdpc->pointer_cached = cb_rdpc_pointer_cached;
        rdpc->pointer_system = cb_rdpc_pointer_system;
        rdpc->pointer_pos = cb_rdpc_pointer_pos;

        // setup svc
        rv = svc_create(&svc);
        NSLog(@"RDPSession initWithSettings: svc_create rv %d", rv);
        if (rv != LIBSVC_ERROR_NONE)
        {
            return nil;
        }
        svc->user = self;
        svc->log_msg = cb_svc_log_msg;
        svc->send_data = cb_svc_send_data;

        // setup channels
        struct TS_UD_CS_NET* gcc_net = &rdpc->cgcc.net;

        // setup drdynvc
        rv = drdynvc_create(&drdynvc);
        NSLog(@"RDPSession initWithSettings: drdynvc_create rv %d", rv);
        if (rv != LIBDRDYNVC_ERROR_NONE)
        {
            return nil;
        }
        drdynvc->user = self;
        drdynvc->log_msg = cb_drdynvc_log_msg;
        drdynvc->send_data = cb_drdynvc_svc_send_data;
        drdynvc->process_cap_request = cb_drdynvc_process_cap_request;
        drdynvc->process_create_request = cb_drdynvc_process_create_request;
        drdynvc->process_data_first = cb_drdynvc_process_data_first;
        drdynvc->process_data = cb_drdynvc_process_data;
        drdynvc->process_close = cb_drdynvc_process_close;
        size_t chan_index = gcc_net->channelCount;
        struct CHANNEL_DEF* chan = &gcc_net->channelDefArray[chan_index];
        memcpy(&chan->name, "DRDYNVC", 8);
        chan->options = 0;
        svc->channels[chan_index].user = self;
        svc->channels[chan_index].process_data = cb_svc_drdynvc_process_data;
        gcc_net->channelCount += 1;

        // setup cliprdr
        rv = cliprdr_create(&cliprdr);
        NSLog(@"RDPSession initWithSettings: cliprdr_create rv %d", rv);
        if (rv != LIBCLIPRDR_ERROR_NONE)
        {
            return nil;
        }
        cliprdr->user = self;
        cliprdr->log_msg = cb_cliprdr_log_msg;
        cliprdr->send_data = cb_cliprdr_svc_send_data;
        cliprdr->ready = cb_cliprdr_ready;
        cliprdr->format_list = cb_cliprdr_format_list;
        cliprdr->format_list_response = cb_cliprdr_format_list_response;
        cliprdr->data_request = cb_cliprdr_data_request;
        cliprdr->data_response = cb_cliprdr_data_response;
        chan_index = gcc_net->channelCount;
        chan = &gcc_net->channelDefArray[chan_index];
        memcpy(chan->name, "CLIPRDR", 8);
        chan->options = 0;
        svc->channels[chan_index].user = self;
        svc->channels[chan_index].process_data = cb_svc_cliprdr_process_data;
        gcc_net->channelCount += 1;

        // setup rdpsnd
        rv = rdpsnd_create(&rdpsnd);
        NSLog(@"RDPSession initWithSettings: rdpsnd_create rv %d", rv);
        if (rv != LIBRDPSND_ERROR_NONE)
        {
            return nil;
        }
        rdpsnd->user = self;
        rdpsnd->log_msg = cb_rdpsnd_log_msg;
        rdpsnd->send_data = cb_rdpsnd_svc_send_data;
        rdpsnd->process_close = cb_rdpsnd_process_close;
        rdpsnd->process_wave = cb_rdpsnd_process_wave;
        rdpsnd->process_training = cb_rdpsnd_process_training;
        rdpsnd->process_formats = cb_rdpsnd_process_formats;
        chan_index = gcc_net->channelCount;
        chan = &gcc_net->channelDefArray[chan_index];
        memcpy(chan->name, "RDPSND\0", 8);
        chan->options = 0;
        svc->channels[chan_index].user = self;
        svc->channels[chan_index].process_data = cb_svc_rdpsnd_process_data;
        gcc_net->channelCount += 1;

        // setup edisp
        rv = edisp_create(&edisp);
        NSLog(@"RDPSession initWithSettings: edisp_create rv %d", rv);
        if (rv != LIBEDISP_ERROR_NONE)
        {
            return nil;
        }
        edisp->user = self;
        edisp->log_msg = cb_edisp_log_msg;
        edisp->send_data = cb_edisp_drdynvc_send_data;
        edisp->process_caps = cb_edisp_process_caps;

        connectInfo = aconnectInfo;
        [connectInfo retain];
        in_data_size = 128 * 1024;
        in_data = (char*)malloc(in_data_size);

        drdynvc_svc_channel_id = 0;
        edisp_drdynvc_channel_id = 0xFFFFFFFF;
        egfx_drdynvc_channel_id = 0xFFFFFFFF;

    }
    return self;
}

//*****************************************************************************
-(int)logMsg:(const char*)msg
{
    NSLog(@"%s", msg);
}

//*****************************************************************************
-(int)sendToServer:(void*)adata :(uint32_t)abytes
{
    //NSLog(@"sendToServer:");
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
        //NSLog(@"sendToServer: save_bytes %ld send_rv %d", save_bytes, send_rv);
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
-(int)drawImage:(unsigned int)src_width :(unsigned int)src_height
        :(int)dst_left :(int)dst_top
        :(unsigned int)dst_width :(unsigned int)dst_height
        :(char*)pixels :(struct rfx_rect*)clips :(unsigned int)num_clips
{
    CGColorSpaceRef colorSpace;
    CGContextRef context;
    CGImageRef image;
    NSRect rect;
    NSRect clip;
    NSRect* ns_clips;
    int index;

    //NSLog(@"drawImage:");
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        CGContextSaveGState(bs_context);
        clip = NSMakeRect(dst_left, dst_top, dst_width, dst_height);
        clip = [self flipRect:clip];
        CGContextClipToRect(bs_context, clip);
        if (num_clips > 0)
        {
            // convert clips
            ns_clips = (NSRect*)malloc(sizeof(NSRect) * num_clips);
            if (ns_clips != NULL)
            {
                for (index = 0; index < num_clips; index++)
                {
                    rect = NSMakeRect(clips[index].x, clips[index].y,
                            clips[index].cx, clips[index].cy);
                    ns_clips[index] = [self flipRect:rect];
                }
                CGContextClipToRects(bs_context, ns_clips, num_clips);
                free(ns_clips);
            }
        }
        context = CGBitmapContextCreate(pixels,
                src_width, src_height, 8, src_width * 4, colorSpace,
                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        if (context != NULL)
        {
            image = CGBitmapContextCreateImage(context);
            if (image != NULL)
            {
                // must be src_width and src_height or else
                // CGContextDrawImage will stretch
                rect = NSMakeRect(dst_left, dst_top, src_width, src_height);
                rect = [self flipRect:rect];
                CGContextDrawImage(bs_context, rect, image);
                CGImageRelease(image);
            }
            CGContextRelease(context);
        }
        CGContextRestoreGState(bs_context);
        CGColorSpaceRelease(colorSpace);
        [view invalidate:clip :bs_width :bs_height];
    }
    return 0;
}

//*****************************************************************************
-(int)bitmapUpdate:(struct bitmap_data_t*)abitmap_data
{
    //NSLog(@"RDPSession bitmapUpdate:");
    uint32_t size = abitmap_data->width * abitmap_data->height * 4;
    if (size == 0)
    {
        return 0;
    }
    if (size > rle_ddata_len)
    {
        free(rle_ddata_ptr);
        free(rle_tdata_ptr);
        rle_ddata_ptr = (char*)malloc(size);
        rle_tdata_ptr = (char*)malloc(size);
        rle_ddata_len = size;
    }
    if (abitmap_data->bitmap_data != NULL)
    {
        int rv = bitmap_decompress(abitmap_data->bitmap_data,
                    rle_ddata_ptr,
                    abitmap_data->width, abitmap_data->height,
                    abitmap_data->bitmap_data_len,
                    abitmap_data->bits_per_pixel,
                    rle_tdata_ptr);
        //NSLog(@"RDPSession bitmapUpdate: rv %d", rv);
        // inclusive right and bottom
        uint32_t dest_width = abitmap_data->dest_right -
                abitmap_data->dest_left + 1;
        uint32_t dest_height = abitmap_data->dest_bottom -
                abitmap_data->dest_top + 1;
        int draw_image_rv = [self drawImage
                :abitmap_data->width :abitmap_data->height
                :abitmap_data->dest_left :abitmap_data->dest_top
                :dest_width :dest_height :rle_ddata_ptr :NULL :0];
        if (draw_image_rv != 0)
        {
            return 1;
        }
    }
    return 0;
}

//*****************************************************************************
-(int)setSurfaceBits:(struct bitmap_data_ex_t*)abitmap_data
{
    //NSLog(@"RDPSession setSurfaceBits: codec_id %d", abitmap_data->codec_id);
    if (abitmap_data->codec_id == CODEC_ID_REMOTEFX)
    {
        int width = abitmap_data->width;
        int height = abitmap_data->height;
        int awidth = (width + 63) & ~63;
        int aheight = (height + 63) & ~63;
        if ((rfxdecoder == NULL) ||
                (awidth > rfxwidth) || (aheight > rfxheight))
        {
            free(ddata_ptr);
            rfxcodec_decode_destroy(rfxdecoder);
            rfxdecoder = NULL;
            ddata_len = awidth * aheight * 4;
            ddata_ptr = (char*)malloc(ddata_len);
            if (ddata_ptr == NULL)
            {
                ddata_len = 0;
                return 1;
            }
            int rv = rfxcodec_decode_create_ex(awidth, aheight,
                    RFX_FORMAT_BGRA, RFX_FLAGS_SAFE, &rfxdecoder);
            //NSLog(@"rfxcodec_decode_create_ex rv %d awidth %d aheight %d",
            //        rv, awidth, aheight);
            if (rv != 0)
            {
                free(ddata_ptr);
                ddata_ptr = NULL;
                ddata_len = 0;
                return 2;
            }
            rfxwidth = awidth;
            rfxheight = aheight;
        }
        if (rfxdecoder != NULL)
        {
            struct rfx_rect* rects = NULL;
            int num_rects = 0;
            struct rfx_tile* tiles = NULL;
            int num_tiles = 0;
            int rv = rfxcodec_decode_ex(rfxdecoder,
                    abitmap_data->bitmap_data, abitmap_data->bitmap_data_len,
                    ddata_ptr, awidth, aheight, awidth * 4,
                    &rects, &num_rects, &tiles, &num_tiles, 0);
            //NSLog(@"rfxcodec_decode_ex rv %d num_rects %d num_tiles %d",
            //        rv, num_rects, num_tiles);
            if (rv != 0)
            {
                return 3;
            }
            // exclusive right and bottom
            uint32_t dest_width = abitmap_data->dest_right -
                    abitmap_data->dest_left;
            uint32_t dest_height = abitmap_data->dest_bottom -
                    abitmap_data->dest_top;
            int draw_image_rv = [self drawImage :awidth :aheight
                    :abitmap_data->dest_left :abitmap_data->dest_top
                    :dest_width :dest_height :ddata_ptr :rects :num_rects];
            if (draw_image_rv != 0)
            {
                NSLog(@"setSurfaceBits: draw_image_rv %d", draw_image_rv);
                return 5;
            }
        }
    }
    return 0;
}

//*****************************************************************************
-(int)frameMarker:(uint16_t)frame_action :(uint32_t)frame_id
{
    //NSLog(@"RDPSession frameMarker:");
    if (frame_action == SURFACECMD_FRAMEACTION_END)
    {
        rdpc_send_frame_ack(rdpc, frame_id);
    }
    return 0;
}

//*****************************************************************************
static uint32_t
getPointerPixel(uint8_t* data, uint16_t bpp,
        uint32_t width, uint32_t height, size_t x, size_t y)
{
    if (bpp == 32)
    {
        size_t offset = y * width * 4 + x * 4;
        uint32_t pixel = data[offset + 3];
        pixel = (pixel << 8) | data[offset + 2];
        pixel = (pixel << 8) | data[offset + 1];
        pixel = (pixel << 8) | data[offset];
        return pixel;
    }
    else if (bpp == 24)
    {
        size_t offset = y * width * 3 + x * 3;
        uint32_t pixel = data[offset];
        pixel = (pixel << 8) | data[offset + 1];
        pixel = (pixel << 8) | data[offset + 2];
        return pixel | 0xFF000000;
    }
    else if (bpp == 16)
    {
        size_t offset = y * width * 2 + x * 2;
        uint32_t pixel = data[offset + 1];
        pixel = (pixel << 8) | data[offset];
        uint32_t r = (pixel & 0xF800) >> 11;
        uint32_t g = (pixel & 0x07E0) >> 5;
        uint32_t  b = pixel * 0x001F;
        r = (r << 3) | (r >> 2);
        g = (g << 2) | (g >> 4);
        b = (b << 3) | (b >> 2);
        return (r << 16) | (g << 8) | b | 0xFF000000;
    }
    else if (bpp == 15)
    {
        size_t offset = y * width * 2 + x * 2;
        uint32_t pixel = data[offset + 1];
        pixel = (pixel << 8) | data[offset];
        uint32_t r = (pixel & 0x7C00) >> 10;
        uint32_t g = (pixel & 0x3E0) >> 5;
        uint32_t b = pixel * 0x001F;
        r = (r << 3) | (r >> 2);
        g = (g << 3) | (g >> 2);
        b = (b << 3) | (b >> 2);
        return (r << 16) | (g << 8) | b | 0xFF000000;
    }
    else if (bpp == 1)
    {
        uint32_t lwidth = (width + 7) / 8;
        uint32_t start = (y * lwidth) + x / 8;
        uint32_t shift = x % 8;
        uint32_t pixel = data[start];
        uint32_t mask = 0x80;
        while (shift > 0)
        {
            mask >>= 1;
            shift -= 1;
        }
        pixel = ((pixel & mask) != 0) ? 0xFFFFFFFF : 0xFF000000;
        return pixel;
    }
    return 0;
}

//*****************************************************************************
-(uint8_t*)getCursorPixels:(struct pointer_t*)apointer
{
    uint32_t y;
    uint32_t x;
    uint32_t apixel;
    uint32_t xpixel;
    uint32_t yup;
    uint32_t bpp = (apointer->xor_bpp == 0) ? 24 : apointer->xor_bpp;
    uint32_t w = apointer->width;
    uint32_t h = apointer->height;
    uint8_t* and_data = apointer->and_mask_data;
    uint8_t* xor_data = apointer->xor_mask_data;
    uint32_t* pixels = (uint32_t*)malloc(apointer->width * apointer->height * 4);

    if (pixels == NULL)
    {
        return NULL;
    }
    for (y = 0; y < h; y++)
    {
        yup = (h - 1) - y;
        for (x = 0; x < w; x++)
        {
            apixel = getPointerPixel(and_data, 1, w, h, x, yup);
            xpixel = getPointerPixel(xor_data, bpp, w, h, x, yup);
            if ((apixel & 0xFFFFFF) != 0)
            {
                if ((xpixel & 0xFFFFFF) == 0xFFFFFF)
                {
                    // use pattern (not solid black) for xor area
                    xpixel = ((x & 1) == (y & 1)) ? 0xFFFFFFFF : 0xFF000000;
                }
                else if (xpixel == 0xFF000000)
                {
                    xpixel = 0;
                }
            }
            pixels[w * y + x] = xpixel;
        }
    }
    return (uint8_t*)pixels;
}

//*****************************************************************************
-(int)pointerUpdate:(struct pointer_t*)apointer
{
    NSLog(@"RDPSession pointerUpdate: bpp %d width %d height %d",
            apointer->xor_bpp, apointer->width, apointer->height);
    uint8_t* cursor_data = [self getCursorPixels:apointer];
    if (cursor_data == NULL)
    {
        return 0;
    }
    NSBitmapImageRep* bmiRep;
    bmiRep = [NSBitmapImageRep alloc];
    if (bmiRep != nil)
    {
        [bmiRep initWithBitmapDataPlanes:&cursor_data
                pixelsWide:apointer->width
                pixelsHigh:apointer->height
                bitsPerSample:8
                samplesPerPixel:4
                hasAlpha:YES
                isPlanar:NO
                colorSpaceName:NSDeviceRGBColorSpace
                bitmapFormat:0
                bytesPerRow:apointer->width * 4
                bitsPerPixel:0];
        NSImage* image = [NSImage alloc];
        if (image != nil)
        {
            [image initWithSize:[bmiRep size]];
            [image addRepresentation: bmiRep];
            NSCursor* cur = [NSCursor alloc];
            if (cur != nil)
            {
                NSPoint hotspot = NSMakePoint(apointer->hotx,
                        apointer->hoty);
                [cur initWithImage:image hotSpot:hotspot];
                if (apointer->cache_index < MAX_CURSORS)
                {
                    [cur retain];
                    [cursors[apointer->cache_index] release];
                    cursors[apointer->cache_index] = cur;
                }
                [view setCursor:cur];
                [cur release];
            }
            else
            {
                NSLog(@"RDPSession pointerUpdate: NSCursor failed");
            }
            [image release];
        }
        else
        {
            NSLog(@"RDPSession pointerUpdate: NSImage failed");
        }
        [bmiRep release];
    }
    else
    {
        NSLog(@"RDPSession pointerUpdate: NSBitmapImageRep failed");
    }
    free(cursor_data);
    return 0;
}

//*****************************************************************************
-(int)pointerCached:(uint16_t)cache_index
{
    NSLog(@"RDPSession pointerCached: cache_index %d", cache_index);
    if (cache_index < MAX_CURSORS)
    {
        NSCursor* cur = cursors[cache_index];
        [view setCursor:cur];
    }
    return 0;
}

//*****************************************************************************
-(int)pointerSystem:(uint32_t)id
{
    NSLog(@"RDPSession pointerSystem:");
    if (id == 0)
    {
        [view setCursor:nil];
    }
    else
    {
        NSCursor* cur = [NSCursor arrowCursor];
        [view setCursor:cur];
    }
    return 0;
}

//*****************************************************************************
-(int)pointerPos:(uint16_t)x :(uint16_t)y
{
    NSLog(@"RDPSession pointerPos:");
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
    //NSLog(@"readProcessServerData:");
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
    //NSLog(@"readProcessServerData: recv_rv %d", recv_rv);
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
                NSLog(@"readProcessServerData: rdpc_process_server_data "
                        "failed rv %d", rv);
                return 3;
            }
        }
    }
    return 0;
}

//*****************************************************************************
-(int)processWriteServerData
{
    //NSLog(@"processWriteServerData:");
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
        [self resizeBackingStore:width :height];
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
        //NSLog(@"processWriteServerData: bytes %ld send_rv %d", bytes, send_rv);
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
    //NSLog(@"sendMouseMovedEvent: x %d y %d", x, y);
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
        case 4:
            flags = PTRXFLAGS_DOWN | PTRXFLAGS_BUTTON1;
            rdpc_send_mouse_event_ex(rdpc, flags, x, y);
            return;
        case 5:
            flags = PTRXFLAGS_DOWN | PTRXFLAGS_BUTTON2;
            rdpc_send_mouse_event_ex(rdpc, flags, x, y);
            return;
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
        case 4:
            flags = PTRXFLAGS_BUTTON1;
            rdpc_send_mouse_event_ex(rdpc, flags, x, y);
            return;
        case 5:
            flags = PTRXFLAGS_BUTTON2;
            rdpc_send_mouse_event_ex(rdpc, flags, x, y);
            return;
        default: return;
    }
    rdpc_send_mouse_event(rdpc, flags, x, y);
}

//*****************************************************************************
-(void)sendMouseWheel:(int)delta :(bool)isHorizontal :(uint16_t)x :(uint16_t)y
{
    uint16_t flags = isHorizontal ? PTRFLAGS_HWHEEL : PTRFLAGS_WHEEL;
    bool is_neg = false;
    if (delta < 0)
    {
        flags |= PTRFLAGS_WHEEL_NEGATIVE;
        delta *= -1;
        is_neg = true;
    }
    while (delta > 0)
    {
        int ldelta = delta > 0xFF ? 0xFF : delta;
        flags &= 0xFF00;
        flags |= (is_neg ? -ldelta : ldelta) & 0xFF;
        if (rdpc_send_mouse_event(rdpc, flags, x, y) != 0)
        {
            return;
        }
        delta -= ldelta;
    }
}

//*****************************************************************************
-(int)sendKeyboardScancode:(uint16_t)flags :(uint16_t)code
{
    NSLog(@"sendKeyboardScancode: flags 0x%4.4X code 0x%4.4X",
            (uint32_t)flags, (uint32_t)code);
    if (rdpc_send_keyboard_scancode(rdpc, flags, code) != 0)
    {
        return 1;
    }
    return 0;
}

//*****************************************************************************
-(int)sendKeyboardSync:(uint32_t)toggleFlags
{
    NSLog(@"sendKeyboardSync:");
    if (rdpc_send_keyboard_sync(rdpc, toggleFlags) != 0)
    {
        return 1;
    }
    return 0;
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
    //NSLog(@"doRead:");
    int rv = [self readProcessServerData];
    if (rv != 0)
    {
        NSLog(@"doRead: readProcessServerData failed rv %d", rv);
        [app terminate:self];
        return;
    }
    [self setupRunLoop];
}

//*****************************************************************************
-(void)doWrite;
{
    //NSLog(@"doWrite:");
    int rv = [self processWriteServerData];
    if (rv != 0)
    {
        NSLog(@"doRead: processWriteServerData failed rv %d", rv);
        [app terminate:self];
        return;
    }
    [self setupRunLoop];
}

//*****************************************************************************
-(NSRect)flipRect:(NSRect)arect
{
    CGFloat height = bs_height;
    arect.origin.y = (height - arect.origin.y) - arect.size.height;
    return arect;
}

//*****************************************************************************
-(int)resizeBackingStore:(int)width :(int)height
{
    NSLog(@"resizeBackingStore:");

    if ((width == bs_width) && (height == bs_height))
    {
        return 0;
    }
    // create new backing store, copy old to new
    CGContextRef save_bs_context = bs_context;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        bs_context = CGBitmapContextCreate(NULL,
                width, height, 8, 0, colorSpace,
                kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(colorSpace);
    }
    if (bs_context == NULL)
    {
        NSLog(@"resizeBackingStore: failed to create bs_context");
        return 1;
    }
    if (save_bs_context != NULL)
    {
        CGImageRef cgImage = CGBitmapContextCreateImage(save_bs_context);
        if (cgImage != NULL)
        {
            CGContextSaveGState(bs_context);
            NSRect rect = NSMakeRect(0, 0, bs_width, bs_height);
            rect = [self flipRect:rect];
            CGContextDrawImage(bs_context, rect, cgImage);
            CGContextRestoreGState(bs_context);
            CGImageRelease(cgImage);
        }
        CGContextRelease(save_bs_context);
    }
    bs_width = width;
    bs_height = height;
    return 0;
}

//*****************************************************************************
-(int)createWindow:(int)width :(int)height
{
    NSLog(@"createWindow:");
    // create window
    MClientWindow* window = [MClientWindow alloc];
    NSWindowStyleMask mask = NSTitledWindowMask | NSResizableWindowMask |
            NSMiniaturizableWindowMask | NSClosableWindowMask;
    [window
        initWithContentRect:NSMakeRect(0, 0, width, height)
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
    [view setSessionApp:self :app];
    // add view
    [[window contentView] addSubview:view];
    return 0;
}

//*****************************************************************************
-(CGContextRef)getBackingStore
{
    return bs_context;
}

//*****************************************************************************
-(int)drdynvcProcessCapRequest
        :(uint16_t)channel_id :(uint16_t)version
        :(uint16_t)pc0 :(uint16_t)pc1
        :(uint16_t)pc2 :(uint16_t)pc3
{
    return drdynvc_send_cap_response(drdynvc, channel_id, version);
}

static const NSString* g_edisp_name = @"Microsoft::Windows::RDS::DisplayControl";
static const NSString* g_egfx_name = @"Microsoft::Windows::RDS::Graphics";

//*****************************************************************************
-(int)drdynvcProcessCreateRequest
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(NSString*)channel_name
{
    if ([channel_name isEqualToString:g_edisp_name])
    {
        drdynvc_svc_channel_id = channel_id;
        edisp_drdynvc_channel_id = drdynvc_channel_id;
        return drdynvc_send_create_response(drdynvc, channel_id,
                drdynvc_channel_id, 0);
    }
    else if ([channel_name isEqualToString:g_egfx_name])
    {
        drdynvc_svc_channel_id = channel_id;
        egfx_drdynvc_channel_id = drdynvc_channel_id;
        return drdynvc_send_create_response(drdynvc, channel_id,
                drdynvc_channel_id, 0);
    }
    else
    {
        return drdynvc_send_create_response(drdynvc, channel_id,
                drdynvc_channel_id, 1);
    }
    return 0;
}

//*****************************************************************************
-(int)drdynvcProcessDataFirst
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(uint32_t)total_bytes :(void*)data :(uint32_t)bytes
{
    return 0;
}

//*****************************************************************************
-(int)drdynvcProcessData
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(void*)data :(uint32_t)bytes
{
    if (drdynvc_channel_id == edisp_drdynvc_channel_id)
    {
        if (edisp_process_data(edisp, channel_id, drdynvc_channel_id,
                data, bytes) != LIBEDISP_ERROR_NONE)
        {
            return LIBDRDYNVC_ERROR_DATA;
        }
    }
    return LIBDRDYNVC_ERROR_NONE;
}

//*****************************************************************************
-(int)drdynvcProcessClose
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
{
    return 0;
}

//*****************************************************************************
-(int)cliprdrReady
        :(uint16_t)channel_id
        :(uint32_t)version
        :(uint32_t)general_flags
{
    return 0;
}

//*****************************************************************************
-(int)cliprdrFormatList
        :(uint16_t)channel_id
        :(uint16_t)msg_flags
        :(uint32_t)num_formats
        :(struct cliprdr_format_t*)formats
{
    return 0;
}

//*****************************************************************************
-(int)cliprdrFormatListResponse
        :(uint16_t)channel_id
        :(uint16_t)mfg_flags
{
    return 0;
}

//*****************************************************************************
-(int)cliprdrDataRequest
        :(uint16_t)channel_id
        :(uint32_t)requested_format_id
{
    return 0;
}

//*****************************************************************************
-(int)cliprdrDataResponse
        :(uint16_t)channel_id
        :(uint16_t)msg_flags
        :(void*)requested_format_data
        :(uint32_t)requested_format_data_bytes
{
    return 0;
}

//*****************************************************************************
-(int)rdpsndProcessClose
        :(uint16_t)channel_id
{
    return 0;
}

//*****************************************************************************
-(int)rdpsndProcessWave
        :(uint16_t)channel_id
        :(uint16_t)time_stamp
        :(uint16_t)format_no
        :(void*)data
        :(uint32_t)bytes
{
    return 0;
}

//*****************************************************************************
-(int)rdpsndProcessTraining
        :(uint16_t)channel_id
        :(uint16_t)time_stamp
        :(uint16_t)pack_size
        :(void*)data
        :(uint32_t)bytes
{
    return 0;
}

//*****************************************************************************
-(int)rdpsndProcessFormats
        :(uint16_t)channel_id
        :(uint32_t)flags
        :(uint32_t)volume
        :(uint32_t)pitch
        :(uint16_t)dgram_port
        :(uint16_t)version
        :(uint16_t)block_no
        :(uint16_t)num_formats
        :(struct rdpsnd_format_t*)formats
{
    return 0;
}

//*****************************************************************************
-(int)edispProcessCaps
        :(uint16_t)channel_id
        :(uint32_t)drdynvc_channel_id
        :(uint32_t)max_num_monitor
        :(uint32_t)max_monitor_area_factor_a
        :(uint32_t)max_monitor_area_factor_b
{
    return 0;
}

//*****************************************************************************
-(struct rdpc_t*)getRdpc
{
    return rdpc;
}

//*****************************************************************************
-(struct svc_channels_t*)getSvc
{
    return svc;
}

//*****************************************************************************
-(struct drdynvc_t*)getDrdynvc
{
    return drdynvc;
}

//*****************************************************************************
-(struct cliprdr_t*)getCliprdr
{
    return cliprdr;
}

-(struct rdpsnd_t*)getRdpsnd
{
    return rdpsnd;
}

@end
