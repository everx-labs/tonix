pragma ton-solidity >= 0.61.2;

struct kobj_class {
	string name;		// class name
//	kobj_method_t	*methods;	// method table
	uint16 size;		// object size
	uint16[] baseclasses;	// base classes
	uint16 refs;		// reference count
//	kobj_ops_t	ops		// compiled method table
}

struct u_businfo {
	uint16 ub_version;	    // interface version
	uint16 ub_generation;	// generation count
}

enum device_state {
	DS_NOTPRESENT,// = 10,		// not probed or probe failed
	DS_ALIVE, // = 20,			// probe succeeded
	DS_ATTACHING, // = 25,		// currently attaching
	DS_ATTACHED // = 30,		// attach method called
}

enum device_property_type { DEVICE_PROP_ANY, DEVICE_PROP_BUFFER, DEVICE_PROP_UINT32, DEVICE_PROP_UINT64 }

struct u_device {
	uint16 dv_handle;
	uint16 dv_parent;
	uint32 dv_devflags;   // API Flags for device
	uint16 dv_flags;	   // flags for dev state
	device_state dv_state; // State of attachment
	string dv_fields;      // NUL terminated fields
	/* name (name of the device in tree) */
	/* desc (driver description) */
	/* drivername (Name of driver without unit number) */
	/* pnpinfo (Plug and play information from bus) */
	/* location (Location of device on parent */
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
//struct driver {
//	KOBJ_CLASS_FIELDS;
//}

enum intr_type { INTR_TYPE_TTY, INTR_TYPE_BIO, INTR_TYPE_NET, INTR_TYPE_CAM, INTR_TYPE_MISC, INTR_TYPE_CLK, INTR_TYPE_AV, INTR_EXCL, INTR_MPSAFE, INTR_ENTROPY, INTR_MD1, INTR_MD2, INTR_MD3, INTR_MD4 } // powers of 2
enum intr_trigger { INTR_TRIGGER_INVALID, INTR_TRIGGER_CONFORM, INTR_TRIGGER_EDGE, INTR_TRIGGER_LEVEL } // starts from -1
enum intr_polarity { INTR_POLARITY_CONFORM, INTR_POLARITY_HIGH, INTR_POLARITY_LOW }

struct driverlink_t {
    uint16 driver;  // kobj_class_t
    uint16 link;    // TAILQ_ENTRY(driverlink) list of drivers in devclass
	uint16 pass;
	uint16 flags;
    uint16 passlink; // TAILQ_ENTRY(driverlink)
}

struct driver_t {
    string name;        // class name
    uint16[] methods;   // method table
	uint16 size;		// object size
	uint16[] baseclasses; // base classes
	uint16 refs;		// reference count
}

struct dev_softc {
	bool inuse;
	bool nonblock;
	bool queued;
	bool async;
//	s_cv	cv;
//	struct selinfo	sel;
//	struct devq	devq;
//	s_sigio	sigio;
//	s_uma_zone_t	zone;
}

struct devclass_t {
    uint16 link;      // TAILQ_ENTRY(devclass)
	uint16 parent;	  // parent in devclass hierarchy
	uint16[] drivers; // bus devclasses store drivers for bus
	string name;
	uint16[] devices; // array of devices indexed by unit
	uint16 maxunit;	  // size of devices array
	uint16 flags;
//	s_sysctl_ctx_list sysctl_ctx;
//	s_sysctl_oid sysctl_tree;
}

struct device_t {
    uint16 link;        // list of devices in parent
    uint16 devlink;     // global device list membership
	uint16 parent;		// parent of this device
	uint16[] children;	// list of child devices
	uint16 driver;	    // current driver
	uint16 devclass;	// current device class
	uint16 unit;		// current unit number
	string nameunit;	// name+unit e.g. foodev0
	string desc;		// driver specific description
	uint16 busy;		// count of calls to device_busy()
	device_state state;	// current device state
	uint32 devflags;	// api level flags for device_get_flags()
	uint16 flags;	// internal device flags
	uint16 order;	// order from device_add_child_ordered()
	string ivars;	// instance variables
	string softc;	// current driver's variables
//	s_sysctl_ctx_list sysctl_ctx; // state for sysctl variables
//	s_sysctl_oid sysctl_tree;	  // state for sysctl variables
}

struct s_resource_i {
//	s_resource		r_r;
    uint16 r_link;
	uint16 r_sharelink;
	uint16 r_sharehead;
	uint32 r_start;	    // index of the first entry in this resource
	uint32 r_end;		// index of the last entry (inclusive)
	uint16 r_flags;
	bytes r_virtual;	// virtual address of this resource
	bytes r_irq_cookie;	// interrupt cookie for this (interrupt) resource
	device_t r_dev;	    // device which has allocated this resource
	s_rman r_rm;	    // resource manager from whence this came
	uint16 r_rid;		    // optional rid for this resource.
}
enum rman_type { RMAN_UNINIT, RMAN_GAUGE, RMAN_ARRAY }

struct u_resource {
	uint16 r_handle;	// resource uniquifier
	uint16 r_parent;	// parent rman
	uint16 r_device;	// device owning this resource
	string r_devname;	// device name XXX obsolete
	uint32 r_start;		// offset in resource space
	uint32 r_size;		// size in resource space
	uint32 r_flags;		// RF_* flags
}

struct u_rman {
	uint16 rm_handle;	// rman uniquifier
	string rm_descr;	// rman description
	uint32 m_start;		// base of managed region
	uint32 rm_size;		// sze of managed region
	rman_type rm_type;	// region type
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
	bytes r_vaddr;
}
struct s_resource_map_request {
	uint16 size;
	uint16 offset;
	uint16 length;
	uint16 memattr;
}

struct s_rman {
	uint16[] rm_list;
	uint16 rm_link;    // link in list of all rmans
	uint32 rm_start;   // index of globally first entry
	uint32 rm_end;	   // index of globally last entry
	rman_type rm_type; // what type of resource this is
	string rm_descr;   // text descripion of this resource
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
    uint16 link;    // STAILQ_ENTRY(resource_list_entry)
	uint16 rtype;	// type argument to alloc_resource
	uint16 rid;	    // resource identifier
	uint16 flags;	// resource flags
	s_resource res;	// the real resource when allocated
	uint32 start;	// start of resource range
	uint32 end;	    // end of resource range
	uint32 count;	// count within range
}
