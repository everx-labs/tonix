pragma ton-solidity >= 0.62.0;

import "proc_h.sol";

library libproc {

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
    uint32 constant P_STOPPED = P_STOPPED_SIG | P_STOPPED_SINGLE | P_STOPPED_TRACE;

}