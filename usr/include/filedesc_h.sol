pragma ton-solidity >= 0.67.0;
import "ucred_h.sol";
import "xio.sol";
struct s_xfile {
    uint8 xf_size;  // size of struct xfile
    uint16 xf_pid;  // owning process
    uint16 xf_uid;  // effective uid of owning process
    uint8 xf_fd;    // descriptor number
    uint8 xf_type;  // descriptor type
    uint8 xf_count; // reference count
    uint8 xf_msgcount; // references from message queue
    uint32 xf_offset;  // file offset
    uint16 xf_data;    // file descriptor specific data
    uint16 xf_vnode;   // vnode pointer
    uint16 xf_flag;    // flags (see fcntl.h)
}

struct s_fdescenttbl {
    uint8 fdt_nfiles;           // number of open files allocated
    s_filedescent[] fdt_ofiles;	// open files
}

struct s_filedesc {
    s_fdescenttbl fd_files; // open files table
    uint64 fd_map;      // bitmap of free fds
    uint16 fd_freefile; // approx. next free file
    uint16 fd_refcnt;   // thread reference count
}

struct fdescenttbl0 {
    uint8 fdt_nfiles;
    s_filedescent[20] fdt_ofiles;
}
struct filedesc0 {
    s_filedesc fd_fd;
//    SLIST_HEAD(, freetable) fd_free;
    fdescenttbl0 fd_dfiles;
//    NDSLOTTYPE fd_dmap[NDSLOTS(NDFILE)];
}
struct s_xfiledesc {
    uint16 fdt_nfiles;  // number of open files allocated
    s_of[] fdt_ofiles;  // open files
    s_filedesc fd_fd;
//    uint8 fd_nfiles;
//    s_filedescent[] fd_ofiles;
//    uint64 fd_map;      // bitmap of free fds
//    uint16 fd_freefile; // approx. next free file
//    uint16 fd_refcnt;   // thread reference count
}
struct s_xpwddesc {
    s_of pwd_cdir;
    s_of pwd_rdir;
//    s_of pwd_jdir;
    uint16 pd_cmask; // mask for file creation
}

struct pwd {
	uint8 pwd_refcount;
	uint8 pwd_cdir;	// vnode current directory
	uint8 pwd_rdir;	// vnode root directory
	uint8 pwd_jdir;	// vnode jail root directory
}
//typedef SMR_POINTER(struct pwd *) smrpwd_t;

struct pwddesc {
	uint8 pd_pwd;   // smrpwd_t directories
	uint8 pd_refcount;
	uint16 pd_cmask;	// mask for file creation
}

struct s_dirent {
    uint16 d_fileno;
    uint8 d_type;
    string d_name;
}
struct s_dirdesc {
    uint8 dd_fd;    // file descriptor associated with directory
    uint16 dd_loc;   // offset in current buffer
    uint16 dd_size;  // amount of data returned by getdirentries
    string dd_buf;   // data buffer
    uint16 dd_len;   // size of data buffer
    uint16 dd_seek;  // magic cookie returned by getdirentries
    uint16 dd_flags; // flags for readdir
    uint16 dd_td;    // telldir position recording
}

struct filecaps {
    uint64 fc_rights; // per-descriptor capability rights
    uint8[] fc_ioctls; // per-descriptor allowed ioctls
    uint8 fc_nioctls; // fc_ioctls array size
    uint32 fc_fcntls; // per-descriptor allowed fcntls
}

struct s_filedescent {
    s_file fde_file; // file structure for open file
    filecaps fde_caps;// per-descriptor rights
    uint8 fde_flags; // per-process open file flags
//  seqc_t fde_seqc; // keep file and caps in sync
}

struct s_fadvise_info {
    uint8 fa_advice; // FADV_* type
    uint32 fa_start;  // Region start
    uint32 fa_end;    // Region end
}

struct fops {
    uint32 fo_read;       // fo_rdwr_t
    uint32 fo_write;      // fo_rdwr_t
}

struct fileops  {
    uint32 fo_read;       // fo_rdwr_t
    uint32 fo_write;      // fo_rdwr_t
    uint32 fo_truncate;   // fo_truncate_t
    uint32 fo_ioctl;      // fo_ioctl_t
    uint32 fo_poll;       // fo_poll_t
//    uint32 fo_kqfilter;   // fo_kqfilter_t
    uint32 fo_stat;       // fo_stat_t
    uint32 fo_close;      // fo_close_t
    uint32 fo_chmod;      // fo_chmod_t
    uint32 fo_chown;      // fo_chown_t
    uint32 fo_sendfile;   // fo_sendfile_t
    uint32 fo_seek;       // fo_seek_t
//    uint32 fo_fill_kinfo; // fo_fill_kinfo_t
    uint32 fo_mmap;       // fo_mmap_t
    uint32 fo_aio_queue;  // fo_aio_queue_t
    uint32 fo_add_seals;  // fo_add_seals_t
    uint32 fo_get_seals;  // fo_get_seals_t
    uint32 fo_fallocate;  // fo_fallocate_t
    uint32 fo_fspacectl;  // fo_fspacectl_t
    uint16 fo_flags;      // DFLAG_* below //fo_flags_t
}

struct s_file {
    uint16 f_flag; // see fcntl
	uint8 f_count; // reference count
    bytes f_data;  // file descriptor specific data
    uint32 f_ops;  // fileops File operations
    uint8 f_vnode; // s_vnode NULL or applicable vnode
    uint32 f_cred; // s_ucred associated credentials
    uint8 f_type;  // descriptor type
    uint32[2] f_nextoff; // next expected read/write offset
    s_fadvise_info fvn_advice;
    uint32 f_offset;
}

// Structure to keep track of (process leader, struct fildedesc) tuples. Each process has a pointer to such a structure when detailed tracking
// is needed, e.g., when rfork(RFPROC | RFMEM) causes a file descriptor table to be shared by processes having different "p_leader" pointers
// and thus distinct POSIX style locks. fdl_refcount and fdl_holdcount are protected by struct filedesc mtx.
struct s_filedesc_to_leader {
	uint8 fdl_refcount;	// references from struct proc
	uint8 fdl_holdcount;// temporary hold during closef
	uint8 fdl_wakeup;	// fdfree() waits on closef()
	uint16 fdl_leader;	// s_proc owner of POSIX locks
//	struct filedesc_to_leader *fdl_prev;
//	struct filedesc_to_leader *fdl_next;
}
