pragma ton-solidity >= 0.67.0;

struct cdev {
    uint16 si_flags;
    uint32 si_atime;
    uint32 si_ctime;
    uint32 si_mtime;
    uint16 si_uid;
    uint16 si_gid;
    uint16 si_mode;
    uint16 si_cred;       // cached clone-time credential // ucred
    uint16 si_drv0;
    uint16 si_refcount;
    uint16 si_list;        // cdev
    uint16 si_clone;       // cdev
    uint16[] si_children;  // cdev
    uint16 si_siblings;    // cdev
    uint16 si_parent;      // cdev
    uint16 si_mountpt;     // mount
    uint32 si_drv1;
    uint32 si_drv2;
    uint16 si_devsw;        // cdevsw
    uint16 si_iosize_max;   // maximum I/O size (for physio &al)
    string si_name;
}

struct cdevsw {
    uint16 d_version;
    uint16 d_flags;
    string d_name;
    uint32 d_open;      // d_open_t
    uint32 d_fdopen;    // d_fdopen_t
    uint32 d_close;     // d_close_t
    uint32 d_read;      // d_read_t
    uint32 d_write;     // d_write_t
    uint32 d_ioctl;     // d_ioctl_t
    uint32 d_poll;      // d_poll_t
    uint32 d_mmap;      // d_mmap_t
    uint32 d_purge;     // d_purge_t
    uint32 d_mmap_single; // d_mmap_single_t
}
