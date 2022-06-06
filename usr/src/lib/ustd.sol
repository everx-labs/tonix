pragma ton-solidity >= 0.58.0;

import "stypes.sol";
/*struct s_filedesc {
    s_fdescenttbl fd_files;      // open files table
    uint64 fd_map;               // bitmap of free fds
    uint16 fd_freefile;          // approx. next free file
    uint16 fd_refcnt;            // thread reference count
    uint16 fd_holdcnt;           // hold count on structure + mutex
    uint16 fd_holdleaderscount;  // block fdfree() for shared close()
    uint16 fd_holdleaderswakeup; // fdfree() needs wakeup
}
struct s_filecaps {
    uint32 fc_rights;   // per-descriptor capability rights
    uint64 fc_ioctls;   // per-descriptor allowed ioctls
    uint16 fc_nioctls;  // fc_ioctls array size
    uint32 fc_fcntls;   // per-descriptor allowed fcntls
}
struct s_filedescent {
//    s_file fde_file;  // file structure for open file
    s_of fde_file;  // file structure for open file
    uint32 fde_caps;  // per-descriptor rights
    uint8 fde_flags;  // per-process open file flags
    uint16 fde_seqc;  // keep file and caps in sync
}
struct s_fdescenttbl {
    uint16 fdt_nfiles;          // number of open files allocated
    s_filedescent[] fdt_ofiles; // open files
}
struct s_proc {
    s_ucred p_ucred;       // (c) Process owner's identity.
    s_filedesc p_fd;          // (b) Open files.
    s_pwddesc p_pd;          // (b) Cwd, chroot, jail, umask
    s_plimit p_limit;       // (c) Resource limits.
    uint32 p_flag;         // (/) P_* flags.
    uint16 p_pid;          // (b) Process identifier.
    uint16 p_oppid;    // (c + e) Real parent pid.
    uint16 p_sigparent;    // (c) Signal to parent on exit.
    s_thread p_singlethread;// (c + j) If single threading this is it
    uint16 p_treeflag;     // (e) P_TREE flags
//    struct filemon  *p_filemon;     // (c) filemon-specific data.
    uint16 p_magic;        // (b) Magic number.
    string p_comm;  // (x) Process name.
    s_pargs p_args;        // (c) Process arguments.
    uint16 p_fibnum;       // in this routing domain XXX MRT
    uint16 p_reapsubtree;  // (e) Pid of the direct child of the reaper which spawned our subtree.
    uint16 p_elf_machine;  // (x) ELF machine type
    uint64 p_elf_flags;    // (x) ELF flags
    uint16 p_xexit;        // (c) Exit code.
    uint16 p_xsig;         // (c) Stop/kill sig.
    s_pgrp p_pgrp;        // (c + e) Pointer to process group.
    uint16 p_numthreads;   // (c) Number of threads.
    uint16 p_acflag;       // (c) Accounting flags.
    uint16[] p_peers;       // (r)
    uint16 p_leader;      // (b)
}*/

/*struct s_proc {
    s_ucred p_ucred;     // Process owner's identity.
    s_xfiledesc p_fd;    // Open files.
    s_xpwddesc p_pd;     // Cwd, chroot, jail, umask
    s_plimit p_limit;    // Resource limits.
    uint32 p_flag;       // P_* flags.
    uint16 p_pid;        // Process identifier.
    uint16 p_oppid;      // Real parent pid.
    string p_comm;       // Process name.
    s_pargs p_args;      // Process arguments.
    uint16 p_xexit;      // Exit code.
    uint16 p_numthreads; // Number of threads.
    uint16 p_leader;
}*/

struct s_xsession {
    uint16 s_count;      // Ref cnt; pgrps in session - atomic.
    s_proc s_leader;     // Session leader.
    s_xtty k_ttyp;        // Controlling tty.
    uint16 s_sid;        // Session ID.
    string s_login;      // Setlogin() name:
}

struct s_xpgrp {
    s_proc[] pg_members;   // Pointer to pgrp members.
    s_xsession pg_session;  // Pointer to session.
    uint16 pg_id;          // Process group id.
    uint16 pg_flags;       // PGRP_ flags
}

/*struct s_thread {
//    s_proc td_proc;         // Associated process.
    uint16 td_tid;          // Thread ID.
    // Cleared during fork
    uint16 td_flags;        // TDF_* flags.
    uint16 td_dupfd;        // Ret value from fdopen. XXX
    s_ucred td_realucred;   // Reference to credentials.
    s_ucred td_ucred;       // Used credentials, temporarily switchable.
    s_plimit td_limit;      // Resource limits.
    string td_name;         // Thread name.
    s_xfile td_fpop;         // file referencing cdev under op
//    k_vnode td_vp_reserved; // Prealloated vnode.
    uint32 td_sleeptimo;    // Sleep timeout.
    uint16 td_errno;        // Error from last syscall.
    uint16 td_ucredref;     // references on td_realucred
    // Fields that must be manually set in fork1() or create_thread()
    // or already have been set in the allocator, constructor, etc.
    td_states td_state;     // thread state
//    uint32 tdu_off;
//    s_proc td_rfppwait_p;   // The vforked child
}*/