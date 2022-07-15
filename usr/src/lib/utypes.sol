pragma ton-solidity >= 0.61.2;

enum vtype      { VNON, VREG, VDIR, VBLK, VCHR, VLNK, VSOCK, VFIFO, VBAD, VMARKER }
enum vgetstate  { VGET_NONE, VGET_HOLDCNT, VGET_USECOUNT }

enum idtype {
    P_PID,     // process
    P_PPID,    // parent process
    P_PGID,    // process group
    P_SID,     // session
    P_CID,     // scheduling class
    P_UID,     // user
    P_GID,     // group
    P_ALL,     // All
    P_LWPID,   // LWP
    P_TASKID,  // task
    P_PROJID,  // project
    P_POOLID,  // pool
    P_JAILID,  // zone
    P_CTID,    // (process) contract
    P_CPUID,   // CPU
    P_PSETID   // Processor set
}

struct s_stat {
    uint16 st_dev;      // ID of device containing file
    uint16 st_ino;      // Inode number
    uint16 st_mode;     // File type and mode
    uint16 st_nlink;    // Number of hard links
    uint16 st_uid;      // User ID of owner
    uint16 st_gid;      // Group ID of owner
    uint16 st_rdev;     // Device ID (if special file)
    uint32 st_size;     // Total size, in bytes
    uint16 st_blksize;  // Block size for filesystem I/O
    uint16 st_blocks;   // Number of 512B blocks allocated
    uint32 st_mtim;     // Time of last modification
    uint32 st_ctim;     // Time of last status change
}

struct s_kevent {
    uint32 ident;  // identifier for this event
    uint16 filter; // filter for event
    uint16 flags;  // action flags for kqueue
    uint16 fflags; // filter flag value
    uint64 data;   // filter data value
    bytes udata;   // opaque user data identifier
    uint64[4] ext; // extensions
}

struct s_xvnode {
    uint16 xv_vnode; // address of real vnode
    uint16 xv_flag;  // vnode vflags
    uint16 xv_id;    // capability identifier
    uint8 xv_type;  // vnode type
    bytes xv_un;
}

// Userland version of struct tty, for sysctl kern.ttys
struct s_xtty {
    uint16 xt_size;    // Structure size.
    uint16 xt_insize;  // Input queue size.
    uint16 xt_incc;    // Canonicalized characters.
    uint16 xt_inlc;    // Input line charaters.
    uint16 xt_inlow;   // Input low watermark.
    uint16 xt_outsize; // Output queue size.
    uint16 xt_outcc;   // Output queue usage.
    uint16 xt_outlow;  // Output low watermark.
    uint16 xt_column;  // Current column position.
    uint16 xt_pgid;    // Foreground process group.
    uint16 xt_sid;     // Session.
    uint16 xt_flags;   // Terminal option flags.
    uint32 xt_dev;     // Userland device. XXXKIB truncated
}

struct s_sigaction {
    uint32 __sigaction_u; // signal handler
    uint16 sa_flags;      // see signal options below
    uint8[] sa_mask;      // signal mask to apply
}

struct __siginfo {
    uint8 si_signo;  // signal number
    uint8 si_errno;  // errno association
    uint8 si_code;   // signal code
    uint16 si_pid;   // sending process
    uint16 si_uid;   // sender's ruid
    uint8 si_status; // exit value
    bytes si_addr;   // faulting instruction
    uint16 si_value; // signal value
    uint16 _reason;
}

struct s_stack {
    uint8 depth;
    uint32[18] pcs; // STACK_MAX
}

struct __ucontext {
    uint8[] uc_sigmask;
    uint16 uc_mcontext;
    s_stack uc_stack;
    uint16 uc_flags;
}

struct s_shm_largepage_conf {
    uint16 psind;
    uint16 alloc_policy;
}
struct s_shmfd {
    uint32 shm_size;
    uint16 shm_object;
    uint16 shm_refs;
    uint16 shm_uid;
    uint16 shm_gid;
    uint16 shm_mode;
    uint16 shm_kmappings;
    uint32 shm_atime;
    uint32 shm_mtime;
    uint32 shm_ctime;
    uint32 shm_birthtime;
    uint16 shm_ino;
    string shm_label;
    string shm_path;
    uint16 shm_flags;
    uint16 shm_seals;
    uint16 shm_lp_psind;
    uint16 shm_lp_alloc_policy;
}

struct s_vfsops {
    uint32 vfs_mount;
    uint32 vfs_cmount;
    uint32 vfs_unmount;
    uint32 vfs_root;
    uint32 vfs_cachedroot;
    uint32 vfs_quotactl;
    uint32 vfs_statfs;
    uint32 vfs_sync;
    uint32 vfs_vget;
    uint32 vfs_fhtovp;
    uint32 vfs_checkexp;
    uint32 vfs_init;
    uint32 vfs_uninit;
    uint32 vfs_extattrctl;
    uint32 vfs_sysctl;
    uint32 vfs_susp_clean;
    uint32 vfs_reclaim_lowervp;
    uint32 vfs_unlink_lowervp;
    uint32 vfs_purge;
}

// Userland version of the struct vfsconf.
struct s_xvfsconf {
    s_vfsops vfc_vfsops; // filesystem operations vector
    string vfc_name;     // filesystem type name
    uint16 vfc_typenum;  // historic filesystem type number
    uint16 vfc_refcount; // number mounted of this type
    uint16 vfc_flags;    // permanent flags
}

struct s_kevent_copyops {
    bytes arg;
    uint32 kcopyout; //int (bytes arg, s_kevent kevp, int count);
    uint32 kcopyin; // int (bytes arg, s_kevent kevp, int count);
    uint32 kevent_size;
}

struct s_bio_ops {
    uint32 io_start;     // (struct buf *);
    uint32 io_complete;  // (struct buf *);
    uint32 io_deallocate;// (struct buf *);
    uint32 io_countdeps; // int (struct buf *, int);
}

enum mount_counter { MNT_COUNT_REF, MNT_COUNT_LOCKREF, MNT_COUNT_WRITEOPCOUNT }

struct k_buf_ops {
    string bop_name;
    uint32 bop_write;     // int (struct buf *);
    uint32 bop_strategy;  //  (struct bufobj *, struct buf *);
    uint32 bop_sync;      // int (struct bufobj *, int waitfor);
    uint32 bop_bdflush;   // (struct bufobj *, struct buf *);
}

struct s_uprof {     // Profile arguments.
    uint32 pr_base;  // Buffer base.
    uint32 pr_size;  // Buffer size.
    uint32 pr_off;   // PC offset.
    uint32 pr_scale; // PC scaling.
}

struct s_sched_param {
    uint16 sched_priority;
}

// Window/terminal size structure.  This information is stored by the kernel
// in order to provide a consistent interface, but is not used by the kernel.
struct s_winsize {
    uint16 ws_row;    // rows, in characters
    uint16 ws_col;    // columns, in characters
    uint16 ws_xpixel; // horizontal size, pixels
    uint16 ws_ypixel; // vertical size, pixels
}

