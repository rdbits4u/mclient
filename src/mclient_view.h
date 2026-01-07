
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
    NSRect contentRect;
    RDPSession* session;
    struct rdp_key_code_t keymap[256];
    uint32_t last_mod_flags;
    bool need_keyboard_sync;
    NSPoint bs_origin;
    NSTimer* resizeTimer;
    NSCursor* last_cur;
}

-(void)setSessionApp:(RDPSession*)asession :(NSApplication*)aapp;
-(void)focusIn;
-(void)focusOut;
-(void)invalidate:(NSRect)arect :(int)width :(int)height;
-(void)setCursor:(NSCursor*)cur;

@end
