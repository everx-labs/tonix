pragma ton-solidity >= 0.64.0;

enum md_types { MD_MALLOC, MD_PRELOAD, MD_VNODE, MD_SWAP, MD_NULL }

struct md_ioctl {
    uint32 md_version;	// Structure layout version
    uint32 md_unit;	    // unit number
    md_types md_type;   // type of disk
    string md_file;	    // pathname of file to mount
    uint32 md_mediasize;// size of disk in bytes
    uint32 md_sectorsize; // sectorsize
    uint32 md_options;	// options
    uint32 md_base;	    // base address
    uint32 md_fwheads;	// firmware heads
    uint32 md_fwsectors;// firmware sectors
    string md_label;	// label of the device
}

library libmdioctl {
// Ioctl definitions for memory disk pseudo-device.
    uint8 constant MDNPAD =		96;

    string constant MD_NAME	= 	"md";
    string constant MDCTL_NAME	= "mdctl";
    uint8 constant MDIOVERSION =	0;

    // Before you can use a unit, it must be configured with MDIOCSET. The configuration persists across opens and closes of the device;
    // an MDIOCCLR must be used to reset a configuration.  An attempt to MDIOCSET an already active unit will return EBUSY.

//    uint32 constant MDIOCATTACH	= _IOWR('m', 0, struct md_ioctl); // attach disk
//    uint32 constant MDIOCDETACH	= _IOWR('m', 1, struct md_ioctl); // detach disk
//    uint32 constant MDIOCQUERY	= _IOWR('m', 2, struct md_ioctl); // query status
//    uint32 constant MDIOCRESIZE	= _IOWR('m', 4, struct md_ioctl); // resize disk

    uint16 constant MD_CLUSTER	= 0x01;	// Don't cluster
    uint16 constant MD_RESERVE	= 0x02;	// Pre-reserve swap
    uint16 constant MD_AUTOUNIT	= 0x04;	// Assign next free unit
    uint16 constant MD_READONLY	= 0x08;	// Readonly mode
    uint16 constant MD_COMPRESS	= 0x10;	// Compression mode
    uint16 constant MD_FORCE	= 0x20;	// Don't try to prevent foot-shooting
    uint16 constant MD_ASYNC	= 0x40;	// Asynchronous mode
    uint16 constant MD_VERIFY	= 0x80;	// Open file with O_VERIFY (vnode only)
    uint16 constant MD_CACHE	= 0x100;// Cache vnode data
    uint16 constant MD_MUSTDEALLOC = 0x200;// BIO_DELETE only if dealloc is available
}

library libioccom {

// Ioctl's have the command encoded in the lower word, and the size of any in or out parameters in the upper word.  The high 3 bits of the
// upper word are used to encode the in/out status of the parameter.
//	 31 29 28                     16 15            8 7             0
//	+---------------------------------------------------------------+
//	| I/O | Parameter Length        | Command Group | Command       |
//	+---------------------------------------------------------------+
    uint32 constant IOCPARM_SHIFT	= 13;		/* number of bits for ioctl size */
    uint32 constant IOCPARM_MASK = (1 << IOCPARM_SHIFT) - 1; /* parameter length mask */

    uint32 constant IOCPARM_MAX = 1 << IOCPARM_SHIFT; /* max size of ioctl */

    uint32 constant IOC_VOID =	0x20000000;	// no parameters
    uint32 constant IOC_OUT =	0x40000000;	// copy out parameters
    uint32 constant IOC_IN =	0x80000000;	// copy in parameters
    uint32 constant IOC_INOUT =	IOC_IN | IOC_OUT; // copy parameters in and out
    uint32 constant IOC_DIRMASK = IOC_VOID | IOC_OUT | IOC_IN; // mask for IN/OUT/VOID
    uint32 constant	_IOC_INVALID =	_IOC_VOID | _IOC_INOUT;	// Never valid cmd value, use as filler

    uint8 constant T_0 = 0;
    uint8 constant T_INT = 1;

    function IOCPARM_LEN(uint32 x) internal returns (uint32) {
        return (x >> 16) & IOCPARM_MASK;
    }

    function IOCBASECMD(uint32 x) internal returns (uint32) {
        return x & ~(IOCPARM_MASK << 16);
    }

    function IOCGROUP(uint32 x) internal returns (uint32) {
        return (x >> 8) & 0xff;
    }


    function iosizeof(uint8 t) internal returns (uint16) {
        if (t == T_0) return 0;
        if (t == T_INT) return 4;

    }
    function _IOC(uint32 inout, uint8 group, uint8 num, uint16 len)	internal returns (uint32) {
        return inout | ((len & IOCPARM_MASK) << 16) | (group << 8) | num;
    }

    function _IO(uint8 g, uint8 n) internal returns (uint32) {
        return _IOC(IOC_VOID, g, n, 0);
    }

    function _IOWINT(uint8 g, uint8 n) internal returns (uint32) {
        return _IOC(IOC_VOID, g, n, iosizeof(T_INT));
    }

    function _IOR(uint8 g, uint8 n, uint8 t) internal returns (uint32) {
        return _IOC(IOC_OUT, g, n, iosizeof(t));
    }

    function _IOW(uint8 g, uint8 n, uint8 t) internal returns (uint32) {
        return _IOC(IOC_IN,	g, n, iosizeof(t));
    }

    function _IOWR(uint8 g, uint8 n, uint8 t) internal returns (uint32) {
        return _IOC(IOC_INOUT, g, n, iosizeof(t));
    }

    function _IOC_NEWLEN(uint16 ioc, uint16 len) internal returns (uint32) {
        return ((~(IOCPARM_MASK << 16)) & ioc) | ((len & IOCPARM_MASK) << 16);
    }

    function _IOC_NEWTYPE(uint16 ioc, uint8 ntype) internal returns (uint32) {
        return _IOC_NEWLEN(ioc, iosizeof(ntype));
    }

    function IOCPARM_IVAL(uint32 x) internal returns (uint32) {
//        return ((int)(intptr_t)(void *)*(caddr_t *)(void *)(x));
    }


/* this should be _IORW, but stdio got there first */
/* Replace length/type in an ioctl command. */

}