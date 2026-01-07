
@interface RDPConnect : NSObject
{
    NSString* serverName;
    NSString* serverPort;
}

-(void)setServerName:(NSString*)aserverName;
-(NSString*)getServerName;
-(void)setServerPort:(NSString*)aserverPort;
-(NSString*)getServerPort;

@end

struct send_t
{
    size_t sent;
    size_t out_data_bytes;
    char* out_data;
    struct send_t* next;
};

#define MAX_CURSORS 64

@class MClientView;

@interface RDPSession : NSObject
{
    struct rdpc_t* rdpc;
    RDPConnect* connectInfo;
    int sck;
    bool connected;
    char* in_data;
    size_t in_data_size;
    size_t recv_start;
    struct send_t* send_head;
    struct send_t* send_tail;

    NSApplication* app;
    NSString* appName;
    NSString* appVersion;
    CFSocketRef socketRef;
    CFRunLoopSourceRef runLoopSourceRef;
    bool setupWithWantWrite;
    MClientView* view;

    // set_surface_bits
    void* rfxdecoder;
    uint32_t rfxwidth;
    uint32_t rfxheight;
    char* ddata_ptr;
    size_t ddata_len;

    // bitmap_update
    char* rle_ddata_ptr;
    char* rle_tdata_ptr;
    size_t rle_ddata_len;

    CGContextRef bs_context;
    int bs_width;
    int bs_height;

    NSCursor* cursors[MAX_CURSORS];

    struct svc_channels_t* svc;
    struct drdynvc_t* drdynvc;
    struct cliprdr_t* cliprdr;
    struct rdpsnd_t* rdpsnd;
    struct edisp_t* edisp;

    uint16_t drdynvc_svc_channel_id;
    uint32_t edisp_drdynvc_channel_id;
    uint32_t egfx_drdynvc_channel_id;

}

-(RDPSession*)initWithSettings
        :(struct rdpc_settings_t*)asettings
        :(RDPConnect*)aconnectInfo;

-(int)logMsg:(const char*)msg;
-(int)sendToServer:(void*)adata :(uint32_t)abytes;
-(int)bitmapUpdate:(struct bitmap_data_t*)abitmap_data;
-(int)setSurfaceBits:(struct bitmap_data_ex_t*)abitmap_data;
-(int)frameMarker:(uint16_t)frame_action :(uint32_t)frame_id;
-(int)pointerUpdate:(struct pointer_t*)apointer;
-(int)pointerCached:(uint16_t)cache_index;
-(int)pointerSystem:(uint32_t)id;
-(int)pointerPos:(uint16_t)x :(uint16_t)y;

-(int)connectToServer;
-(int)readProcessServerData;
-(int)processWriteServerData;

-(void)sendMouseMovedEvent:(uint16_t)x :(uint16_t)y;
-(void)sendMouseDownEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y;
-(void)sendMouseUpEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y;
-(void)sendMouseWheel:(int)delta :(bool)isHorizontal :(uint16_t)x :(uint16_t)y;
-(int)sendKeyboardScancode:(uint16_t)flags :(uint16_t)code;
-(int)sendKeyboardSync:(uint32_t)toggleFlags;

-(void)setApp:(NSApplication*)aapp;
-(void)setAppName:(NSString*)aappName;
-(void)setAppVersion:(NSString*)aappVersion;
-(void)setupRunLoop;
-(void)doRead;
-(void)doWrite;

-(int)createWindow:(int)width :(int)height;

-(CGContextRef)getBackingStore;

-(int)drdynvcProcessCapRequest
        :(uint16_t)channel_id :(uint16_t)version
        :(uint16_t)pc0 :(uint16_t)pc1
        :(uint16_t)pc2 :(uint16_t)pc3;
-(int)drdynvcProcessCreateRequest
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(NSString*)channel_name;
-(int)drdynvcProcessDataFirst
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(uint32_t)total_bytes :(void*)data :(uint32_t)bytes;
-(int)drdynvcProcessData
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id
        :(void*)data :(uint32_t)bytes;
-(int)drdynvcProcessClose
        :(uint16_t)channel_id :(uint32_t)drdynvc_channel_id;

-(int)cliprdrReady
        :(uint16_t)channel_id
        :(uint32_t)version
        :(uint32_t)general_flags;
-(int)cliprdrFormatList
        :(uint16_t)channel_id
        :(uint16_t)msg_flags
        :(uint32_t)num_formats
        :(struct cliprdr_format_t*)formats;
-(int)cliprdrFormatListResponse
        :(uint16_t)channel_id
        :(uint16_t)mfg_flags;
-(int)cliprdrDataRequest
        :(uint16_t)channel_id
        :(uint32_t)requested_format_id;
-(int)cliprdrDataResponse
        :(uint16_t)channel_id
        :(uint16_t)msg_flags
        :(void*)requested_format_data
        :(uint32_t)requested_format_data_bytes;

-(int)rdpsndProcessClose
        :(uint16_t)channel_id;
-(int)rdpsndProcessWave
        :(uint16_t)channel_id
        :(uint16_t)time_stamp
        :(uint16_t)format_no
        :(void*)data
        :(uint32_t)bytes;
-(int)rdpsndProcessTraining
        :(uint16_t)channel_id
        :(uint16_t)time_stamp
        :(uint16_t)pack_size
        :(void*)data
        :(uint32_t)bytes;
-(int)rdpsndProcessFormats
        :(uint16_t)channel_id
        :(uint32_t)flags
        :(uint32_t)volume
        :(uint32_t)pitch
        :(uint16_t)dgram_port
        :(uint16_t)version
        :(uint16_t)block_no
        :(uint16_t)num_formats
        :(struct rdpsnd_format_t*)formats;

-(int)edispProcessCaps
        :(uint16_t)channel_id
        :(uint32_t)drdynvc_channel_id
        :(uint32_t)max_num_monitor
        :(uint32_t)max_monitor_area_factor_a
        :(uint32_t)max_monitor_area_factor_b;

-(struct rdpc_t*)getRdpc;
-(struct svc_channels_t*)getSvc;
-(struct drdynvc_t*)getDrdynvc;
-(struct cliprdr_t*)getCliprdr;
-(struct rdpsnd_t*)getRdpsnd;

@end
