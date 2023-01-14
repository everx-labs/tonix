pragma ton-solidity >= 0.62.0;

import "ucred_h.sol";
import "filedesc_h.sol";
import "racct_h.sol";
import "sysent_h.sol";
import "signal_h.sol";

enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }
enum p_states { PRS_NEW, PRS_NORMAL, PRS_ZOMBIE }
enum tda { TDA_AST, TDA_OWEUPC, TDA_HWPMC, TDA_VFORK, TDA_ALRM, TDA_PROF, TDA_MAC, TDA_SCHED, TDA_UFS, TDA_GEOM, TDA_KQUEUE, TDA_RACCT, TDA_MOD1, TAD_MOD2, TDA_SIG, TDA_KTRACE, TDA_SUSPEND, TDA_SIGSUSPEND, TDA_MOD3, TAD_MOD4, TDA_MAX }

struct s_ar_misc {
    string argv;
    string flags;
    string sargs;
    uint16 n_params;
    string[] pos_params;
    uint8 ec;
    string last_param;
    string opt_err;
    string redir_in;
    string redir_out;
    s_dirent[] pos_args;
    string[][2] opt_values;
}
struct s_opt_arg {
    string opt_name;
    string opt_value;
}
struct s_pargs {
    uint16 ar_length; // Length
    string[] ar_args; // Arguments
    s_ar_misc ar_misc;
}

struct s_proc {
    s_ucred p_ucred;      // Process owner's identity
    s_xfiledesc p_fd;     // Open files
    s_xpwddesc p_pd;      // Cwd, chroot, jail, umask
    s_plimit p_limit;     // Resource limits
    uint32 p_flag;        // P_* flags
    uint16 p_pid;         // Process identifier
    ksiginfo p_ksi;       // Locked by parent proc lock
    s_sigqueue p_sigqueue; // Sigs not delivered to a td
    uint16 p_oppid;       // Real parent pid
    string p_comm;        // Process name
    s_sysentvec p_sysent; // Syscall dispatch info
    s_pargs p_args;       // Process arguments
    string[] environ;
    uint8 p_xexit;        // Exit code
    uint8 p_xsig;         // Stop/kill sig.
    uint16 p_pgrp;        // Pointer to process group.
    uint16 p_numthreads;  // Number of threads
    uint16 p_leader;
}

struct proc {
    uint8 p_ucred;      // Process owner's identity
//    s_xfiledesc p_fd;     // Open files
    s_filedesc p_fd;     // Open files
    s_xpwddesc p_pd;      // Cwd, chroot, jail, umask
    s_plimit p_limit;     // Resource limits
    uint32 p_flag;        // P_* flags
    uint16 p_pid;         // Process identifier
    ksiginfo p_ksi;       // Locked by parent proc lock
    s_sigqueue p_sigqueue; // Sigs not delivered to a td
    uint16 p_oppid;       // Real parent pid
    string p_comm;        // Process name
    s_sysentvec p_sysent; // Syscall dispatch info
    s_pargs p_args;       // Process arguments
    string[] environ;
    uint8 p_xexit;        // Exit code
    uint8 p_xsig;         // Stop/kill sig.
    uint16 p_pgrp;        // Pointer to process group.
    uint16 p_numthreads;  // Number of threads
    uint16 p_leader;
}

struct s_proc_old {
    s_ucred p_ucred;      // Process owner's identity
    s_xfiledesc p_fd;     // Open files
    s_xpwddesc p_pd;      // Cwd, chroot, jail, umask
    s_plimit p_limit;     // Resource limits
    uint32 p_flag;        // P_* flags
    uint16 p_pid;         // Process identifier
    ksiginfo p_ksi;       // Locked by parent proc lock
    s_sigqueue p_sigqueue; // Sigs not delivered to a td
    uint16 p_oppid;       // Real parent pid
    string p_comm;        // Process name
    s_sysentvec p_sysent; // Syscall dispatch info
    s_pargs p_args;       // Process arguments
    string[] environ;
    uint8 p_xexit;        // Exit code
    uint8 p_xsig;         // Stop/kill sig.
    uint16 p_pgrp;        // Pointer to process group.
    uint16 p_numthreads;  // Number of threads
    uint16 p_leader;
}

struct s_loadavg {
    uint32[3] ldavg;
    uint32 fscale;
}
struct s_ps_strings {
    string[] ps_argvstr; // first of 0 or more argument strings
    uint16 ps_nargvstr;  // the number of argument strings
    string[] ps_envstr;  // first of 0 or more environment strings
    uint16 ps_nenvstr;   // the number of environment strings
}

struct s_syscall_args {
    uint16 code;
    uint16 original_code;
    s_sysent callp;
    uint16[8] args;
}

struct s_thread {
    s_proc td_proc;    // Associated process
    uint16 td_tid;     // Thread ID
    s_sigqueue td_sigqueue; // Sigs arrived, not delivered.
    uint32 td_flags;   // TDF_* flags
    uint32 td_pflags;  // Private thread (TDP_*) flags.
    uint8 td_dupfd;   // Ret value from fdopen
    s_ucred td_realucred; // Reference to credentials
    s_ucred td_ucred;  // Used credentials, temporarily switchable
    s_plimit td_limit; // Resource limits
    string td_name;    // Thread name
    uint8 td_errno;    // Error from last syscall
    uint32 td_sigmask; // Current signal mask (actually sigset_t)
    s_syscall_args td_sa; // Syscall parameters. Copied on fork for child tracing
//  td_sigblock_ptr;   // uptr for fast sigblock.
//  uint32 td_sigblock_val; // fast sigblock value read at
    td_states td_state; // thread state
    uint32 td_retval;
}

struct thread {
    uint8 td_proc;    // Associated process
    uint16 td_tid;     // Thread ID
    s_sigqueue td_sigqueue; // Sigs arrived, not delivered.
    uint32 td_flags;   // TDF_* flags
    uint32 td_pflags;  // Private thread (TDP_*) flags.
    uint8 td_dupfd;   // Ret value from fdopen
    uint8 td_realucred; // Reference to credentials
    uint8 td_ucred;  // Used credentials, temporarily switchable
    s_plimit td_limit; // Resource limits
    string td_name;    // Thread name
    uint8 td_errno;    // Error from last syscall
    uint32 td_sigmask; // Current signal mask (actually sigset_t)
    s_syscall_args td_sa; // Syscall parameters. Copied on fork for child tracing
//  td_sigblock_ptr;   // uptr for fast sigblock.
//  uint32 td_sigblock_val; // fast sigblock value read at
    td_states td_state; // thread state
    uint32 td_retval;
}

struct s_unrhdr { // Header element for a unr number space.
    uint16 low;   // Lowest item
    uint16 high;  // Highest item
    uint16 busy;  // Count of allocated items
    uint16 alloc; // Count of memory allocations
    uint16 first; // items in allocated from start
    uint16 last;  // items free at end
}
struct s_prstatus {
    uint16 pr_version;   // Version number of struct
    uint16 pr_osreldate; // Kernel version
    uint16 pr_cursig;    // Current signal
    uint16 pr_pid;       // LWP (Thread) ID
}
struct s_prpsinfo {
    uint16 pr_version;  // Version number of struct
    string pr_fname;    // Command name, null terminated [PRFNAMESZ+1]
    string pr_psargs;   // Arguments, null terminated [PRARGSZ+1];
    uint16 pr_pid;      // Process ID
}
struct s_thrmisc {
    string pr_tname; // Thread name, null terminated [MAXCOMLEN+1];
}

struct s_pgrp {
    s_proc[] pg_members;   // Pointer to pgrp members.
    s_session pg_session;  // Pointer to session.
    s_sigio[] pg_sigiolst; // List of sigio sources.
    uint16 pg_id;          // Process group id.
    uint16 pg_flags;       // PGRP_ flags
}

struct s_session {
    uint16 s_count; // Ref cnt; pgrps in session - atomic
    uint16 s_leader;// Session leader
    uint16 s_ttyvp; // Vnode of controlling tty
    uint16 s_ttydp; // Device of controlling tty
    uint16 s_ttyp;  // Controlling tty
    uint16 s_sid;   // Session ID
    string s_login; // Setlogin() name
}
