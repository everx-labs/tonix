pragma ton-solidity >= 0.66.0;
enum p_states { PRS_NEW, PRS_NORMAL, PRS_ZOMBIE }
enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }
struct proc {
    uint16 p_ucred;     // Process owner's identity // ucred
    uint16 p_fd;        // Open files   // filedesc
    uint16 p_fdtol;     // Tracking node   // filedesc_to_leader
    uint16 p_pd;        // Cwd, chroot, jail, umask // pwddesc
    uint16 p_sigacts;   // Signal actions, state (CPU)  // sigacts
    uint16 p_flag;      // P_* flags
    uint16 p_flag2;     // P2_* flags
    p_states p_state;   // Process status
    uint16 p_pid;	    // Process identifier
    uint16 p_pptr;	    // Pointer to parent process // proc
    uint16 p_ksi;	    // Locked by parent proc lock // ksiginfo
    uint32 p_siglist;   // Sigs not delivered to a td
    uint16 p_oppid;     // Real parent pid
    uint16 p_vmspace;   // Address space // vmspace
    uint16 p_textvp;    // Vnode of executable // vnode
    uint16 p_textdvp;   // Dir containing textvp // vnode
    string p_binname;   // Binary hardlink name
    uint16 p_sigiolst;  // List of sigio sources // sigiolst
    uint16 p_sigparent; // Signal to parent on exit
    uint16 p_sig;       // For core dump/debugger XXX
    uint16 p_ptevents;  // ptrace() event mask
    uint16 p_aioinfo;   // ASYNC I/O info // kaioinfo
    uint8 p_pendingcnt; // how many signals are pending
    uint8 p_pdeathsig;  // Signal from parent on exit
    uint32 p_magic;     // Magic number
    uint32 p_osrel;     // osreldate for the binary (from ELF note, if any)
    string p_comm;      // Process name
    uint16 p_sysent;    // Syscall dispatch info // sysentvec
    uint16 p_args;      // Process arguments // pargs
    int8 p_nice;        // Process "nice" value
    uint8 p_xexit;      // Exit code
    uint8 p_xsig;       // Stop/kill sig
    uint16 p_pgrp;      // Pointer to process group pgrp
    uint16 p_peers;     // proc
    uint16 p_leader;    // proc
}
struct thread {
    uint16 td_proc;     // Associated process // proc
    uint16 td_sel;      // Select queue/channel // seltd
    uint16 td_tid;      // Thread ID
    uint32 td_siglist;  // Sigs arrived, not delivered
    uint32 td_flags;    // TDF_* flags
    uint32 td_ast;      // TDA_* indicators
    uint32 td_pflags;   // Private thread (TDP_*) flags
    uint32 td_pflags2;  // Private thread (TDP2_*) flags
    uint8 td_dupfd;     // Ret value from fdopen
    uint16 td_realucred;// Reference to credentials // ucred
    uint16 td_ucred;    // Used credentials, temporarily switchable // ucred
    string td_name;     // Thread name
    uint16 td_fpop;     // file referencing cdev under op // file
    uint16 td_vp_reserved;// Preallocated vnode // vnode
    uint8 td_errno;     // Error from last syscall
    uint32 td_sigmask;  // Current signal mask
    uint16 td_sa;       // Syscall parameters. Copied on fork for child tracing // syscall_args
    td_states td_state; // thread state
    uint16 td_retval;   // Syscall aux returns
}
struct session {
    uint8 s_count;   // Ref cnt; pgrps in session - atomic
    uint16 s_leader; // Session leader // proc
    uint16 s_ttyvp;  // Vnode of controlling tty // vnode
    uint16 s_ttydp;  // Device of controlling tty. // cdev_priv
    uint16 s_ttyp;   // Controlling tty // tty
    uint16 s_sid;    // Session ID
    string s_login;  // Setlogin() name
}
struct pgrp {
    uint16[] pg_members;// Pointer to pgrp members
    uint16 pg_session;  // Pointer to session // session
    sigio[]	pg_sigiolst;// List of sigio sources
    uint16 pg_id;       // Process group id
    uint16 pg_flags;    // PGRP_ flags
}
struct sigio {
    uint16 siu_proc;  // process to receive SIGIO/SIGURG
    uint16 sio_myref; // location of the pointer that holds	the reference to this structure // sigio **
    uint16 sio_ucred; // current credentials // ucred
    uint16 sio_pgid;  // pgid for signals
}
