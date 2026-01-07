
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
    //NSLog(@"cb_rdpc_log_msg: %s", msg);
    //return LIBRDPC_ERROR_NONE;

    int rv = LIBRDPC_ERROR_PARAM;
    if (rdpc != NULL)
    {
        if (rdpc->user != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpc->user);
            [session logMsg:msg];
            rv = LIBRDPC_ERROR_NONE;
        }
    }
    return rv;
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


//*****************************************************************************
// callback
// int (*log_msg)(struct svc_channels_t* svc, const char* msg);
static int
cb_svc_log_msg(struct svc_channels_t* svc, const char* msg)
{
    int rv = LIBSVC_ERROR_LOG;
    if (msg != NULL)
    {
        if (svc != NULL)
        {
            RDPSession* session = (RDPSession*)(svc->user);
            if (session != NULL)
            {
                [session logMsg:msg];
                rv = LIBSVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*send_data)(struct svc_channels_t* svc, uint16_t channel_id,
//                  uint32_t total_bytes, uint32_t flags,
//                  void* data, uint32_t bytes);
static int
cb_svc_send_data(struct svc_channels_t* svc, uint16_t channel_id,
        uint32_t total_bytes, uint32_t flags, void* data, uint32_t bytes)
{
    int rv = LIBSVC_ERROR_SEND_DATA;
    if (svc != NULL)
    {
        RDPSession* session = (RDPSession*)(svc->user);
        if (session != NULL)
        {
            struct rdpc_t* rdpc = [session getRdpc];
            if (rdpc_channel_send_data(rdpc, channel_id,
                    total_bytes, flags, data, bytes) == LIBRDPC_ERROR_NONE)
            {
                rv = LIBSVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*log_msg)(struct cliprdr_t* cliprdr, const char* msg);
static int
cb_drdynvc_log_msg(struct drdynvc_t* drdynvc, const char* msg)
{
    int rv = LIBDRDYNVC_ERROR_LOG;
    if (msg != NULL)
    {
        if (drdynvc != NULL)
        {
            RDPSession* session = (RDPSession*)(drdynvc->user);
            if (session != NULL)
            {
                [session logMsg:msg];
                rv = LIBDRDYNVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*send_data)(struct drdynvc_t* drdynvc, uint16_t channel_id,
//                  void* data, uint32_t bytes);
static int
cb_drdynvc_svc_send_data(struct drdynvc_t* drdynvc, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBDRDYNVC_ERROR_SEND_DATA;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            struct svc_channels_t* svc = [session getSvc];
            if (svc_send_data(svc, channel_id, data, bytes) ==
                    LIBSVC_ERROR_NONE)
            {
                rv = LIBDRDYNVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*capabilities_request)(struct drdynvc_t* drdynvc,
//                             uint16_t channel_id, uint16_t version,
//                             uint16_t pc0, uint16_t pc1,
//                             uint16_t pc2, uint16_t pc3);
static int
cb_drdynvc_process_cap_request(struct drdynvc_t* drdynvc,
        uint16_t channel_id, uint16_t version,
        uint16_t pc0, uint16_t pc1, uint16_t pc2, uint16_t pc3)
{
    int rv = LIBDRDYNVC_ERROR_CAP_REQUEST;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            rv = [session drdynvcProcessCapRequest
                    :channel_id :version
                    :pc0 :pc1 :pc2 :pc3];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_create_request)(struct drdynvc_t* drdynvc,
//                       uint16_t channel_id,
//                       uint32_t drdynvc_channel_id,
//                       const char* drdynvc_channel_name);
static int
cb_drdynvc_process_create_request(struct drdynvc_t* drdynvc,
        uint16_t channel_id, uint32_t drdynvc_channel_id,
        const char* drdynvc_channel_name)
{
    int rv = LIBDRDYNVC_ERROR_CREATE_REQUEST;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            if (drdynvc_channel_name != NULL)
            {
                NSString* channel_name = [[NSString alloc]
                        initWithUTF8String:drdynvc_channel_name];
                rv = [session drdynvcProcessCreateRequest
                        :channel_id :drdynvc_channel_id :channel_name];
                [channel_name release];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_data_first)(struct drdynvc_t* drdynvc,
//                           uint16_t channel_id,
//                           uint32_t drdynvc_channel_id,
//                           uint32_t total_bytes,
//                           void* data, uint32_t bytes);
static int
cb_drdynvc_process_data_first(struct drdynvc_t* drdynvc,
        uint16_t channel_id, uint32_t drdynvc_channel_id,
        uint32_t total_bytes, void* data, uint32_t bytes)
{
    int rv = LIBDRDYNVC_ERROR_DATA;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            if (data != NULL)
            {
                rv = [session drdynvcProcessDataFirst:channel_id
                        :drdynvc_channel_id :total_bytes :data :bytes];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_data)(struct drdynvc_t* drdynvc, uint16_t channel_id,
//                     uint32_t drdynvc_channel_id,
//                     void* data, uint32_t bytes);
static int
cb_drdynvc_process_data(struct drdynvc_t* drdynvc,
        uint16_t channel_id, uint32_t drdynvc_channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBDRDYNVC_ERROR_DATA;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            if (data != NULL)
            {
                rv = [session drdynvcProcessData:channel_id
                        :drdynvc_channel_id :data :bytes];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_close)(struct drdynvc_t* drdynvc, uint16_t channel_id,
//                      uint32_t drdynvc_channel_id);
static int
cb_drdynvc_process_close(struct drdynvc_t* drdynvc,
        uint16_t channel_id, uint32_t drdynvc_channel_id)
{
    int rv = LIBDRDYNVC_ERROR_CLOSE;
    if (drdynvc != NULL)
    {
        RDPSession* session = (RDPSession*)(drdynvc->user);
        if (session != NULL)
        {
            rv = [session drdynvcProcessClose:channel_id
                        :drdynvc_channel_id];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_data)(struct svc_t* svc, uint16_t channel_id,
//                     void* data, uint32_t bytes);
static int
cb_svc_drdynvc_process_data(struct svc_t* svc, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBSVC_ERROR_PROCESS_DATA;
    if (svc != NULL)
    {
        RDPSession* session = (RDPSession*)(svc->user);
        if (session != NULL)
        {
            struct drdynvc_t* drdynvc = [session getDrdynvc];
            if (drdynvc_process_data(drdynvc, channel_id,
                    data, bytes) == LIBDRDYNVC_ERROR_NONE)
            {
                rv = LIBSVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*log_msg)(struct cliprdr_t* cliprdr, const char* msg);
static int
cb_cliprdr_log_msg(struct cliprdr_t* cliprdr, const char* msg)
{
    int rv = LIBCLIPRDR_ERROR_LOG;
    if (msg!= NULL)
    {
        if (cliprdr != NULL)
        {
            RDPSession* session = (RDPSession*)(cliprdr->user);
            if (session != NULL)
            {
                [session logMsg:msg];
                rv = LIBCLIPRDR_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*send_data)(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                  void* data, uint32_t bytes);
static int
cb_cliprdr_svc_send_data(struct cliprdr_t* cliprdr, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBCLIPRDR_ERROR_SEND_DATA;
    if (cliprdr != NULL)
    {
        RDPSession* session = (RDPSession*)(cliprdr->user);
        if (session != NULL)
        {
            struct svc_channels_t* svc = [session getSvc];
            if (svc_send_data(svc, channel_id, data, bytes) ==
                    LIBSVC_ERROR_NONE)
            {
                rv = LIBCLIPRDR_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*ready)(struct cliprdr_t* cliprdr, uint32_t version,
//              uint32_t general_flags);
static int
cb_cliprdr_ready(struct cliprdr_t* cliprdr, uint16_t channel_id,
        uint32_t version, uint32_t general_flags)
{
    int rv = LIBCLIPRDR_ERROR_READY;
    if (cliprdr != NULL)
    {
        RDPSession* session = (RDPSession*)(cliprdr->user);
        if (session != NULL)
        {
            rv = [session cliprdrReady:channel_id :version :general_flags];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*format_list)(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                    uint16_t msg_flags, uint32_t num_formats,
//                    struct cliprdr_format_t* formats);
static int
cb_cliprdr_format_list(struct cliprdr_t* cliprdr, uint16_t channel_id,
        uint16_t msg_flags, uint32_t num_formats,
        struct cliprdr_format_t* formats)
{
    int rv = LIBCLIPRDR_ERROR_FORMAT_LIST;
    if (cliprdr != NULL)
    {
        if (formats != NULL)
        {
            RDPSession* session = (RDPSession*)(cliprdr->user);
            if (session != NULL)
            {
                rv = [session cliprdrFormatList:channel_id :msg_flags
                        :num_formats :formats];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*format_list_response)(struct cliprdr_t* cliprdr,
//                             uint16_t channel_id, uint16_t msg_flags);
static int
cb_cliprdr_format_list_response(struct cliprdr_t* cliprdr,
        uint16_t channel_id, uint16_t msg_flags)
{
    int rv = LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE;
    if (cliprdr != NULL)
    {
        RDPSession* session = (RDPSession*)(cliprdr->user);
        if (session != NULL)
        {
            rv = [session cliprdrFormatListResponse:channel_id :msg_flags];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*data_request)(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                     uint32_t requested_format_id);
static int
cb_cliprdr_data_request(struct cliprdr_t* cliprdr, uint16_t channel_id,
        uint32_t requested_format_id)
{
    int rv = LIBCLIPRDR_ERROR_DATA_REQUEST;
    if (cliprdr != NULL)
    {
        RDPSession* session = (RDPSession*)(cliprdr->user);
        if (session != NULL)
        {
            rv = [session cliprdrDataRequest:channel_id :requested_format_id];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*data_response)(struct cliprdr_t* cliprdr, uint16_t channel_id,
//                      uint16_t msg_flags, void* requested_format_data,
//                      uint32_t requested_format_data_bytes);
static int
cb_cliprdr_data_response(struct cliprdr_t* cliprdr, uint16_t channel_id,
        uint16_t msg_flags, void* requested_format_data,
        uint32_t requested_format_data_bytes)
{
    int rv = LIBCLIPRDR_ERROR_DATA_RESPONSE;
    if (cliprdr != NULL)
    {
        if (requested_format_data != NULL)
        {
            RDPSession* session = (RDPSession*)(cliprdr->user);
            if (session != NULL)
            {
                rv = [session cliprdrDataResponse:channel_id :msg_flags
                        :requested_format_data
                        :requested_format_data_bytes];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_data)(struct svc_t* svc, uint16_t channel_id,
//                     void* data, uint32_t bytes);
static int
cb_svc_cliprdr_process_data(struct svc_t* svc, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBSVC_ERROR_PROCESS_DATA;
    if (svc != NULL)
    {
        RDPSession* session = (RDPSession*)(svc->user);
        if (session != NULL)
        {
            struct cliprdr_t* cliprdr = [session getCliprdr];
            if (cliprdr_process_data(cliprdr, channel_id,
                    data, bytes) == LIBCLIPRDR_ERROR_NONE)
            {
                rv = LIBSVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*log_msg)(struct rdpsnd_t* rdpsnd, const char* msg);
static int
cb_rdpsnd_log_msg(struct rdpsnd_t* rdpsnd, const char* msg)
{
    int rv = LIBRDPSND_ERROR_LOG;
    if (msg != NULL)
    {
        if (rdpsnd != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpsnd->user);
            if (session != NULL)
            {
                [session logMsg:msg];
                rv = LIBCLIPRDR_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*send_data)(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
//                  void* data, uint32_t bytes);
static int
cb_rdpsnd_svc_send_data(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBRDPSND_ERROR_SEND_DATA;
    if (rdpsnd != NULL)
    {
        RDPSession* session = (RDPSession*)(rdpsnd->user);
        if (session != NULL)
        {
            struct svc_channels_t* svc = [session getSvc];
            if (svc_send_data(svc, channel_id, data, bytes) ==
                    LIBSVC_ERROR_NONE)
            {
                rv = LIBRDPSND_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_close)(struct rdpsnd_t* rdpsnd, uint16_t channel_id);
static int
cb_rdpsnd_process_close(struct rdpsnd_t* rdpsnd, uint16_t channel_id)
{
    int rv = LIBRDPSND_ERROR_PROCESS_CLOSE;
    if (rdpsnd != NULL)
    {
        RDPSession* session = (RDPSession*)(rdpsnd->user);
        if (session != NULL)
        {
            rv = [session rdpsndProcessClose:channel_id];
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_wave)(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
//                     uint16_t time_stamp, uint16_t format_no,
//                     uint8_t block_no, void* data, uint32_t bytes);
static int
cb_rdpsnd_process_wave(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
        uint16_t time_stamp, uint16_t format_no, uint8_t block_no,
        void* data, uint32_t bytes)
{
    int rv = LIBRDPSND_ERROR_PROCESS_WAVE;
    if (rdpsnd != NULL)
    {
        if (data != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpsnd->user);
            if (session != NULL)
            {
                rv = [session rdpsndProcessWave:channel_id :time_stamp
                        :format_no :data :bytes];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_training)(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
//                         uint16_t time_stamp, uint16_t pack_size,
//                         void* data, uint32_t bytes);
static int
cb_rdpsnd_process_training(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
        uint16_t time_stamp, uint16_t pack_size,
        void* data, uint32_t bytes)
{
    int rv = LIBRDPSND_ERROR_PROCESS_TRAINING;
    if (rdpsnd != NULL)
    {
        RDPSession* session = (RDPSession*)(rdpsnd->user);
        if (session != NULL)
        {
            rv = [session rdpsndProcessTraining:channel_id :time_stamp
                        :pack_size :data :bytes];
        }
    }
    return rv;
}
//*****************************************************************************
// callback
// int (*process_formats)(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
//                        uint32_t flags, uint32_t volume,
//                        uint32_t pitch, uint16_t dgram_port,
//                        uint16_t version, uint8_t block_no,
//                        uint16_t num_formats, struct format_t* formats);
static int
cb_rdpsnd_process_formats(struct rdpsnd_t* rdpsnd, uint16_t channel_id,
        uint32_t flags, uint32_t volume, uint32_t pitch, uint16_t dgram_port,
        uint16_t version, uint8_t block_no, uint16_t num_formats,
        struct rdpsnd_format_t* formats)
{
    int rv = LIBRDPSND_ERROR_PROCESS_FORMATS;
    if (rdpsnd != NULL)
    {
        if (formats != NULL)
        {
            RDPSession* session = (RDPSession*)(rdpsnd->user);
            if (session != NULL)
            {
                rv = [session rdpsndProcessFormats:channel_id :flags
                        :volume :pitch :dgram_port :version :block_no
                        :num_formats :formats];
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*process_data)(struct svc_t* svc, uint16_t channel_id,
//                     void* data, uint32_t bytes);
static int
cb_svc_rdpsnd_process_data(struct svc_t* svc, uint16_t channel_id,
        void* data, uint32_t bytes)
{
    int rv = LIBSVC_ERROR_PROCESS_DATA;
    if (svc != NULL)
    {
        RDPSession* session = (RDPSession*)(svc->user);
        if (session != NULL)
        {
            struct rdpsnd_t* rdpsnd = [session getRdpsnd];
            if (rdpsnd_process_data(rdpsnd, channel_id,
                    data, bytes) == LIBRDPSND_ERROR_NONE)
            {
                rv = LIBSVC_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*log_msg)(struct edisp_t* edisp, const char* msg);
static int
cb_edisp_log_msg(struct edisp_t* edisp, const char* msg)
{
    int rv = LIBEDISP_ERROR_LOG;
    if (msg != NULL)
    {
        if (edisp != NULL)
        {
            RDPSession* session = (RDPSession*)(edisp->user);
            if (session != NULL)
            {
                [session logMsg:msg];
                rv = LIBEDISP_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// callback
// int (*send_data)(struct edisp_t* edisp, uint16_t channel_id,
//                  uint32_t drdynvc_channel_id,
//                  void* data, uint32_t bytes);
static int
cb_edisp_drdynvc_send_data(struct edisp_t* edisp, uint16_t channel_id,
        uint32_t drdynvc_channel_id, void* data, uint32_t bytes)
{
    int rv = LIBEDISP_ERROR_SEND_DATA;
    if (edisp != NULL)
    {
        RDPSession* session = (RDPSession*)(edisp->user);
        if (session != NULL)
        {
            struct drdynvc_t* drdynvc = [session getDrdynvc];
            if (drdynvc_send_data(drdynvc, channel_id,
                    drdynvc_channel_id, data, bytes) ==
                    LIBDRDYNVC_ERROR_NONE)
            {
                rv = LIBEDISP_ERROR_NONE;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// int (*caps)(struct edisp_t* edisp, uint16_t channel_id,
//             uint32_t drdynvc_channel_id, uint32_t max_num_monitor,
//             uint32_t max_monitor_area_factor_a,
//             uint32_t max_monitor_area_factor_b);
static int
cb_edisp_process_caps(struct edisp_t* edisp, uint16_t channel_id,
        uint32_t drdynvc_channel_id, uint32_t max_num_monitor,
        uint32_t max_monitor_area_factor_a, uint32_t max_monitor_area_factor_b)
{
    int rv = LIBEDISP_ERROR_CAPS;
    if (edisp != NULL)
    {
        RDPSession* session = (RDPSession*)(edisp->user);
        if (session != NULL)
        {
            rv = [session edispProcessCaps
                    :channel_id
                    :drdynvc_channel_id
                    :max_num_monitor
                    :max_monitor_area_factor_a
                    :max_monitor_area_factor_b];
        }
    }
    return rv;
}

#endif
