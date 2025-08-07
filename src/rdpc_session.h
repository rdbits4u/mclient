
#import <Cocoa/Cocoa.h>
#include <librdpc.h>

struct send_t
{
    size_t sent;
    size_t out_data_bytes;
    char* out_data;
    struct send_t* next;
};

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

@interface RDPSession : NSObject
{
    struct rdpc_t* rdpc;
    RDPConnect* connectInfo;
    int sck;
    bool connected;
    char* in_data;
    int in_data_size;
    int recv_start;
    struct send_t* send_head;
    struct send_t* send_tail;

    NSApplication* app;
    NSString* appName;
    NSString* appVersion;
    CFSocketRef socketRef;
    CFRunLoopSourceRef runLoopSourceRef;
    bool setupWithWantWrite;

}

-(RDPSession*)initWithSettings
        :(struct rdpc_settings_t*)asettings
        :(RDPConnect*)aconnectInfo;

-(int)sendToServer:(void*)adata :(uint32_t)abytes;
-(int)setSurfaceBits:(struct bitmap_data_t*)abitmap_data;
-(int)frameMarker:(uint16_t)frame_action :(uint32_t)frame_id;
-(int)connectToServer;
-(int)readProcessServerData;
-(int)processWriteServerData;

-(void)sendMouseMovedEvent:(uint16_t)x :(uint16_t)y;
-(void)sendMouseDownEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y;
-(void)sendMouseUpEvent:(uint16_t)but :(uint16_t)x :(uint16_t)y;

-(void)setApp:(NSApplication*)aapp;
-(void)setAppName:(NSString*)aappName;
-(void)setAppVersion:(NSString*)aappVersion;
-(int)getSck;
-(bool)wantWrite;
-(void)setupRunLoop;
-(void)doRead;
-(void)doWrite;

@end
