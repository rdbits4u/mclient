
struct rdp_key_code_t
{
    uint16_t code;
    uint16_t flags[2];
    bool is_down;
};

@class RDPSession;

@interface MClientView : NSView
{
    NSApplication* app;
    NSPoint origin;
    NSSize content_size;
    RDPSession* session;
    CGContextRef bs_context;
    struct rdp_key_code_t keymap[256];
    uint32_t last_mod_flags;
    bool need_keyboard_sync;
}

-(int)drawImage:(unsigned int)src_width :(unsigned int)src_height
        :(int)dst_left :(int)dst_top
        :(unsigned int)dst_width :(unsigned int)dst_height
        :(char*)pixels :(struct rfx_rect*)clips :(unsigned int)num_clips;
-(void)setSessionApp:(RDPSession*)asession :(NSApplication*)aapp;
-(void)focusIn;
-(void)focusOut;

@end
