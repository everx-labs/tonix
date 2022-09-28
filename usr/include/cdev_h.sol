pragma ton-solidity >= 0.64.0;
//import "ucred_h.sol";
struct s_cdev {
    uint16 si_flags;
    uint32 si_atime;
    uint32 si_ctime;
    uint32 si_mtime;
    uint16 si_uid;
    uint16 si_gid;
    uint16 si_mode;
    uint32 si_cred;  // s_ucred cached clone-time credential
    uint8 si_drv0;
    uint8 si_refcount;
    uint32 si_parent; // s_cdev
    uint32 si_mountpt;  // s_mount
    uint32 si_drv1;
    uint32 si_drv2;
	uint32 si_devsw; // cdevsw
    uint16 si_iosize_max; // maximum I/O size (for physio &al)
    uint8 si_usecount;
    uint8 si_threadcount;
    string si_name;
}

struct s_cdevsw {
    uint32 d_version;
    uint16 d_flags;
    string d_name;
    uint32 d_open;  // d_open_t ID 1517397130
    uint32 d_fdopen;// d_fdopen_t ID 2918828990
    uint32 d_close; // d_close_t ID 2024148992
    uint32 d_read;  // d_read_t ID 3888666218
    uint32 d_write; // d_write_t ID 729573231
    uint32 d_ioctl; // d_ioctl_t ID 3433572656
    uint32 d_poll;  // d_poll_t ID 3509366529
    uint32 d_mmap;  // d_mmap_t
    uint32 d_strategy; // d_strategy_t
    uint32 d_kqfilter; // d_kqfilter_t
    uint32 d_purge; // d_purge_t ID 769467768
    uint32 d_mmap_single; // d_mmap_single_t ID 389430846
    uint32 d_devs; // LIST_HEAD(, cdev)
}
struct s_make_dev_args {
    uint16 mda_size;
    uint16 mda_flags;
	uint32 mda_devsw; // s_cdevsw
    uint32 mda_cr; // s_ucred
    uint16 mda_uid;
    uint16 mda_gid;
    uint16 mda_mode;
    uint8 mda_unit;
	uint32 mda_si_drv1;
	uint32 mda_si_drv2;
    string mda_name;
}
