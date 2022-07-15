pragma ton-solidity >= 0.62.0;

import "ucred_h.sol";
import "filedesc_h.sol";
import "racct_h.sol";
import "sysent_h.sol";

enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }

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
    s_ucred p_ucred;     // Process owner's identity
    s_xfiledesc p_fd;    // Open files
    s_xpwddesc p_pd;     // Cwd, chroot, jail, umask
    s_plimit p_limit;    // Resource limits
    uint32 p_flag;       // P_* flags
    uint16 p_pid;        // Process identifier
    uint16 p_oppid;      // Real parent pid
    string p_comm;       // Process name
    s_sysent[] p_sysent; // Syscall dispatch info
    s_pargs p_args;      // Process arguments
    string[] environ;
    uint8 p_xexit;      // Exit code
    uint16 p_numthreads; // Number of threads
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
struct s_thread {
//    s_proc td_proc;    // Associated process
    uint16 td_proc;    // Associated process
    uint16 td_tid;     // Thread ID
    uint16 td_flags;   // TDF_* flags
    uint16 td_dupfd;   // Ret value from fdopen
    s_ucred td_realucred; // Reference to credentials
    s_ucred td_ucred;  // Used credentials, temporarily switchable
    s_plimit td_limit; // Resource limits
    string td_name;    // Thread name
    uint8 td_errno;    // Error from last syscall
    td_states td_state; // thread state
    uint32 td_retval;
}
struct s_unrhdr {  // Header element for a unr number space.
    uint16 low;    // Lowest item
    uint16 high;   // Highest item
    uint16 busy;   // Count of allocated items
    uint16 alloc;  // Count of memory allocations
    uint16 first;  // items in allocated from start
    uint16 last;   // items free at end
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
