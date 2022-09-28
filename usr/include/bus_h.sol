pragma ton-solidity >= 0.64.0;

import "ucred_h.sol";
import "kobj_h.sol";
import "cv_h.sol";
import "select_h.sol";
import "signal_h.sol";
import "cam_h.sol";
import "cdev_h.sol";

/*struct s_cdevsw {
    uint32 d_version;
    uint32[] d_methods;
    string d_name;
}*/

struct d_cdevsw {
    function (s_cdev, uint16, uint8, s_thread) internal returns (uint8) d_open_t;
    function (s_cdev, uint16, s_thread, s_file) internal returns (uint8) d_fdopen_t;
    function (s_cdev, uint16, uint8, s_thread) internal returns (uint8) d_close_t;
    function (s_cdev, uint8, uint32, uint16, s_thread) internal returns (uint8) d_ioctl_t;
    function (s_cdev, s_uio, uint16) internal returns (uint8) d_read_t;
    function (s_cdev, s_uio, uint16) internal returns (uint8) d_write_t;
    function (s_cdev, uint8, s_thread) internal returns (uint8) d_poll_t;
//    function (s_cdev dev, uint32 offset, uint32 paddr, uint8 nprot, vm_memattr_t *memattr) internal returns (uint8) d_mmap_t;
    function (s_cdev, uint32, uint32, uint32, uint8) internal returns (uint8) d_mmap_single_t;
    function (s_cdev) internal d_purge_t;
    function (uint32, uint32, uint32, uint32) internal returns (uint8) dumper_t;
    function (s_dumperinfo, uint32, uint32) internal returns (uint8) dumper_start_t;
//    function (s_dumperinfo, s_kerneldumpheader) internal returns (uint8) dumper_hdr_t;
}
//    function void d_strategy_t(s_bio bp);
//    function int d_kqfilter_t(s_cdev dev, struct knote *kn);

struct s_dumperinfo {
    uint32 dumper;  // dumper_t // Dumping function.
    uint32 dumper_start; // dumper_start_t // Dumper callback for dump_start().
    uint32 dumper_hdr; // dumper_hdr_t // Dumper callback for writing headers.
    uint32 priv;	    // Private parts.
    uint32 blocksize;   // Size of block in bytes.
    uint32 maxiosize;   // Max size allowed for an individual I/O
    uint32 mediaoffset;	// Initial offset in bytes.
    uint32 mediasize;   // Space available in bytes.
    uint32 blockbuf;    // Buffer for padding shorter dump blocks
    uint32 dumpoff;	    // Offset of ongoing kernel dump.
    uint32 origdumpoff;	// Starting dump offset.
//  struct kerneldumpcrypto	*kdcrypto; // Kernel dump crypto
//  struct kerneldumpcomp *kdcomp; // Kernel dump compression
//  TAILQ_ENTRY(dumperinfo)	di_next;
	string	di_devname;
}

struct s_device_location_node {
    string dln_locator;
    string dln_path;
    uint16 dln_link;
}

struct u_businfo {
    uint16 ub_version;    // interface version
    uint16 ub_generation; // generation count
}

enum device_state {
    DS_NOTPRESENT, // not probed or probe failed
    DS_ALIVE,      // probe succeeded
    DS_ATTACHING,  // currently attaching
    DS_ATTACHED    // attach method called
}

enum device_property_type { DEVICE_PROP_ANY, DEVICE_PROP_BUFFER, DEVICE_PROP_UINT32, DEVICE_PROP_UINT64 }
enum evhdev_detach {
    EVHDEV_DETACH_BEGIN,    // Before detach() is called
    EVHDEV_DETACH_COMPLETE, // After detach() returns 0
    EVHDEV_DETACH_FAILED    // After detach() returns err
}

struct u_device {
    uint16 dv_handle;
    uint16 dv_parent;
    uint32 dv_devflags;   // API Flags for device
    uint16 dv_flags;      // flags for dev state
    device_state dv_state; // State of attachment
    string dv_fields;      // NUL terminated fields
    // name (name of the device in tree)
    // desc (driver description)
    // drivername (Name of driver without unit number)
    // pnpinfo (Plug and play information from bus)
    // location (Location of device on parent
}

struct devreq_buffer {
    bytes buffer;
    uint32 length;
}
struct s_devreq {
    string dr_name;  //[128];
    uint16 dr_flags; // request-specific flags
    bytes dru_data;
}

enum cpu_sets {	LOCAL_CPUS, INTR_CPUS }

enum intr_type { INTR_TYPE_TTY, INTR_TYPE_BIO, INTR_TYPE_NET, INTR_TYPE_CAM, INTR_TYPE_MISC, INTR_TYPE_CLK, INTR_TYPE_AV, INTR_EXCL, INTR_MPSAFE, INTR_ENTROPY, INTR_MD1, INTR_MD2, INTR_MD3, INTR_MD4 } // powers of 2
enum intr_trigger { INTR_TRIGGER_INVALID, INTR_TRIGGER_CONFORM, INTR_TRIGGER_EDGE, INTR_TRIGGER_LEVEL } // starts from -1
enum intr_polarity { INTR_POLARITY_CONFORM, INTR_POLARITY_HIGH, INTR_POLARITY_LOW }
enum bus_dma_lock_op_t { BUS_DMA_LOCK, BUS_DMA_UNLOCK }

struct driver_filter_t {
    function (uint32) internal returns (uint8) driver_filter;
}

struct driver_intr_t {
    function (uint32) internal driver_intr;
}

struct driverlink_t { //35
    driver_t driver;
    uint32 link;    // TAILQ_ENTRY(driverlink) list of drivers in devclass
    uint8 pass;
    uint16 flags;
    uint8 passlink;
}

struct driver_t {
    uint16 version;
    bytes10 name;    // class name
    uint32 methods;
    uint16 size;    // object size
    uint8[] baseclasses; // base classes
    uint8 refs;    // reference count
    uint32 updated_at;
}

//#define DEVCTL_BUFFER (1024 - sizeof(void *))
struct s_dev_event_info {
    uint32 dei_link; // STAILQ_ENTRY(dev_event_info) ;
    string dei_data;//[DEVCTL_BUFFER];
}

struct dev_softc {
    bool inuse;
    bool nonblock;
    uint8 queued;
    bool async;
//    s_cv cv;
//    s_selinfo sel;
    //uint32 devq; // s_devq
    s_dev_event_info[] devq;
    s_sigio sigio;
    uint32 zone; // uma_zone
}

struct s_logsoftc {
    uint8 sc_state;	    // see above for possibilities
    s_selinfo sc_selp;  // process waiting on select call
    s_sigio sc_sigio;   // information for async I/O
    s_callout sc_callout; // callout to wakeup syslog
}

struct devclass_t { //29
    uint8 link; // TAILQ_ENTRY(devclass)
    uint8 parent; // parent in devclass hierarchy
    uint8[] drivers; // driverlink_t[]  bus devclasses store drivers for bus
    bytes10 name;
    uint8[] devices; // array of devices indexed by unit
    uint8 maxunit;   // size of devices array
    uint16 flags;
}

struct device_t {
    uint8 link;      // list of devices in parent
    address devlink; // global device list membership
    uint8 parent;    // parent of this device
    uint8[] children;// list of child devices
    uint8 driver;    // current driver
    uint8 devclass; // current device class
    uint8 unit;      // current unit number
    bytes12 nameunit; // name+unit e.g. foodev0
    bytes20 desc;    // driver specific description
    uint8 busy;      // count of calls to device_busy()
    device_state state;	// current device state
    uint8 devflags;  // api level flags for device_get_flags()
    uint16 flags;    // internal device flags
    uint8 order;     // order from device_add_child_ordered()
    uint32 ivars;   // instance variables
    uint32 softc;   // current driver's variables
}

struct s_resource_i {
//  s_resource r_r;
    uint16 r_link;
    uint16 r_sharelink;
    uint16 r_sharehead;
    uint32 r_start;     // index of the first entry in this resource
    uint32 r_end;       // index of the last entry (inclusive)
    uint16 r_flags;
    bytes r_virtual;    // virtual address of this resource
    bytes r_irq_cookie;	// interrupt cookie for this (interrupt) resource
    device_t r_dev;     // device which has allocated this resource
    s_rman r_rm;        // resource manager from whence this came
    uint16 r_rid;       // optional rid for this resource.
}
enum rman_type { RMAN_UNINIT, RMAN_GAUGE, RMAN_ARRAY }

struct u_resource {
    uint16 r_handle;  // resource uniquifier
    uint16 r_parent;  // parent rman
    uint16 r_device;  // device owning this resource
    string r_devname; // device name XXX obsolete
    uint32 r_start;   // offset in resource space
    uint32 r_size;    // size in resource space
    uint32 r_flags;   // RF_* flags
}

struct u_rman {
    uint16 rm_handle;  // rman uniquifier
    string rm_descr;   // rman description
    uint32 m_start;    // base of managed region
    uint32 rm_size;    // size of managed region
    rman_type rm_type; // region type
}

struct s_resource {
    s_resource_i __r_i;
    uint32 r_bustag;    // bus_space tag
    uint32 r_bushandle;	// bus_space handle
}

struct s_resource_map {
    uint32 r_bustag;
    uint32 r_bushandle;
    uint32 r_size;
    uint32 r_vaddr;
}
struct s_resource_map_request {
    uint16 size;
    uint16 offset;
    uint16 length;
    uint16 memattr;
}

struct s_rman {
    uint16[] rm_list;
    uint16 rm_link;  // link in list of all rmans
    uint32 rm_start; // index of globally first entry
    uint32 rm_end;   // index of globally last entry
    rman_type rm_type; // what type of resource this is
    string rm_descr; // text descripion of this resource
}

struct s_resource_spec {
    uint16 rtype;
    uint16 rid;
    uint16 flags;
}
struct s_resource_list {
    s_resource_list_entry[] list;
}
struct s_resource_list_entry {
    uint16 link;  // STAILQ_ENTRY(resource_list_entry)
    uint16 rtype; // type argument to alloc_resource
    uint16 rid;	  // resource identifier
    uint16 flags; // resource flags
    s_resource res; // the real resource when allocated
    uint32 start; // start of resource range
    uint32 end;	  // end of resource range
    uint32 count; // count within range
}

struct s_bm {
    function (device_t) internal returns (uint8) shutdown;
    function (device_t) internal returns (uint8) suspend;
    function (device_t) internal returns (uint8) resume;
    function (device_t, device_t) internal returns (string) print_child;
    function (device_t, device_t, uint16) internal returns (uint8, uint32) read_ivar;
    function (device_t, device_t, uint16, uint32) internal returns (uint8) write_ivar;
    function (device_t, device_t) internal returns (uint8) child_present;
}

struct s_devm {
    function (device_t) internal returns (uint8) shutdown;
    function (device_t) internal returns (uint8) suspend;
    function (device_t) internal returns (uint8) resume;
    function (device_t, device_t) internal returns (string) print_child;
    function (device_t, device_t, uint16) internal returns (uint8, uint32) read_ivar;
    function (device_t, device_t, uint16, uint32) internal returns (uint8) write_ivar;
    function (device_t, device_t) internal returns (uint8) child_present;
}