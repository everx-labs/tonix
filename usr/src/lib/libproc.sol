pragma ton-solidity >= 0.67.0;

import "proc_h.sol";
import "ucred_h.sol";
import "filedesc_h.sol";
import "racct_h.sol";
import "signal_h.sol";
import "sysent_h.sol";
import "str.sol";
library libproc {

    uint8 constant ENOSYS       = 78; // Function not implemented

    // Flags kept in td_flags: To change these you MUST have the scheduler lock.
    uint32 constant TDF_BORROWING   = 0x00000001;  // Thread is borrowing pri from another.
    uint32 constant TDF_INPANIC     = 0x00000002;  // Caused a panic, let it drive crashdump.
    uint32 constant TDF_INMEM       = 0x00000004;  // Thread's stack is in memory.
    uint32 constant TDF_SINTR       = 0x00000008;  // Sleep is interruptible.
    uint32 constant TDF_TIMEOUT     = 0x00000010;  // Timing out during sleep.
    uint32 constant TDF_IDLETD      = 0x00000020;  // This is a per-CPU idle thread.
    uint32 constant TDF_CANSWAP     = 0x00000040;  // Thread can be swapped.
    uint32 constant TDF_SIGWAIT     = 0x00000080;  // Ignore ignored signals
    uint32 constant TDF_KTH_SUSP    = 0x00000100;  // kthread is suspended
    uint32 constant TDF_ALLPROCSUSP = 0x00000200;  // suspended by SINGLE_ALLPROC
    uint32 constant TDF_BOUNDARY    = 0x00000400;  // Thread suspended at user boundary
    uint32 constant TDF_ASTPENDING  = 0x00000800;  // Thread has some asynchronous events.
    uint32 constant TDF_KQTICKLED   = 0x00001000;  // AST drain kqueue taskqueue
    uint32 constant TDF_SBDRY       = 0x00002000;  // Stop only on usermode boundary.
    uint32 constant TDF_UPIBLOCKED  = 0x00004000;  // Thread blocked on user PI mutex.
    uint32 constant TDF_NEEDSUSPCHK = 0x00008000;  // Thread may need to suspend.
    uint32 constant TDF_NEEDRESCHED = 0x00010000;  // Thread needs to yield.
    uint32 constant TDF_NEEDSIGCHK  = 0x00020000;  // Thread may need signal delivery.
    uint32 constant TDF_NOLOAD      = 0x00040000;  // Ignore during load avg calculations.
    uint32 constant TDF_SERESTART   = 0x00080000;  // ERESTART on stop attempts.
    uint32 constant TDF_THRWAKEUP   = 0x00100000;  // Libthr thread must not suspend itself.
    uint32 constant TDF_SEINTR      = 0x00200000;  // EINTR on stop attempts.
    uint32 constant TDF_SWAPINREQ   = 0x00400000;  // Swapin request due to wakeup.
    uint32 constant TDF_DOING_SA    = 0x00800000;  // Doing SINGLE_ALLPROC, do not unsuspend me
    uint32 constant TDF_SCHED0      = 0x01000000;  // Reserved for scheduler private use
    uint32 constant TDF_SCHED1      = 0x02000000;  // Reserved for scheduler private use
    uint32 constant TDF_SCHED2      = 0x04000000;  // Reserved for scheduler private use
    uint32 constant TDF_SCHED3      = 0x08000000;  // Reserved for scheduler private use
    uint32 constant TDF_ALRMPEND    = 0x10000000;  // Pending SIGVTALRM needs to be posted.
    uint32 constant TDF_PROFPEND    = 0x20000000;  // Pending SIGPROF needs to be posted.
    uint32 constant TDF_MACPEND     = 0x40000000;  // AST-based MAC event pending.

    // Userland debug flags
    uint32 constant TDB_SUSPEND     = 0x00000001; // Thread is suspended by debugger
    uint32 constant TDB_XSIG        = 0x00000002; // Thread is exchanging signal under trace
    uint32 constant TDB_USERWR      = 0x00000004; // Debugger modified memory or registers
    uint32 constant TDB_SCE         = 0x00000008; // Thread performs syscall enter
    uint32 constant TDB_SCX         = 0x00000010; // Thread performs syscall exit
    uint32 constant TDB_EXEC        = 0x00000020; // TDB_SCX from exec(2) family
    uint32 constant TDB_FORK        = 0x00000040; // TDB_SCX from fork(2) that created new process
    uint32 constant TDB_STOPATFORK  = 0x00000080; // Stop at the return from fork (child only)
    uint32 constant TDB_CHILD       = 0x00000100; // New child indicator for ptrace()
    uint32 constant TDB_BORN        = 0x00000200; // New LWP indicator for ptrace()
    uint32 constant TDB_EXIT        = 0x00000400; // Exiting LWP indicator for ptrace()
    uint32 constant TDB_VFORK       = 0x00000800; // vfork indicator for ptrace()
    uint32 constant TDB_FSTP        = 0x00001000; // The thread is PT_ATTACH leader
    uint32 constant TDB_STEP        = 0x00002000; // (x86) PSL_T set for PT_STEP
    uint32 constant TDB_SSWITCH     = 0x00004000; // Suspended in ptracestop
    uint32 constant TDB_COREDUMPRQ  = 0x00008000; // Coredump request

    //  "Private" flags kept in td_pflags: These are only written by curthread and thus need no locking.
    uint32 constant TDP_OLDMASK       = 0x00000001; // Need to restore mask after suspend.
    uint32 constant TDP_INKTR         = 0x00000002; // Thread is currently in KTR code.
    uint32 constant TDP_INKTRACE      = 0x00000004; // Thread is currently in KTRACE code.
    uint32 constant TDP_BUFNEED       = 0x00000008; // Do not recurse into the buf flush
    uint32 constant TDP_COWINPROGRESS = 0x00000010; // Snapshot copy-on-write in progress.
    uint32 constant TDP_ALTSTACK      = 0x00000020; // Have alternate signal stack.
    uint32 constant TDP_DEADLKTREAT   = 0x00000040; // Lock acquisition - deadlock treatment.
    uint32 constant TDP_NOFAULTING    = 0x00000080; // Do not handle page faults.
    uint32 constant TDP_SIGFASTBLOCK  = 0x00000100; // Fast sigblock active
    uint32 constant TDP_OWEUPC        = 0x00000200; // Call addupc() at next AST.
    uint32 constant TDP_ITHREAD       = 0x00000400; // Thread is an interrupt thread.
    uint32 constant TDP_SYNCIO        = 0x00000800; // Local override, disable async i/o.
    uint32 constant TDP_SCHED1        = 0x00001000; // Reserved for scheduler private use
    uint32 constant TDP_SCHED2        = 0x00002000; // Reserved for scheduler private use
    uint32 constant TDP_SCHED3        = 0x00004000; // Reserved for scheduler private use
    uint32 constant TDP_SCHED4        = 0x00008000; // Reserved for scheduler private use
    uint32 constant TDP_GEOM          = 0x00010000; // Settle GEOM before finishing syscall
    uint32 constant TDP_SOFTDEP       = 0x00020000; // Stuck processing softdep worklist
    uint32 constant TDP_NORUNNINGBUF  = 0x00040000; // Ignore runningbufspace check
    uint32 constant TDP_WAKEUP        = 0x00080000; // Don't sleep in umtx cond_wait
    uint32 constant TDP_INBDFLUSH     = 0x00100000; // Already in BO_BDFLUSH, do not recurse
    uint32 constant TDP_KTHREAD       = 0x00200000; // This is an official kernel thread
    uint32 constant TDP_CALLCHAIN     = 0x00400000; // Capture thread's callchain
    uint32 constant TDP_IGNSUSP       = 0x00800000; // Permission to ignore the MNTK_SUSPEND*
    uint32 constant TDP_AUDITREC      = 0x01000000; // Audit record pending on thread
    uint32 constant TDP_RFPPWAIT      = 0x02000000; // Handle RFPPWAIT on syscall exit
    uint32 constant TDP_RESETSPUR     = 0x04000000; // Reset spurious page fault history.
    uint32 constant TDP_NERRNO        = 0x08000000; // Last errno is already in td_errno
    uint32 constant TDP_UIOHELD       = 0x10000000; // Current uio has pages held in td_ma
    uint32 constant TDP_UNUSED0       = 0x20000000; // UNUSED
    uint32 constant TDP_EXECVMSPC     = 0x40000000; // Execve destroyed old vmspace
    uint32 constant TDP_SIGFASTPENDING = 0x80000000; // Pending signal due to sigfastblock

    uint32 constant TDP2_SBPAGES      = 0x00000001; // Owns sbusy on some pages
    uint32 constant TDP2_COMPAT32RB   = 0x00000002; // compat32 ABI for robust lists
    uint32 constant TDP2_ACCT         = 0x00000004; // Doing accounting

    // Reasons that the current thread can not be run yet. More than one may apply.
    uint16 constant TDI_SUSPENDED      = 0x0001; // On suspension queue.
    uint16 constant TDI_SLEEPING       = 0x0002; // Actually asleep! (tricky).
    uint16 constant TDI_SWAPPED        = 0x0004; // Stack not in mem.  Bad juju if run.
    uint16 constant TDI_LOCK           = 0x0008; // Stopped on a lock.
    uint16 constant TDI_IWAIT          = 0x0010; // Awaiting interrupt.

    uint32 constant P_ADVLOCK          = 0x00000001; // Process may hold a POSIX advisory lock.
    uint32 constant P_CONTROLT         = 0x00000002; // Has a controlling terminal.
    uint32 constant P_KPROC            = 0x00000004; // Kernel process.
    uint32 constant P_UNUSED3          = 0x00000008; // --available--
    uint32 constant P_PPWAIT           = 0x00000010; // Parent is waiting for child to exec/exit.
    uint32 constant P_PROFIL           = 0x00000020; // Has started profiling.
    uint32 constant P_STOPPROF         = 0x00000040; // Has thread requesting to stop profiling.
    uint32 constant P_HADTHREADS       = 0x00000080; // Has had threads (no cleanup shortcuts)
    uint32 constant P_SUGID            = 0x00000100; // Had set id privileges since last exec.
    uint32 constant P_SYSTEM           = 0x00000200; // System proc: no sigs, stats or swapping.
    uint32 constant P_SINGLE_EXIT      = 0x00000400; // Threads suspending should exit, not wait.
    uint32 constant P_TRACED           = 0x00000800; // Debugged process being traced.
    uint32 constant P_WAITED           = 0x00001000; // Someone is waiting for us.
    uint32 constant P_WEXIT            = 0x00002000; // Working on exiting.
    uint32 constant P_EXEC             = 0x00004000; // Process called exec.
    uint32 constant P_WKILLED          = 0x00008000; // Killed, go to kernel/user boundary ASAP.
    uint32 constant P_CONTINUED        = 0x00010000; // Proc has continued from a stopped state.
    uint32 constant P_STOPPED_SIG      = 0x00020000; // Stopped due to SIGSTOP/SIGTSTP.
    uint32 constant P_STOPPED_TRACE    = 0x00040000; // Stopped because of tracing.
    uint32 constant P_STOPPED_SINGLE   = 0x00080000; // Only 1 thread can continue (not to user).
    uint32 constant P_PROTECTED        = 0x00100000; // Do not kill on memory overcommit.
    uint32 constant P_SIGEVENT         = 0x00200000; // Process pending signals changed.
    uint32 constant P_SINGLE_BOUNDARY  = 0x00400000; // Threads should suspend at user boundary.
    uint32 constant P_HWPMC            = 0x00800000; // Process is using HWPMCs
    uint32 constant P_JAILED           = 0x01000000; // Process is in jail.
    uint32 constant P_TOTAL_STOP       = 0x02000000; // Stopped in stop_all_proc.
    uint32 constant P_INEXEC           = 0x04000000; // Process is in execve().
    uint32 constant P_STATCHILD        = 0x08000000; // Child process stopped or exited.
    uint32 constant P_INMEM            = 0x10000000; // Loaded into memory.
    uint32 constant P_SWAPPINGOUT      = 0x20000000; // Process is being swapped out.
    uint32 constant P_SWAPPINGIN       = 0x40000000; // Process is being swapped in.
    uint32 constant P_PPTRACE          = 0x80000000; // PT_TRACEME by vforked child.
    uint32 constant P_STOPPED = 0x000E0000; // P_STOPPED_SIG | P_STOPPED_SINGLE | P_STOPPED_TRACE;

    uint16 constant PGET_HOLD	= 0x00001;	    // Hold the process
    uint16 constant PGET_CANSEE	= 0x00002;	    // Check against p_cansee()
    uint16 constant PGET_CANDEBUG	= 0x00004;	// Check against p_candebug()
    uint16 constant PGET_ISCURRENT	= 0x00008;	// Check that the found process is current
    uint16 constant PGET_NOTWEXIT	= 0x00010;	// Check that the process is not in P_WEXIT
    uint16 constant PGET_NOTINEXEC	= 0x00020;	// Check that the process is not in P_INEXEC
    uint16 constant PGET_NOTID	= 0x00040;	    // Do not assume tid if pid > PID_MAX
    uint16 constant PGET_WANTREAD	= (PGET_HOLD | PGET_CANDEBUG | PGET_NOTWEXIT);

    uint32 constant	PGRP_ORPHANED = 0x00000001;	/* Group is orphaned */
    uint8 constant SINGLE_NO_EXIT =	0;
    uint8 constant SINGLE_EXIT =	1;
    uint8 constant SINGLE_BOUNDARY =	2;
    uint8 constant SINGLE_ALLPROC =	3;

    using libproc for s_thread;

    uint16 constant SYS_exit    = 1;
    uint16 constant SYS_fork    = 2;
    uint16 constant SYS_wait4   = 7;
    uint16 constant SYS_execve  = 59;
    uint16 constant SYS_vfork   = 66;
    uint16 constant SYS_rfork   = 251;
    uint16 constant SYS_fexecve = 492;
    uint16 constant SYS_pdfork  = 518;

    function proc_to_cell(s_proc p) internal returns (TvmCell) {
        TvmBuilder b;
        b.store(p);
        return b.toCell();
    }

    function thread_to_cell(s_thread t) internal returns (TvmCell) {
        TvmBuilder b;
        b.store(t);
        return b.toCell();
    }

    function proc0() internal returns (s_proc) {
        s_ucred p_ucred;
        s_xfiledesc p_fd;
        s_xpwddesc p_pd;
        s_plimit p_limit;
        uint32 p_flag;
        uint16 p_pid = 0;
        ksiginfo p_ksi;
        s_sigqueue p_sigqueue;
        uint16 p_oppid;
        string p_comm;
        s_sysentvec p_sysent;
        s_pargs p_args;
        string[] environ;
        uint8 p_xexit;
        uint8 p_xsig;
        uint16 p_pgrp;
        uint16 p_numthreads;
        uint16 p_leader;
        return s_proc(p_ucred, p_fd, p_pd, p_limit, p_flag, p_pid, p_ksi, p_sigqueue, p_oppid, p_comm, p_sysent, p_args, environ, p_xexit, p_xsig, p_pgrp, p_numthreads, p_leader);
    }

    function thread0() internal returns (s_thread) {
        s_proc td_proc = proc0();    // Associated process
        uint16 td_tid;     // Thread ID
        s_sigqueue td_sigqueue; // Sigs arrived, not delivered.
        uint32 td_flags;   // TDF_* flags
        uint32 td_pflags;  // Private thread (TDP_*) flags.
        uint8 td_dupfd;    // Ret value from fdopen
        s_ucred td_realucred; // Reference to credentials
        s_ucred td_ucred;  // Used credentials, temporarily switchable
        s_plimit td_limit; // Resource limits
        string td_name;    // Thread name
        uint8 td_errno;    // Error from last syscall
        uint32 td_sigmask; // Current signal mask (actually sigset_t)
        s_syscall_args td_sa; // Syscall parameters. Copied on fork for child tracing
        td_states td_state; // thread state
        uint32 td_retval;
        return s_thread(td_proc, td_tid, td_sigqueue, td_flags, td_pflags, td_dupfd, td_realucred, td_ucred, td_limit, td_name, td_errno, td_sigmask, td_sa, td_state, td_retval);
    }
    function curproc(TvmCell c) internal returns (s_proc) {
        TvmSlice s = c.toSlice();
        (s_ucred p_ucred, s_xfiledesc p_fd, s_xpwddesc p_pd, s_plimit p_limit, uint32 p_flag, uint16 p_pid, ksiginfo p_ksi, s_sigqueue p_sigqueue, uint16 p_oppid, string p_comm, s_sysentvec p_sysent, s_pargs p_args, string environ, uint8 p_xexit, uint8 p_xsig, uint16 p_pgrp, uint16 p_numthreads, uint16 p_leader) =
            s.decode(s_ucred, s_xfiledesc, s_xpwddesc, s_plimit, uint32, uint16, ksiginfo, s_sigqueue, uint16, string, s_sysentvec, s_pargs, string, uint8, uint8, uint16, uint16, uint16);
        return s_proc(p_ucred, p_fd, p_pd, p_limit, p_flag, p_pid, p_ksi, p_sigqueue, p_oppid, p_comm, p_sysent, p_args, [environ], p_xexit, p_xsig, p_pgrp, p_numthreads, p_leader);
    }

    function curthread(TvmCell c) internal returns (s_thread) {
        TvmSlice s = c.toSlice();
        (s_proc td_proc, uint16 td_tid, s_sigqueue td_sigqueue, uint32 td_flags, uint32 td_pflags, uint8 td_dupfd, s_ucred td_realucred, s_ucred td_ucred, s_plimit td_limit, string td_name, uint8 td_errno, uint32 td_sigmask, s_syscall_args td_sa, td_states td_state, uint32 td_retval) =
            s.decode(s_proc, uint16, s_sigqueue, uint32, uint32, uint8, s_ucred, s_ucred, s_plimit, string, uint8, uint32, s_syscall_args, td_states, uint32);
        return s_thread(td_proc, td_tid, td_sigqueue, td_flags, td_pflags, td_dupfd, td_realucred, td_ucred, td_limit, td_name, td_errno, td_sigmask, td_sa, td_state, td_retval);
    }

    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS_fork || n == SYS_vfork) return 0;
        else if (n == SYS_exit || n == SYS_rfork)
            return 1;
        else if (n == SYS_execve)
            return 3;
        else if (n == SYS_wait4)
            return 4;
    }
    function syscall_ids() internal returns (uint16[]) {
        return [SYS_exit, SYS_fork, SYS_wait4, SYS_execve, SYS_vfork, SYS_rfork, SYS_fexecve, SYS_pdfork];
    }
    function syscall_name(uint16 number) internal returns (string) {
        if (number == SYS_exit) return "exit";
        if (number == SYS_fork) return "fork";
        if (number == SYS_wait4) return "wait4";
        if (number == SYS_execve) return "execve";
        if (number == SYS_vfork) return "vfork";
        if (number == SYS_rfork) return "rfork";
        if (number == SYS_fexecve) return "fexecve";
        if (number == SYS_pdfork) return "pdfork";
    }
    function signal_syscall(s_thread td, uint16 number, string[] args) internal {
        td.do_syscall(number, args);
    }
/*
struct siginfo {
	uint8 si_signo;	 // signal number
	uint8 si_errno;	 // errno association
	uint8 si_code;	 // signal code
	uint16 si_pid;	 // sending process
	uint16 si_uid;	 // sender's ruid
	uint8 si_status; // exit value
	uint32 si_addr;	 // faulting instruction
	uint32 si_value; // signal value
	uint32 trapno;  // machine specific trap code
}*/

    function pgfind(uint16) internal returns (s_pgrp) {}            // Find process group by id.
    function pfind(uint16) internal returns (s_proc) {}             // Find process by id.

    function do_syscall(s_thread td, uint16 number, string[] args) internal {
        uint16 rv;
        uint8 ec;
        if (!args.empty()) {
        }
//        s_dirent[] dirents;
//        s_of[] fdt_in = td.td_proc.p_fd.fdt_ofiles;
//        s_of[] fdt;
//        uint len = fdt_in.length;
//        uint n_args = args.length;
//        string sarg1 = n_args > 0 ? args[0] : "";
//        string sarg2 = n_args > 1 ? args[1] : "";
//        uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
//        uint16 arg2 = n_args > 1 ? str.toi(sarg2) : 0;
        if (number == SYS_exit) {
//            rv = libstat.st_ino(td.td_proc.p_pd.pwd_cdir.attr);
            if (rv > 0)
                ec == 0;
        } else if (number == SYS_fork) {
        } else
            ec = ENOSYS;
        td.td_errno = ec;
        td.td_retval = rv;
    }

}