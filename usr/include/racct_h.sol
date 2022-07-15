pragma ton-solidity >= 0.62.0;

struct s_rlimit {
    uint32 rlim_cur; // current (soft) limit
    uint32 rlim_max; // maximum value for rlim_cur
}
struct s_plimit {
    s_rlimit[15] pl_rlimit; // RLIM_NLIMITS
    uint16 pl_refcnt;       // number of references
}

struct s_loginclass {
    string lc_name;
    uint16 lc_refcount;
    s_racct lc_racct;
}
struct s_racct {
    uint64[25] r_resources; // RACCT_MAX + 1
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

