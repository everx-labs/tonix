struct kinfo_proc {
    uint16     ki_structsize;          // size of this structure
    uint16     ki_layout;              // reserved: layout identifier
    s_pargs ki_args;         // address of command arguments
    s_proc ki_paddr;         // address of proc
    struct  user *ki_addr;          // kernel virtual addr of u-area
    k_vnode ki_tracep;       // pointer to trace file
    k_vnode ki_textvp;       // pointer to executable file
    struct  filedesc *ki_fd;        // pointer to open file info
    struct  vmspace *ki_vmspace;    // pointer to kernel vmspace struct
    bytes ki_wchan;           // sleep address
    uint16 ki_pid;                 // Process identifier
    uint16 ki_ppid;                // parent process id
    uint16 ki_pgid;                // process group id
    uint16 ki_tpgid;               // tty process group id
    uint16 ki_sid;                 // Process session ID
    uint16 ki_tsid;                // Terminal session ID
    uint16 ki_jobc;                // job control counter
    uint32 ki_tdev_freebsd11;     // controlling tty dev
    uint16[] ki_siglist;            // Signals arrived but not delivered
    uint16[] ki_sigmask;            // Current signal mask
    uint16[] ki_sigignore;          // Signals being ignored
    uint16[] ki_sigcatch;           // Signals being caught by user
    uint16 ki_uid;                 // effective user id
    uint16 ki_ruid;                // Real user id
    uint16 ki_svuid;               // Saved effective user id
    uint16 ki_rgid;                // Real group id
    uint16 ki_svgid;               // Saved effective group id
    uint16   ki_ngroups;             // number of groups
    uint16[]   ki_groups;           // groups [KI_NGROUPS]
    uint32 ki_size;              // virtual size
    uint32 ki_rssize;              // current resident set size in pages
    uint32 ki_swrss;               // resident set size before last swap
    uint32 ki_tsize;               // text size (pages) XXX
    uint32 ki_dsize;               // data size (pages) XXX
    uint32 ki_ssize;               // stack size (pages)
    uint16 ki_xstat;               // Exit status for wait & stop signal
    uint16 ki_acflag;              // Accounting flags
    uint16 ki_pctcpu;              // %cpu for process during ki_swtime
    uint16 ki_estcpu;              // Time averaged value of ki_cpticks
    uint16 ki_slptime;             // Time since last blocked
    uint16 ki_swtime;              // Time swapped in or out
    uint16 ki_cow;                 // number of copy-on-write faults
    uint64 ki_runtime;           // Real time in microsec
    uint32 ki_start;       // starting time
    uint32 ki_childtime;   // time used by process children
    uint32    ki_flag;                // P_* flags
    uint32    ki_kiflag;              // KI_* flags (below)
    uint16     ki_traceflag;           // Kernel trace points
    uint8    ki_stat;                // S* process status
    int8  ki_nice;            // Process "nice" value
    uint8    ki_lock;                // Process lock (prevent swap) count
    uint8    ki_rqindex;             // Run queue index
    uint8  ki_oncpu_old;           // Which cpu we are on (legacy)
    uint8  ki_lastcpu_old;         // Last cpu we were on (legacy)
    string ki_tdname[TDNAMLEN+1];  // thread name
    string ki_wmesg[WMESGLEN+1];   // wchan message
    string ki_login[LOGNAMELEN+1]; // setlogin name
    string ki_lockname[LOCKNAMELEN+1]; // lock name
    string ki_comm[COMMLEN+1];     // command name
    string ki_emul[KI_EMULNAMELEN+1];  // emulation name
    string ki_loginclass[LOGINCLASSLEN+1]; // login class
    string ki_moretdname[MAXCOMLEN-TDNAMLEN+1];    // more thread name
    uint64 ki_tdev;               // controlling tty dev
    uint16     ki_oncpu;               // Which cpu we are on
    uint16     ki_lastcpu;             // Last cpu we were on
    uint16     ki_tracer;              // Pid of tracing process
    uint16     ki_flag2;               // P2_* flags
    uint16     ki_fibnum;              // Default FIB number
    uint16   ki_cr_flags;            // Credential flags
    uint16     ki_jid;                 // Process jail ID
    uint16     ki_numthreads;          // XXXKSE number of threads in total
    uint16 ki_tid;                 // XXXKSE thread id
    struct  priority ki_pri;        // process priority
    s_rusage ki_rusage;       // process rusage statistics
    s_rusage ki_rusage_ch;    // rusage of children processes
    struct  pcb *ki_pcb;            // kernel virtual addr of pcb
    uint32  ki_kstack;             // kernel virtual addr of stack
    uint32  ki_udata;              // User convenience pointer
    s_thread ki_tdaddr;      // address of thread
    struct  pwddesc *ki_pd;         // pointer to process paths info
    uint32    ki_sflag;               // PS_* flags
    uint32    ki_tdflags;             // XXXKSE kthread flag
}

struct user {
    struct  pstats u_stats;         // *p_stats
    struct  kinfo_proc u_kproc;     // eproc
}

struct kf_sock {
    uint32 kf_sock_sendq;           // Sendq size
    uint16 kf_sock_domain0;         // Socket domain.
    uint16 kf_sock_type0;           // Socket type.
    uint16 kf_sock_protocol0;       // Socket protocol.
    k_sockaddr_storage kf_sa_local; // Socket address.
    k_sockaddr_storage kf_sa_peer;  // Peer address.
    uint64 kf_sock_pcb;             // Address of so_pcb.
    uint64 kf_sock_inpcb;           // Address of inp_ppcb.
    uint64 kf_sock_unpconn;         // Address of unp_conn.
    uint16 kf_sock_snd_sb_state;    // Send buffer state.
    uint16 kf_sock_rcv_sb_state;    // Receive buffer state.
    uint32 kf_sock_recvq;           // Recvq size.
}

struct kf_file {
    uint16 kf_file_type;           // Vnode type.
    uint64 kf_file_fsid;           // Vnode filesystem id.
    uint64 kf_file_rdev;           // File device.
    uint64 kf_file_fileid;         // Global file id.
    uint64 kf_file_size;           // File size.
    uint16 kf_file_mode;           // File mode.
}

struct kf_pipe {
    uint64 kf_pipe_addr;
    uint64 kf_pipe_peer;
    uint32 kf_pipe_buffer_cnt;
}
struct kf_pts {
    uint64 kf_pts_dev;
}
struct kf_proc {
    uint16 kf_pid;
}
struct kf_eventfd {
    uint64 kf_eventfd_value;
    uint32 kf_eventfd_flags;
}

struct kinfo_file {
    uint16 kf_type;       // Descriptor type.
    uint16 kf_fd;         // Array index.
    uint16 kf_ref_count;  // Reference count.
    uint16 kf_flags;      // Flags.
    int64  kf_offset;     // Seek location.
    uint16 kf_status;     // Status flags
    uint32 kf_cap_rights; // Capability rights
    string kf_path;       // Path to file, if any PATH_MAX
}

struct kinfo_vmentry {
    uint16 kve_type;              // Type of map entry
    uint64 kve_start;             // Starting address
    uint64 kve_end;               // Finishing address
    uint64 kve_offset;            // Mapping offset in objec
    uint64 kve_vn_fileid;         // inode number if vnod
    uint16 kve_flags;             // Flags on map entry
    uint16 kve_resident;          // Number of resident pages
    uint16 kve_private_resident;  // Number of private pages
    uint16 kve_protection;        // Protection bitmask
    uint16 kve_ref_count;         // VM obj ref count
    uint16 kve_shadow_count;      // VM obj shadow count
    uint16 kve_vn_type;           // Vnode type
    uint64 kve_vn_size;           // File size
    uint16 kve_vn_mode;           // File mode
    uint16 kve_status;            // Status flags
    uint64 kve_vn_fsid;           // dev_t of vnode locatio
    uint64 kve_vn_rdev;           // Device id if device
    string kve_path;            // Path to VM obj, if any PATH_MAX
}

struct kinfo_vmobject {
    uint16 kvo_type;              // Object type: KVME_TYPE_*.
    uint64 kvo_size;              // Object size in pages.
    uint64 kvo_vn_fileid;         // inode number if vnode.
    uint16 kvo_ref_count;         // Reference count.
    uint16 kvo_shadow_count;      // Shadow count.
    uint16 kvo_memattr;           // Memory attribute.
    uint64 kvo_resident;          // Number of resident pages.
    uint64 kvo_active;            // Number of active pages.
    uint64 kvo_inactive;          // Number of inactive pages.
    uint64 kvo_vn_fsid;
    string kvo_path;              // Pathname, if any. PATH_MAX
}

struct kinfo_kstack {
    uint16 kkst_tid;   // ID of thread.
    uint16 kkst_state; // Validity of stack.
    string kkst_trace; // String representing stack. KKST_MAXLEN
}

struct kinfo_sigtramp {
    bytes ksigtramp_start;
    bytes ksigtramp_end;
}


library user {
    uint8 constant KI_NSPARE_INT  = 2;
    uint8 constant KI_NSPARE_LONG = 12;
    uint8 constant KI_NSPARE_PTR  = 5;

    uint8 constant WMESGLEN       = 8; // size of returned wchan message
    uint8 constant LOCKNAMELEN    = 8; // size of returned lock name
    uint8 constant TDNAMLEN       = 16; // size of returned thread name
    uint8 constant COMMLEN        = 19; // size of returned ki_comm name
    uint8 constant KI_EMULNAMELEN = 16; // size of returned ki_emul
    uint8 constant KI_NGROUPS     = 16; // number of groups in ki_groups
    uint8 constant LOGNAMELEN     = 17; // size of returned ki_login
    uint8 constant LOGINCLASSLEN  = 17; // size of returned ki_loginclass

    uint32 constant KI_CRF_CAPABILITY_MODE = 0x00000001;
    uint32 constant KI_CRF_GRP_OVERFLOW    = 0x80000000;

void fill_kinfo_proc(struct proc *, struct kinfo_proc *);

    uint32 constant PS_INMEM = 0x00001; // Loaded into memory.

    uint32 constant KI_CTTY      = 0x00000001; // controlling tty vnode active
    uint32 constant KI_SLEADER   = 0x00000002; // session leader
    uint32 constant KI_LOCKBLOCK = 0x00000004; // proc blocked on lock ki_lockname

    uint32 constant KF_ATTR_VALID =  0x0001;

    uint8 constant KF_TYPE_NONE   = 0;
    uint8 constant KF_TYPE_VNODE  = 1;
    uint8 constant KF_TYPE_SOCKET = 2;
    uint8 constant KF_TYPE_PIPE   = 3;
    uint8 constant KF_TYPE_FIFO   = 4;
    uint8 constant KF_TYPE_KQUEUE = 5;
    // was  KF_TYPE_CRYPTO  6
    uint8 constant KF_TYPE_MQUEUE  = 7;
    uint8 constant KF_TYPE_SHM     = 8;
    uint8 constant KF_TYPE_SEM     = 9;
    uint8 constant KF_TYPE_PTS     = 10;
    uint8 constant KF_TYPE_PROCDESC = 11;
    uint8 constant KF_TYPE_DEV     = 12;
    uint8 constant KF_TYPE_EVENTFD = 13;
    uint8 constant KF_TYPE_UNKNOWN = 255;

    uint8 constant KF_VTYPE_VNON   = 0;
    uint8 constant KF_VTYPE_VREG   = 1;
    uint8 constant KF_VTYPE_VDIR   = 2;
    uint8 constant KF_VTYPE_VBLK   = 3;
    uint8 constant KF_VTYPE_VCHR   = 4;
    uint8 constant KF_VTYPE_VLNK   = 5;
    uint8 constant KF_VTYPE_VSOCK  = 6;
    uint8 constant KF_VTYPE_VFIFO  = 7;
    uint8 constant KF_VTYPE_VBAD   = 8;
    uint8 constant KF_VTYPE_UNKNOWN = 255;

    int8 constant KF_FD_TYPE_CWD  = -1;      // Current working directory
    int8 constant KF_FD_TYPE_ROOT = -2;      // Root directory
    int8 constant KF_FD_TYPE_JAIL = -3;      // Jail directory
    int8 constant KF_FD_TYPE_TRACE = -4;      // Ktrace vnode
    int8 constant KF_FD_TYPE_TEXT = -5;      // Text vnode
    int8 constant KF_FD_TYPE_CTTY = -6;      // Controlling terminal

    uint32 constant KF_FLAG_READ     = 0x00000001;
    uint32 constant KF_FLAG_WRITE    = 0x00000002;
    uint32 constant KF_FLAG_APPEND   = 0x00000004;
    uint32 constant KF_FLAG_ASYNC    = 0x00000008;
    uint32 constant KF_FLAG_FSYNC    = 0x00000010;
    uint32 constant KF_FLAG_NONBLOCK = 0x00000020;
    uint32 constant KF_FLAG_DIRECT   = 0x00000040;
    uint32 constant KF_FLAG_HASLOCK  = 0x00000080;
    uint32 constant KF_FLAG_SHLOCK   = 0x00000100;
    uint32 constant KF_FLAG_EXLOCK   = 0x00000200;
    uint32 constant KF_FLAG_NOFOLLOW = 0x00000400;
    uint32 constant KF_FLAG_CREAT    = 0x00000800;
    uint32 constant KF_FLAG_TRUNC    = 0x00001000;
    uint32 constant KF_FLAG_EXCL     = 0x00002000;
    uint32 constant KF_FLAG_EXEC     = 0x00004000;

    uint8 constant KVME_TYPE_NONE      = 0;
    uint8 constant KVME_TYPE_DEFAULT   = 1;
    uint8 constant KVME_TYPE_VNODE     = 2;
    uint8 constant KVME_TYPE_SWAP      = 3;
    uint8 constant KVME_TYPE_DEVICE    = 4;
    uint8 constant KVME_TYPE_PHYS      = 5;
    uint8 constant KVME_TYPE_DEAD      = 6;
    uint8 constant KVME_TYPE_SG        = 7;
    uint8 constant KVME_TYPE_MGTDEVICE = 8;
    uint8 constant KVME_TYPE_UNKNOWN   = 255;

    uint32 constant KVME_PROT_READ       = 0x00000001;
    uint32 constant KVME_PROT_WRITE      = 0x00000002;
    uint32 constant KVME_PROT_EXEC       = 0x00000004;

    uint32 constant KVME_FLAG_COW        = 0x00000001;
    uint32 constant KVME_FLAG_NEEDS_COPY = 0x00000002;
    uint32 constant KVME_FLAG_NOCOREDUMP = 0x00000004;
    uint32 constant KVME_FLAG_SUPER      = 0x00000008;
    uint32 constant KVME_FLAG_GROWS_UP   = 0x00000010;
    uint32 constant KVME_FLAG_GROWS_DOWN = 0x00000020;
    uint32 constant KVME_FLAG_USER_WIRED = 0x00000040;

    uint16 constant KKST_MAXLEN     = 1024;

    uint8 constant KKST_STATE_STACKOK = 0; // Stack is valid.
    uint8 constant KKST_STATE_SWAPPED = 1; // Stack swapped out.
    uint8 constant KKST_STATE_RUNNING = 2; // Stack ephemeral.

    uint8 constant KERN_PROC_NOTHREADS = 0x1;
    uint8 constant KERN_PROC_MASK32    = 0x2;

    uint32 constant KERN_FILEDESC_PACK_KINFO = 0x00000001;

    uint32 constant KERN_VMMAP_PACK_KINFO = 0x00000001;

int     kern_proc_filedesc_out(s_proc p, s_sbuf sb, uint32 maxlen, int flags);
int     kern_proc_cwd_out(s_proc p, s_sbuf sb, uint32 maxlen);
int     kern_proc_out(s_proc p, s_sbuf sb, int flags);
int     kern_proc_vmmap_out(s_proc p, s_sbuf sb, uint32 maxlen, int flags);

int     vntype_to_kinfo(int vtype);
void    pack_kinfo(struct kinfo_file *kif);
}