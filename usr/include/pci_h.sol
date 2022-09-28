pragma ton-solidity >= 0.64.0;

enum pci_getconf_status {
    PCI_GETCONF_LAST_DEVICE,
    PCI_GETCONF_LIST_CHANGED,
    PCI_GETCONF_MORE_DEVS,
    PCI_GETCONF_ERROR
}

struct s_pcisel {
    uint8 pc_domain; // domain number
    uint8 pc_bus;     // bus number
    uint8 pc_dev;     // device on this bus
    uint8 pc_func;    // function on this device
}

struct s_pci_conf {
    s_pcisel pc_sel;     // domain+bus+slot+function
    uint8 pc_hdr;        // PCI header type
    uint8 pc_subvendor; // card vendor ID
    uint8 pc_subdevice; // card device ID, assigned by card vendor
    uint8 pc_vendor;    // chip vendor ID
    uint8 pc_device;    // chip device ID, assigned by chip vendor
    uint8 pc_class;      // chip PCI class
    uint8 pc_subclass;   // chip PCI subclass
    uint8 pc_progif;     // chip PCI programming interface
    uint8 pc_revid;      // chip revision ID
    string pd_name;      // [PCI_MAXNAMELEN + 1]; device name
    uint8 pd_unit;      // device unit number
}

struct s_pci_match_conf {
    s_pcisel pc_sel;  // domain+bus+slot+function
    string pd_name;   // PCI_MAXNAMELEN + 1];  device name
    uint8 pd_unit;    // Unit number
    uint8 pc_vendor; // PCI Vendor ID
    uint8 pc_device; // PCI Device ID
    uint8 pc_class;   // PCI class
    uint16 flags;     // Matching expression
}

struct pci_conf_io {
    uint32 pat_buf_len;	        // pattern buffer length
    uint8 num_patterns;         // number of patterns
    s_pci_match_conf patterns;  // pattern buffer
    uint32 match_buf_len;       // match buffer length
    uint8 num_matches;          // number of matches returned
    s_pci_conf matches;	        // match buffer
    uint32 offset;              // offset into device list
    uint8 generation;           // device list generation
    pci_getconf_status status;	// request status
}

struct pci_io {
    s_pcisel pi_sel; // device to operate on
    uint8 pi_reg;    // configuration register to examine
    uint32 pi_width; // width (in bytes) of read or write
    uint32 pi_data;  // data to write or result of read
}

struct pci_bar_io {
    s_pcisel pbi_sel;   // device to operate on
    uint32 pbi_reg;     // starting address of BAR
    bool pbi_enabled;   // decoding enabled
    uint64 pbi_base;    // current value of BAR
    uint64 pbi_length;  // length of BAR
}

struct pci_vpd_element {
    string[2] pve_keyword;
    uint8 pve_flags;
    uint8 pve_datalen;
    uint8 pve_data;
}

struct pci_list_vpd_io {
    s_pcisel plvi_sel;	// device to operate on
    uint32 plvi_len;	// size of the data area
    s_pci_vpd_element plvi_data;
}

struct pci_bar_mmap {
    uint32 pbm_map_base;    // (sometimes IN)/OUT mmaped base
    uint32 pbm_map_length;  // mapped length of the BAR, multiple of pages
    uint64 pbm_bar_length;  // actual length of the BAR
    uint32 pbm_bar_off;	    // offset from the mapped base to the start of BAR
    s_pcisel pbm_sel;       // device to operate on
    uint32 pbm_reg;         // starting address of BAR
    uint32 pbm_flags;
    uint32 pbm_memattr;
}

struct pci_bar_ioreq {
    s_pcisel pbi_sel; // device to operate on
    uint32 pbi_op;
    uint32 pbi_bar;
    uint32 pbi_offset;
    uint32 pbi_width;
    uint32 pbi_value;
}

//enum pci_getconf_flags {
//    PCI_GETCONF_NO_MATCH		= 0x0000,
//    PCI_GETCONF_MATCH_DOMAIN	= 0x0001,
//    PCI_GETCONF_MATCH_BUS		= 0x0002,
//    PCI_GETCONF_MATCH_DEV		= 0x0004,
//    PCI_GETCONF_MATCH_FUNC		= 0x0008,
//    PCI_GETCONF_MATCH_NAME		= 0x0010,
//    PCI_GETCONF_MATCH_UNIT		= 0x0020,
//    PCI_GETCONF_MATCH_VENDOR	= 0x0040,
//    PCI_GETCONF_MATCH_DEVICE	= 0x0080,
//    PCI_GETCONF_MATCH_CLASS		= 0x0100
//}

//#define PCI_MAXNAMELEN	16

//#define	PCIBARIO_READ		0x1
//#define	PCIBARIO_WRITE		0x2

//#define	PCIIO_BAR_MMAP_FIXED	0x01
//#define	PCIIO_BAR_MMAP_EXCL	0x02
//#define	PCIIO_BAR_MMAP_RW	0x04
//#define	PCIIO_BAR_MMAP_ACTIVATE	0x08
//
//#define	PCIOCGETCONF	_IOWR('p', 5, struct pci_conf_io)
//#define	PCIOCREAD	_IOWR('p', 2, struct pci_io)
//#define	PCIOCWRITE	_IOWR('p', 3, struct pci_io)
//#define	PCIOCATTACHED	_IOWR('p', 4, struct pci_io)
//#define	PCIOCGETBAR	_IOWR('p', 6, struct pci_bar_io)
//#define	PCIOCLISTVPD	_IOWR('p', 7, struct pci_list_vpd_io)
//#define	PCIOCBARMMAP	_IOWR('p', 8, struct pci_bar_mmap)
//#define	PCIOCBARIO	_IOWR('p', 9, struct pci_bar_ioreq)

//#define	PVE_FLAG_IDENT		0x01	/* Element is the string identifier */
//#define	PVE_FLAG_RW		0x02	/* Element is read/write */
//#define	PVE_NEXT(pve)	((struct pci_vpd_element *)((char *)(pve) + sizeof(struct pci_vpd_element) + (pve)->pve_datalen))