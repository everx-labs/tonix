pragma ton-solidity >= 0.61.2;

enum vtype      { VNON, VREG, VDIR, VBLK, VCHR, VLNK, VSOCK, VFIFO, VBAD, VMARKER }
enum vgetstate  { VGET_NONE, VGET_HOLDCNT, VGET_USECOUNT }
enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }
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

struct s_of {
    uint attr;
    uint16 flags;
    uint16 file;
    string path;
    uint32 offset;
    s_sbuf buf;
}

struct s_sockaddr {
    uint8 sa_family;
    string sa_data;
}

struct s_sockaddr_in {
  uint8 sin_family;
  uint16 sin_port;
  uint sin_addr;
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

struct s_rusage {
    uint32 ru_utime;    // user time used
    uint32 ru_stime;    // system time used
    uint32 ru_maxrss;   // max resident set size
    uint32 ru_ixrss;    // integral shared memory size
    uint32 ru_idrss;    // integral unshared data "
    uint32 ru_isrss;    // integral unshared stack "
    uint32 ru_minflt;   // page reclaims
    uint32 ru_majflt;   // page faults
    uint32 ru_nswap;    // swaps
    uint32 ru_inblock;  // block input operations
    uint32 ru_oublock;  // block output operations
    uint32 ru_msgsnd;   // messages sent
    uint32 ru_msgrcv;   // messages received
    uint32 ru_nsignals; // signals received
    uint32 ru_nvcsw;    // voluntary context switches
    uint32 ru_nivcsw;   // involuntary "
}

struct s___wrusage {
    s_rusage wru_self;
    s_rusage wru_children;
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

struct s_xucred {
    uint16 cr_uid;       // effective user id
    uint8 cr_ngroups;    // number of groups
    uint16[] cr_groups;  // groups
    uint16 cr_pid;
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
    uint32[6] vfs_spare;  // spares for ABI compat
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

/*struct s_file {
    uint16 f_flag;  // see fcntl.h
    string path;
    bytes f_data;   // file descriptor specific data
    uint32 f_offset;
}*/

// Userland version of struct file, for sysctl
struct s_xfile {
//    uint16 xf_size;     // size of struct xfile
    uint16 xf_pid;      // owning process
    uint16 xf_uid;      // effective uid of owning process
    uint16 xf_fd;       // descriptor number
    uint8  xf_type;     // descriptor type
    uint16 xf_count;    // reference count
    uint16 xf_msgcount; // references from message queue
    uint32 xf_offset;   // file offset
    bytes xf_data;      // file descriptor specific data
    uint16 xf_vnode;    // vnode pointer
    uint16 xf_flag;     // flags (see fcntl.h)
}

struct s_rlimit {
    uint32 rlim_cur; // current (soft) limit
    uint32 rlim_max; // maximum value for rlim_cur
}

struct s_plimit {
    s_rlimit[15] pl_rlimit; // RLIM_NLIMITS
    uint16 pl_refcnt;       // number of references
}

struct s_sbuf {
    bytes buf;       // storage buffer
    uint8 error;    // current error code
    uint32 size;     // size of storage buffer
    uint16 len;      // current length of string
    uint32 flags;    // flags
    uint16 sect_len; // current length of section
    uint32 rec_off;  // current record start offset
}

// Window/terminal size structure.  This information is stored by the kernel
// in order to provide a consistent interface, but is not used by the kernel.
struct s_winsize {
    uint16 ws_row;    // rows, in characters
    uint16 ws_col;    // columns, in characters
    uint16 ws_xpixel; // horizontal size, pixels
    uint16 ws_ypixel; // vertical size, pixels
}

struct s_loginclass {
    string lc_name;
    uint16 lc_refcount;
    s_racct lc_racct;
}

struct s_racct {
    uint64[25] r_resources; // RACCT_MAX + 1
}

struct s_xsockbuf {
    uint32 sb_cc;
    uint32 sb_hiwat;
    uint32 sb_mbcnt;
    uint32 sb_mcnt;
    uint32 sb_ccnt;
    uint32 sb_mbmax;
    int32 sb_lowat;
    int32 sb_timeo;
    int16 sb_flags;
}
/*
 * Structure to export socket from kernel to utilities, via sysctl(3).
 */
struct s_xsocket {
//    ksize         xso_len;        // length of this structure
    uint16 xso_so;         // kernel address of struct socket
    uint16 so_pcb;         // kernel address of struct inpcb
    uint64 so_oobmark;
//    int64         so_spare64[8];
    int32  xso_protocol;
    int32  xso_family;
    uint32 so_qlen;
    uint32 so_incqlen;
    uint32 so_qlimit;
    uint16 so_pgid;
    uint16 so_uid;
//    int32         so_spare32[8];
    int16 so_type;
    int16 so_options;
    int16 so_linger;
    int16 so_state;
    int16 so_timeo;
    uint16 so_error;
    s_xsockbuf so_rcv;
    s_xsockbuf so_snd;
}
