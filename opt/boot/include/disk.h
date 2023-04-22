pragma ton-solidity >= 0.67.0;

enum disk_init_level { DISK_INIT_NONE, DISK_INIT_CREATE, DISK_INIT_START, DISK_INIT_DONE }

struct s_disk {
    bool d_goneflag;
    bool d_destroyed;
    disk_init_level d_init_level;
    uint16 d_flags;
    string d_name;
    uint8 d_unit;
    uint16 d_sectorsize;
    uint32 d_mediasize;
    uint16 d_fwsectors;
    uint16 d_fwheads;
    uint32 d_maxsize;
    string d_ident;
    string d_descr;
    uint16 d_hba_vendor;
    uint16 d_hba_device;
    string d_attachment;
}
struct partition {
	uint32 p_size;	 // number of sectors in partition
	uint32 p_offset; // starting sector
	uint8 p_fsize;	 // filesystem basic fragment size
	uint8 p_fstype;  // filesystem type, see below
	uint8 p_frag;	 // filesystem fragments per block
	uint8 p_cpg;	 // filesystem cylinders per group
}
struct disk_geometry {
    uint16 d_magic;      // the magic number
    uint16 d_secsize;    // # of bytes per sector
    uint16 d_nsectors;   // # of data sectors per track
    uint16 d_ntracks;    // # of tracks per cylinder
    uint16 d_ncylinders; // # of data cylinders per unit
    uint16 d_secpercyl;  // # of data sectors per cylinder
    uint32 d_secperunit; // # of data sectors per unit
}
struct disk_type {
    uint16 d_magic;      // the magic number
    uint8 d_type;        // drive type
    uint8 d_subtype;     // controller/d_type specific
    bytes8 d_typename;   // type name, e.g. `eagle'
    bytes8 d_packname;   // pack identifier
    bytes16 d_drivedata; // drive-type specific data
}
struct disklabel {
    uint16 d_magic;	        // the magic number
    uint8 d_type;           // drive type
    uint8 d_subtype;        // controller/d_type specific
    bytes8 d_typename;      // type name, e.g. `eagle'
    bytes8 d_packname;      // pack identifier
    uint8 padding;          // to 31 bytes
    uint8 d_secsize;        // # of bytes per sector
    uint8 d_nsectors;       // # of data sectors per track
    uint8 d_ntracks;        // # of tracks per cylinder
    uint16 d_ncylinders;    // # of data cylinders per unit
    uint16 d_secpercyl;     // # of data sectors per cylinder
    uint16 d_secperunit;    // # of data sectors per unit
    uint8 d_sparespertrack; // # of spare sectors per track
    uint8 d_sparespercyl;   // # of spare sectors per cylinder
    uint8 d_acylinders;     // # of alt. cylinders per unit
    uint8 d_trackskew;      // sector 0 skew, per track
    uint8 d_cylskew;        // sector 0 skew, per cylinder
    uint8 d_flags;          // generic flags
    bytes16 d_drivedata;    // drive-type specific data
    uint16 d_magic2;        // the magic number (again)
}
struct part_table {
    uint8 d_npartitions; // number of partitions in following
    uint16 d_bbsize;     // size of boot area at sn0, bytes
    uint8 d_sbsize;      // max size of fs superblock, bytes // 23
    partition[8] d_partitions; // the partition table
}
