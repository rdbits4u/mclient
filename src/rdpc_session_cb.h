
#if !defined(__RDPC_SESSION_CB_H)
#define __RDPC_SESSION_CB_H

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
    //NSLog(@"cb_rdpc_send_to_server:");
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
// int (*bitmap_update)(struct rdpc_t* rdpc,
//                      struct bitmap_data_ex_t* bitmap_data);
static int
cb_rdpc_bitmap_update(struct rdpc_t* rdpc,
                         struct bitmap_data_t* bitmap_data)
{
    //NSLog(@"cb_rdpc_bitmap_update:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            if (bitmap_data != NULL)
            {
                RDPSession* session = (RDPSession*)(rdpc->user);
                [session bitmapUpdate:bitmap_data];
                return LIBRDPC_ERROR_NONE;
            }
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
// callback
// int (*set_surface_bits)(struct rdpc_t* rdpc,
//                         struct bitmap_data_ex_t* bitmap_data);
static int
cb_rdpc_set_surface_bits(struct rdpc_t* rdpc,
                         struct bitmap_data_ex_t* bitmap_data)
{
    //NSLog(@"cb_rdpc_set_surface_bits:");
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
    //NSLog(@"cb_rdpc_frame_marker:");
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
// callback
// int (*pointer_system)(struct rdpc_t* rdpc,
//                       uint32_t id);
static int
cb_rdpc_pointer_system(struct rdpc_t* rdpc, uint32_t id)
{
    NSLog(@"cb_rdpc_pointer_system:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session pointerSystem:id];
            return LIBRDPC_ERROR_NONE;
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

//*****************************************************************************
// callback
// int (*pointer_pos)(struct rdpc_t* rdpc,
//                    uint16_t x, uint16_t y);
static int
cb_rdpc_pointer_pos(struct rdpc_t* rdpc, uint16_t x, uint16_t y)
{
    NSLog(@"cb_rdpc_pointer_pos:");
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session pointerPos:x :y];
            return LIBRDPC_ERROR_NONE;
        }
    }
    return LIBRDPC_ERROR_PARAM;
}

#endif