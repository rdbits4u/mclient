
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

    void* rfxdecoder;
    char* ddata_ptr;
    size_t ddata_len;

}

-(RDPSession*)initWithSettings
        :(struct rdpc_settings_t*)asettings
        :(RDPConnect*)aconnectInfo;

-(int)sendToServer:(void*)adata :(uint32_t)abytes;
-(int)setSurfaceBits:(struct bitmap_data_t*)abitmap_data;
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

-(void)setApp:(NSApplication*)aapp;
-(void)setAppName:(NSString*)aappName;
-(void)setAppVersion:(NSString*)aappVersion;
-(void)setupRunLoop;
-(void)doRead;
-(void)doWrite;

-(int)createWindow:(int)awidth :(int)aheight;

@end
