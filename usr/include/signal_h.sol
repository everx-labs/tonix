pragma ton-solidity >= 0.63.0;
import "ucred_h.sol";

struct sigset_t {
//    uint32[4] __bits; // _SIG_WORDS
    uint32[1] __bits; // _SIG_WORDS
}
// Logical process signal actions and state, needed only within the process. The mapping between sigacts and proc structures is 1:1 except for rfork()
// processes masquerading as threads which use one structure for the whole group.  All members are locked by the included mutex.  The reference count
// and mutex must be last for the bcopy in sigacts_copy() to work.
struct s_sigacts {
    uint32[128] ps_sigact;      // Disposition of signals. _SIG_MAXSIG
    uint32[128] ps_catchmask;   // Signals to be blocked. _SIG_MAXSIG
    sigset_t ps_sigonstack;     // Signals to take on sigstack.
    sigset_t ps_sigintr;        // Signals that interrupt syscalls.
    sigset_t ps_sigreset;       // Signals that reset when caught.
    sigset_t ps_signodefer;     // Signals not masked while handled.
    sigset_t ps_siginfo;        // Signals that want SA_SIGINFO args.
    sigset_t ps_sigignore;      // Signals being ignored.
    sigset_t ps_sigcatch;       // Signals being caught by user.
    sigset_t ps_freebsd4;       // Signals using freebsd4 ucontext.
    sigset_t ps_osigset;        // Signals using <= 3.x osigset_t.
    sigset_t ps_usertramp;      // SunOS compat; libc sigtramp. XXX
    uint32 ps_flag;
    uint32 ps_refcnt;
}

struct s_sigio {
    uint16 sio_proc;   // s_proc process to receive SIGIO/SIGURG
    uint16 sio_pgrp;   // s_pgrp process group to receive ...
    uint8 sio_pgsigio; // SLIST_ENTRY(sigio) sigio's for process or group
    uint8 sio_myref;   // s_sigio location of the pointer that holds the reference to this structure
    uint8 sio_ucred;   // s_ucred current credentials
    uint16 sio_pgid;   // pgid for signals
}

struct s_sigqueue {
    uint32 sq_signals;  // All pending signals.
    uint32 sq_kill;     // Legacy depth 1 queue.
    uint32 sq_ptrace;   // Depth 1 queue for ptrace(2).
    ksiginfo[] sq_list; // Queued signal info.
    uint16 sq_proc;
    uint16 sq_flags;
}

struct ksiginfo {
    uint32 ksi_link; // TAILQ_ENTRY(ksiginfo)
    s_siginfo ksi_info;
    uint8 ksi_flags;
    uint32 ksi_sigq; //  s_sigqueue
}

struct s_sigevent {
    uint8 sigev_notify; // Notification type
    uint8 sigev_signo;  // Signal number
    uint32 sigev_value; // Signal value
    uint16 _threadid;
}

struct s_siginfo {
    uint8 si_signo;  // signal number
    uint8 si_errno;  // errno association
    uint8 si_code;   // signal code
    uint16 si_pid;   // sending process
    uint16 si_uid;   // sender's ruid
    uint8 si_status; // exit value
    uint32 si_addr;  // faulting instruction
    uint32 si_value; // signal value
    uint32 trapno;   // machine specific trap code
}

//typedef	__sighandler_t	*sig_t;	// type of pointer to a signal function
//typedef	void __siginfohandler_t(int, struct __siginfo *, void


// Signal vector "template" used in sigaction call.
struct s_sigaction {
    uint32 sa_handler; // signal handler
    uint16 sa_flags;   // see signal options below
    uint32 sa_mask;    // signal mask to apply
}

// Signal vector "template" used in sigvec call.
struct s_sigvec {
    uint32 sv_handler; // signal handler
    uint16 sv_mask;    // signal mask to apply
    uint16 sv_flags;   // see signal options below
}

//__sighandler_t *signal(int, __sighandler_t *);
