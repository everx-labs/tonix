pragma ton-solidity >= 0.63.0;
enum sysinit_sub_id {
    SI_SUB_DUMMY,                     // not executed; for linker
    SI_SUB_DONE,                      // processed
    SI_SUB_TUNABLES,                  // establish tunable values
    SI_SUB_COPYRIGHT                  // first use of console
    SI_SUB_VM,          	          // virtual memory system init
    SI_SUB_COUNTER,                   // counter(9) is initialized
    SI_SUB_KMEM,                      // kernel memory
    SI_SUB_HYPERVISOR,                // Hypervisor detection and virtualization support  setup
    SI_SUB_WITNESS,                   // witness initialization
    SI_SUB_MTX_POOL_DYNAMIC,          // dynamic mutex pool
    SI_SUB_LOCK,                      // various locks
    SI_SUB_EVENTHANDLER,              // eventhandler init
    SI_SUB_VNET_PRELINK,              // vnet init before modules
    SI_SUB_KLD,         	          // KLD and module setup
    SI_SUB_KHELP,                     // khelp modules
    SI_SUB_CPU,         	          // CPU resources
    SI_SUB_RACCT,                     // resource accounting
    SI_SUB_KDTRACE,                   // Kernel dtrace hooks
    SI_SUB_RANDOM,                    // random number generator
    SI_SUB_MAC,         	          // TrustedBSD MAC subsystem
    SI_SUB_MAC_POLICY,                // TrustedBSD MAC policies
    SI_SUB_MAC_LATE,                  // TrustedBSD MAC subsystem
    SI_SUB_VNET,                      // vnet 0
    SI_SUB_INTRINSIC,                 // proc 0
    SI_SUB_VM_CONF,                   // config VM, set limits
    SI_SUB_DDB_SERVICES,              // capture, scripting, etc.
    SI_SUB_RUN_QUEUE,                 // set up run queue
    SI_SUB_KTRACE,                    // ktrace
    SI_SUB_OPENSOLARIS,               // OpenSolaris compatibility
    SI_SUB_AUDIT,                     // audit
    SI_SUB_CREATE_INIT,               // create init process
    SI_SUB_SCHED_IDLE,                // required idle procs
    SI_SUB_MBUF,                      // mbuf subsystem
    SI_SUB_INTR,                      // interrupt threads
    SI_SUB_TASKQ,                     // task queues
    SI_SUB_EPOCH,                     // epoch subsystem
    SI_SUB_SMP,         	          // start the APs
    SI_SUB_SOFTINTR,                  // start soft interrupt thread
    SI_SUB_DEVFS,                     // devfs ready for devices
    SI_SUB_INIT_IF,                   // prep for net interfaces
    SI_SUB_NETGRAPH,                  // Let Netgraph initialize
    SI_SUB_DTRACE,                    // DTrace subsystem
    SI_SUB_DTRACE_PROVIDER,           // DTrace providers
    SI_SUB_DTRACE_ANON,               // DTrace anon enabling
    SI_SUB_DRIVERS,                   // Let Drivers initialize
    SI_SUB_CONFIGURE,                 // Configure devices
    SI_SUB_VFS,                       // virtual filesystem
    SI_SUB_CLOCKS,                    // real time and stat clocks
    SI_SUB_SYSV_SHM,                  // System V shared memory
    SI_SUB_SYSV_SEM,                  // System V semaphores
    SI_SUB_SYSV_MSG,                  // System V message queues
    SI_SUB_P1003_1B,                  // P1003.1B realtime
    SI_SUB_PSEUDO,                    // pseudo devices
    SI_SUB_EXEC,                      // execve() handlers
    SI_SUB_PROTO_BEGIN,               // VNET initialization
    SI_SUB_PROTO_PFIL,                // Initialize pfil before FWs
    SI_SUB_PROTO_IF,                  // interfaces
    SI_SUB_PROTO_DOMAININIT,          // domain registration system
    SI_SUB_PROTO_MC,                  // Multicast
    SI_SUB_PROTO_DOMAIN,              // domains (address families?)
    SI_SUB_PROTO_FIREWALL,            // Firewalls
    SI_SUB_PROTO_IFATTACHDOMAIN,      // domain dependent data init
    SI_SUB_PROTO_END,                 // VNET helper functions
    SI_SUB_KPROF,           	      // kernel profiling
    SI_SUB_KICK_SCHEDULER,            // start the timeout events
    SI_SUB_INT_CONFIG_HOOKS,          // Interrupts enabled config
    SI_SUB_ROOT_CONF,                 // Find root devices
    SI_SUB_INTRINSIC_POST,            // proc 0 cleanup
    SI_SUB_SYSCALLS,                  // register system calls
    SI_SUB_VNET_DONE,                 // vnet registration complete
    SI_SUB_KTHREAD_INIT,              // init process
    SI_SUB_KTHREAD_PAGE,              // pageout daemon
    SI_SUB_KTHREAD_VM,                // vm daemon
    SI_SUB_KTHREAD_BUF,               // buffer daemon
    SI_SUB_KTHREAD_UPDATE,            // update daemon
    SI_SUB_KTHREAD_IDLE,              // idle procs
    SI_SUB_SMP,                       // start the APs
    SI_SUB_RACCTD,          	      // start racctd
    SI_SUB_LAST	                      // final initialization
}

// Some enumerated orders; "ANY" sorts last.
enum sysinit_elem_order {
    SI_ORDER_FIRST,	    // first
    SI_ORDER_SECOND,    // second
    SI_ORDER_THIRD,	    // third
    SI_ORDER_FOURTH,    // fourth
    SI_ORDER_FIFTH,	    // fifth
    SI_ORDER_SIXTH,	    // sixth
    SI_ORDER_SEVENTH,   // seventh
    SI_ORDER_EIGHTH,    // eighth
    SI_ORDER_MIDDLE,    // somewhere in the middle
    SI_ORDER_ANY        // last
}

 // A system initialization call instance
 // At the moment there is one instance of sysinit.  We probably do not want two which is why this code is if'd out, but we definitely want
 // to discern SYSINIT's which take non-constant data pointers and SYSINIT's which take constant data pointers,
 // The C_* macros take functions expecting const void * arguments while the non-C_* macros take functions expecting just void * arguments.
 // With -Wcast-qual on, the compiler issues warnings:
 //	- if we pass non-const data or functions taking non-const data to a C_* macro.
 //	- if we pass const data to the normal macros
 // However, no warning is issued if we pass a function taking const data through a normal non-const macro.  This is ok because the function is
 // saying it won't modify the data so we don't care whether the data is modifiable or not.


//typedef void (*sysinit_nfunc_t)(void *);
//typedef void (*sysinit_cfunc_t)(const void *);

struct sysinit {
    sysinit_sub_id	subsystem;	// subsystem identifier
    sysinit_elem_order	order;	// init order within subsystem
    sysinit_cfunc_t func;		// function
    TvmCell udata;			   // multiplexer/argument
}

// Default: no special processing
// The C_ version of SYSINIT is for data pointers to const data ( and functions taking data pointers to const data ).
// At the moment it is no different from SYSINIT and thus still results in warnings.
// The casts are necessary to have the compiler produce the correct warnings when -Wcast-qual is used.
struct sysinit_tslog {
    sysinit_cfunc_t func;
    TvmCell data;
    string name;
}
sysinit_tslog_shim(TvmCell data) {
    s_sysinit_tslog x = data;
    TSRAW(curthread, TS_ENTER, "SYSINIT", x.name);
    x.func(x.data);
    TSRAW(curthread, TS_EXIT, "SYSINIT", x.name);
}
C_SYSINIT(uniquifier, subsystem, order, func, ident)
struct sysinit_tslog uniquifier_sys_init_tslog = {
        func,
        (ident),
        #uniquifier
}
struct sysinit uniquifier_sys_init = {
        subsystem,
        order,
        sysinit_tslog_shim,
        &uniquifier ## _sys_init_tslog
    };
    DATA_WSET(sysinit_set,uniquifier ## _sys_init)
C_SYSINIT(uniquifier, subsystem, order, func, ident) {
    struct sysinit uniquifier_sys_init {
    	subsystem,
    	order,
    	func,
    	(ident)
	}

SYSINIT(uniquifier, subsystem, order, func, ident)
    C_SYSINIT(uniquifier, subsystem, order,
    (sysinit_cfunc_t)(sysinit_nfunc_t)func, (void *)(ident))

oid sysinit_add(sysinit[] set, sysinit[] set_end);

// Infrastructure for tunable 'constants'.  Value may be specified at compile time or kernel load time.  Rules relating tunables together can be placed
// in a SYSINIT function at SI_SUB_TUNABLES with SI_ORDER_ANY.
// WARNING: developers should never use the reserved suffixes specified in loader.conf(5) for any tunables or conflicts will result.
extern void tunable_uint_init(TvmCell);
struct tunable_uint {
    string path;
    uint vvar;
}
struct tunable_uint64 {
    string path;
    uint64 vvar;
}
extern void tunable_bool_init(TvmCell);
struct tunable_bool {
    string path;
    bool vvar;
}
TUNABLE_BOOL(path, var)
TUNABLE_BOOL_FETCH(path, var)	getenv_bool((path), (var))

tunable_str_init(void *);
struct tunable_str {
    string path;
    string svar;
    uint8 size;
}
//#define	TUNABLE_STR_FETCH(path, var, size)	getenv_string((path), (var), (size))
//typedef void (*ich_func_t)(void *_arg);

/*struct intr_config_hook {
    STAILQ_ENTRY(intr_config_hook) ich_links;
    uintptr_t	ich_state;
// #define ICHS_QUEUED	0x1
// #define ICHS_RUNNING	0x2
// #define	ICHS_DONE	0x3
    ich_func_t	ich_func;
    void		*ich_arg;
};

int	config_intrhook_establish(struct intr_config_hook *hook);
void	config_intrhook_disestablish(struct intr_config_hook *hook);
int	config_intrhook_drain(struct intr_config_hook *hook);
void	config_intrhook_oneshot(ich_func_t _func, void *_arg);
*/
