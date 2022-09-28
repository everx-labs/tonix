pragma ton-solidity >= 0.64.0;

import "task_h.sol";
//typedef void callout_func_t(void *);
// Root mount holdback API
struct s_root_hold_token {
	uint16 flags;
	string who;
    uint32[] list; // TAILQ_ENTRY(root_hold_token)
}
struct s_callout {
    uint32 c_links;
    uint32 c_time;      // ticks to the event
    uint32 c_precision; // delta allowed wrt opt
    uint32 c_arg;       // function argument
    uint32 c_func;      // callout_func_t // function to call
    uint16 c_flags;     // User State
    uint16 c_iflags;    // Internal State
    uint8 c_cpu;        // CPU we're scheduled on
}
// The generation number is incremented every time a new entry is entered into the queue giving round robin per priority level scheduling.
struct cam_pinfo {
    uint8 priority;
    uint8 generation;
    uint8 index;
}
struct s_camq {
    cam_pinfo[] queue_array;
    uint8 array_size;
    uint8 entries;
    uint8 generation;
    uint8 qfrozen_cnt;
}
struct s_cam_devq {
    s_camq send_queue;
    uint8 send_openings;
    uint8 send_active;
}
struct s_cam_ccbq {
    s_camq queue;
    uint32 queue_extra_head; // s_ccb_hdr_tailq
    uint8 queue_extra_entries;
    uint8 total_openings;
    uint8 allocated;
    uint8 dev_openings;
    uint8 dev_active;
}
//TAILQ_HEAD(ccb_hdr_tailq, ccb_hdr);
//LIST_HEAD(ccb_hdr_list, ccb_hdr);
//SLIST_HEAD(ccb_hdr_slist, ccb_hdr);
struct s_camq_entry {
    uint32 tqe;
//  LIST_ENTRY(ccb_hdr) le;
//  SLIST_ENTRY(ccb_hdr) sle;
//  TAILQ_ENTRY(ccb_hdr) tqe;
//  STAILQ_ENTRY(ccb_hdr) stqe;
}
struct ccb_priv_entry {
    uint32 ptr;
    uint32 field;
    uint8[4] ebytes; // [sizeof(uintptr_t)]
}
struct ccb_ppriv_area {
    ccb_priv_entry[2] entries; // CCB_PERIPH_PRIV_SIZE
    uint8[2 * 12] ebytes; // sizeof(ccb_priv_entry) = 12
}
struct ccb_spriv_area {
    ccb_priv_entry[2] entries; // CCB_SIM_PRIV_SIZE
    uint8[2 * 12] ebytes; // sizeof(ccb_priv_entry)
}
struct ccb_qos_area {
    uint32 etime;
    uint32 sim_data;
    uint32 periph_data;
}
struct s_ccb_hdr {
    cam_pinfo pinfo;		    // Info for priority scheduling
    s_camq_entry xpt_links;	    // For chaining in the XPT layer
    s_camq_entry sim_links;	    // For chaining in the SIM layer
    s_camq_entry periph_links;	// For chaining in the type driver
    uint16 retry_count;
    uint16 alloc_flags;	// ccb_alloc_flags
    uint32 cbfcnp;      // (*cbfcnp)(struct cam_periph *, union ccb *); // Callback on completion function
    uint16 func_code;   // xpt_opcode // XPT function code
    uint32 status;	    // Status returned by CAM subsystem
    s_cam_path path;    // Compiled path for this ccb
    uint16 path_id;	    // Path ID for the request
    uint16 target_id;   // target_id_t Target device ID
    uint16 target_lun;  // lun_id_t Target LUN number
    uint32 flags;       // ccb_flags
    uint32 xflags;      // Extended flags
    ccb_ppriv_area periph_priv;
    ccb_spriv_area sim_priv;
    ccb_qos_area qos;
    uint32 timeout;	    // Hard timeout value in mseconds
    uint32 softtimeout;	// Soft timeout value in sec + usec
}
enum cam_sf {
    SF_RETRY_UA,	// Retry UNIT ATTENTION conditions.
    SF_NO_PRINT,	// Never print error status.
    SF_QUIET_IR,	// Be quiet about Illegal Request responses
    SF_PRINT_ALWAYS,// Always print error status.
    SF_NO_RECOVERY,	// Don't do active error recovery.
    SF_NO_RETRY,	// Don't do any retries.
    SF_RETRY_BUSY	// Retry BUSY status.
}
// Priority information for a CAM structure.
enum cam_rl { CAM_RL_HOST, CAM_RL_BUS, CAM_RL_XPT, CAM_RL_DEV, CAM_RL_NORMAL, CAM_RL_VALUES }
enum cam_flags { CAM_FLAG_NONE, CAM_EXPECT_INQ_CHANGE, CAM_RETRY_SELTO }
enum cam_error_string_flags { CAM_ESF_NONE,	CAM_ESF_COMMAND, CAM_ESF_CAM_STATUS, CAM_ESF_PROTO_STATUS, CAM_ESF_ALL }
enum cam_error_proto_flags { CAM_EPF_NONE, CAM_EPF_MINIMAL, CAM_EPF_NORMAL, CAM_EPF_ALL, CAM_EPF_LEVEL_MASK }
enum cam_error_scsi_flags { CAM_ESF_PRINT_NONE, CAM_ESF_PRINT_STATUS, CAM_ESF_PRINT_SENSE }
enum cam_error_smp_flags { CAM_ESMF_PRINT_NONE, CAM_ESMF_PRINT_STATUS, CAM_ESMF_PRINT_FULL_CMD }
enum cam_error_ata_flags { CAM_EAF_PRINT_NONE, CAM_EAF_PRINT_STATUS, CAM_EAF_PRINT_RESULT }
enum cam_strvis_flags { CAM_STRVIS_FLAG_NONE, CAM_STRVIS_FLAG_NONASCII_MASK, CAM_STRVIS_FLAG_NONASCII_TRIM, CAM_STRVIS_FLAG_NONASCII_RAW, CAM_STRVIS_FLAG_NONASCII_SPC, CAM_STRVIS_FLAG_NONASCII_ESC }
enum ccb_alloc_flags { CAM_CCB_FROM_UMA } // CCB from a periph UMA zone
// CAM Status field values
enum cam_status {
    CAM_REQ_INPROG,         // CCB request is in progress
    CAM_REQ_CMP,            // CCB request completed without error
    CAM_REQ_ABORTED,        // CCB request aborted by the host
    CAM_UA_ABORT,           // Unable to abort CCB request
    CAM_REQ_CMP_ERR,        // CCB request completed with an error
    CAM_BUSY,               // CAM subsystem is busy
    CAM_REQ_INVALID,        // CCB request was invalid
    CAM_PATH_INVALID,       // Supplied Path ID is invalid
    CAM_DEV_NOT_THERE,      // SCSI Device Not Installed/there
    CAM_UA_TERMIO,          // Unable to terminate I/O CCB request
    CAM_SEL_TIMEOUT,        // Target Selection Timeout
    CAM_CMD_TIMEOUT,        // Command timeout
    CAM_SCSI_STATUS_ERROR,  // SCSI error, look at error code in CCB
    CAM_MSG_REJECT_REC,     // Message Reject Received
    CAM_SCSI_BUS_RESET,     // SCSI Bus Reset Sent/Received
    CAM_UNCOR_PARITY,       // Uncorrectable parity error occurred
    CAM_AUTOSENSE_FAIL,     // Autosense: request sense cmd fail
    CAM_NO_HBA,             // No HBA Detected error
    CAM_DATA_RUN_ERR,       // Data Overrun error
    CAM_UNEXP_BUSFREE,      // Unexpected Bus Free
    CAM_SEQUENCE_FAIL,      // Target Bus Phase Sequence Failure
    CAM_CCB_LEN_ERR,        // CCB length supplied is inadequate
    CAM_PROVIDE_FAIL,       // Unable to provide requested capabilit
    CAM_BDR_SENT,           // A SCSI BDR msg was sent to target
    CAM_REQ_TERMIO,         // CCB request terminated by the host
    CAM_UNREC_HBA_ERROR,    // Unrecoverable Host Bus Adapter Error
    CAM_REQ_TOO_BIG,        // Request was too large for this host
    CAM_REQUEUE_REQ,        // This request should be requeued to preserve transaction ordering.  This typically occurs when the SIM recognizes an error that should freeze the queue and must place additional requests for the target at the sim level back into the XPT queue.
    CAM_ATA_STATUS_ERROR,   // ATA error, look at error code in CCB
    CAM_SCSI_IT_NEXUS_LOST, // Initiator/Target Nexus lost.
    CAM_SMP_STATUS_ERROR,   // SMP error, look at error code in CCB
    CAM_REQ_SOFTTIMEOUT,    // Command completed without error but  exceeded the soft timeout threshold
    CAM_IDE,                // Initiator Detected Error
    CAM_RESRC_UNAVAIL,      // Resource Unavailable
    CAM_UNACKED_EVENT,      // Unacknowledged Event by Host
    CAM_MESSAGE_RECV,       // Message Received in Host Target Mode
    CAM_INVALID_CDB,        // Invalid CDB received in Host Target Mode
    CAM_LUN_INVALID,        // Lun supplied is invalid
    CAM_TID_INVALID,        // Target ID supplied is invalid
    CAM_FUNC_NOTAVAIL,      // The requested function is not available
    CAM_NO_NEXUS,           // Nexus is not established
    CAM_IID_INVALID,        // The initiator ID is invalid
    CAM_CDB_RECVD,          // The SCSI CDB has been received
    CAM_LUN_ALRDY_ENA,      // The LUN is already enabled for target mode
    CAM_SCSI_BUSY,          // SCSI Bus Busy
    CAM_DEV_QFRZN           // The DEV queue is frozen w/this err
}
enum cam_proto {
    PROTO_UNKNOWN,
    PROTO_UNSPECIFIED,
    PROTO_SCSI,	    // Small Computer System Interface
    PROTO_ATA,	    // AT Attachment
    PROTO_ATAPI,	// AT Attachment Packetized Interface
    PROTO_SATAPM,	// SATA Port Multiplier
    PROTO_SEMB,	    // SATA Enclosure Management Bridge
    PROTO_NVME,	    // NVME
    PROTO_MMCSD	    // MMC, SD, SDIO
}
enum cam_xport {
    XPORT_UNKNOWN,
    XPORT_UNSPECIFIED,
    XPORT_SPI,	// SCSI Parallel Interface
    XPORT_FC,	// Fiber Channel
    XPORT_SSA,	// Serial Storage Architecture
    XPORT_USB,	// Universal Serial Bus
    XPORT_PPB,	// Parallel Port Bus
    XPORT_ATA,	// AT Attachment
    XPORT_SAS,	// Serial Attached SCSI
    XPORT_SATA,	// Serial AT Attachment
    XPORT_ISCSI,// iSCSI
    XPORT_SRP,	// SCSI RDMA Protocol
    XPORT_NVME,	// NVMe over PCIe
    XPORT_MMCSD	// MMC, SD, SDIO card
}
struct periph_driver {
    uint32 init; // periph_init_t
    string driver_name;
    uint32[] units; // TAILQ_HEAD(,cam_periph)
    uint8 generation;
    uint32 flags;
    uint32 deinit; // periph_deinit_t
}
enum cam_periph_type { CAM_PERIPH_BIO }
// Definition of a CAM peripheral driver entry.  Peripheral drivers instantiate one of these for each device they wish to communicate with and pass it into
// the xpt layer when they wish to schedule work on that device via the xpt_schedule API.
struct cam_status_entry {
    cam_status status_code;
    string status_text;
}
struct s_cam_periph {
    uint32 periph_start;    // periph_start_t
    uint32 periph_oninval;  // periph_oninv_t
    uint32 periph_dtor;     // periph_dtor_t
    string periph_name;
    uint32 path;  // s_cam_path Compiled path to device
    uint32 softc;
    s_cam_sim sim;
    uint32 unit_number;
    cam_periph_type	ctype;
    uint32 flags;
    uint8 scheduled_priority;
    uint8 immediate_priority;
    uint8 periph_allocating;
    uint8 periph_allocated;
    uint8 refcount;
    uint32 ccb_list;    //SLIST_HEAD(, ccb_hdr)	// For "immediate" requests
    uint32 periph_links;//SLIST_ENTRY(cam_periph)
    uint32 unit_links;  //TAILQ_ENTRY(cam_periph)
    uint32 deferred_callback; // ac_callback_t
    uint32 deferred_ac; //ac_code
    uint32 periph_run_task; //s_task
    uint32 ccb_zone;    //uma_zone
    s_root_hold_token periph_rootmount;
}
// The sim driver should not access anything directly from this structure.
struct s_cam_sim {
    uint32 sim_action;  // sim_action_func
    uint32 sim_poll;    // sim_poll_func
    string sim_name;
    uint32 softc;
    uint32[] links; //TAILQ_ENTRY(cam_sim)
    uint32 path_id; // The Boot device may set this to 0?
    uint8 unit_number;
    uint32 bus_id;
    uint8 max_tagged_dev_openings;
    uint8 max_dev_openings;
    uint32 flags;
    s_cam_devq devq;    // Device Queue to use for this SIM
    uint8 refcount;     // References to the SIM.
}
// The CAM EDT (Existing Device Table) contains the device information for all devices for all buses in the system.
// The table contains a cam_ed structure for each device on the bus.
struct s_cam_ed {
    cam_pinfo devq_entry;
    uint32[] links; // TAILQ_ENTRY(cam_ed)
    s_cam_et target;
    s_cam_sim sim;
    uint8 lun_id;    //lun_id_t
    s_cam_ccbq ccbq; // Queue of pending ccbs
    uint32[] asyncs; // struct async_list   Async callback info for this B/T/L
    uint32[] periphs;// struct periph_list All attached devices
    uint8 generation;// Generation number
    uint32 quirk;	 // Oddities about this device
    uint8 maxtags;
    uint8 mintags;
    cam_proto protocol;
    uint8 protocol_version;
    cam_xport transport;
    uint8 transport_version;
    uint32 inq_data; // struct scsi_inquiry_data ;
    uint8 supported_vpds;
    uint8 supported_vpds_len;
    uint8 device_id_len;
    uint8 device_id;
    uint32 ext_inq_len;
    uint8 ext_inq;
    uint8 physpath_len;
    uint8 physpath;        // physical path string form
    uint8 rcap_len;
    uint8 rcap_buf;
    uint32 ident_data;     //struct ata_params
    uint32 mmc_ident_data; //struct mmc_params
    uint8 inq_flags;       // Current settings for inquiry flags. This allows us to override settings like disconnection and tagged queuing for a device
    uint8 queue_flags;     // Queue flags from the control page
    uint8 serial_num_len;
    uint8 serial_num;
    uint32 flags;
    uint32 tag_delay_count;
    uint32 tag_saved_openings;
    uint32 refcount;
    s_callout callout;
    uint32 highpowerq_entry; // STAILQ_ENTRY(cam_ed)
    uint32 nvme_cdata;  // struct nvme_controller_data
    uint32 nvme_data;   // struct nvme_namespace_data
}
// Each target is represented by an ET (Existing Target).  These entries are created when a target is successfully probed with an
// identify, and removed when a device fails to respond after a number of retries, or a bus rescan finds the device missing.
struct s_cam_et {
    uint32[] ed_entries; // TAILQ_HEAD(, cam_ed)
    uint32[] links;      // TAILQ_ENTRY(cam_et)
    s_cam_eb bus;
    uint16 target_id; // target_id_t
    uint32 refcount;
    uint8 generation;
    uint32 last_reset;
    uint16 rpl_size;
    uint32 luns; // struct scsi_report_luns_data
}
// Each bus is represented by an EB (Existing Bus).
// These entries are created by calls to xpt_bus_register and deleted by calls to xpt_bus_deregister.
struct s_cam_eb {
    uint32[] et_entries; // TAILQ_HEAD(, cam_et)
    uint32[] links;      // TAILQ_ENTRY(cam_eb)
    uint16 path_id;      // path_id_t
    s_cam_sim sim;
    uint32 last_reset;
    uint32 flags;
    uint8 refcount;
    uint8 generation;
    uint32 parent_dev; // device_t
    s_xpt_xport xport;
}
struct s_cam_path {
    s_cam_periph periph;
    s_cam_eb bus;
    s_cam_et target;
    s_cam_ed device;
}
struct s_xpt_xport_ops {
    uint32 alloc_device;  // xpt_alloc_device_func
    uint32 reldev;        // xpt_release_device_func
    uint32 action;        // xpt_action_func
    uint32 async;         // xpt_dev_async_func
    uint32 announce;      // xpt_announce_periph_func
    uint32 announce_sbuf; // xpt_announce_periph_sbuf_func
}
struct s_async_node {
    uint32[] links; // SLIST_ENTRY(async_node)
    uint32 event_enable;// Async Event enables
    uint32 event_lock;  // Take SIM lock for handlers.
    uint32 callback;    // void *)(void *arg, u_int32_t code, struct cam_path *path, void *args);
    uint32 callback_arg;
}
struct s_xpt_xport {
    cam_xport xport;
    string name;
    s_xpt_xport_ops	ops;
}

struct xpt_softc {
    uint32 xpt_generation;
    uint32[] highpowerq;    // STAILQ_HEAD(highpowerlist, cam_ed)  number of high powered commands that can go through right now
    uint8 num_highpower;
    uint32[] ccb_scanq;     // TAILQ_HEAD(, ccb_hdr)     queue for handling async rescan requests.
    uint8 buses_to_config;
    uint8 buses_config_done;
    uint8 announce_nosbuf;
    uint32[] xpt_busses;    // TAILQ_HEAD(,cam_eb) Registered buses
    uint8 bus_generation;
    uint8 boot_delay;
    s_callout boot_callout;
    s_task boot_task; // struct 
    s_root_hold_token xpt_rootmount;
    uint32 xpt_taskq; // struct taskqueue
}
enum dev_match_ret { DM_RET_COPY, DM_RET_FLAG_MASK, DM_RET_NONE, DM_RET_STOP, DM_RET_DESCEND, DM_RET_ERROR, DM_RET_ACTION_MASK }
enum xpt_traverse_depth { XPT_DEPTH_BUS, XPT_DEPTH_TARGET, XPT_DEPTH_DEVICE, XPT_DEPTH_PERIPH }
struct xpt_traverse_config {
    xpt_traverse_depth depth;
    uint32 tr_func;
    uint32 tr_arg;
}
//function xpt_busfunc_t (s_cam_eb bus, uint32 arg) returns (uint8);
//function xpt_targetfunc_t (s_cam_et target, uint32 arg) returns (uint8);
//function xpt_devicefunc_t (s_cam_ed device, uint32 arg) returns (uint8);
//function xpt_periphfunc_t (s_cam_periph periph, uint32 arg) returns (uint8);
//function xpt_pdrvfunc_t (s_periph_driver pdrv, uint32 arg) returns (uint8);