pragma ton-solidity >= 0.64.0;
import "ktr_h.sol";
library libktrace {

// operations to ktrace system call  (KTROP(op))
    uint8 constant  KTROP_SET	=	0;	// set trace points
    uint8 constant  KTROP_CLEAR	=	1;	// clear trace points
    uint8 constant  KTROP_CLEARFILE	=2;	// stop all tracing to file
//#define	KTROP(o)		((o)&3)	// macro to extract operation
// flags (ORed in with operation)
    uint8 constant   KTRFLAG_DESCEND		= 4;	// perform op on all children too

    uint8 constant  KTR_VERSION0	= 0;
    uint8 constant  KTR_VERSION1	= 1;
//    uint8 constant  KTR_OFFSET_V0	= sizeof(struct ktr_header_v0) - sizeof(struct ktr_header)
//  KTRCHECK() just checks that the type is enabled and is only for internal use in the ktrace subsystem.  KTRPOINT() checks against
//  ktrace recursion as well as checking that the type is enabled and is the public interface.
//#define	KTRCHECK(td, type)	((td)->td_proc->p_traceflag & (1 << type))
//#define KTRPOINT(td, type)  (__predict_false(KTRCHECK((td), (type))))
//#define	KTRCHECKDRAIN(td)	(!(STAILQ_EMPTY(&(td)->td_proc->p_ktr)))
//#define	KTRUSERRET(td) do {						\
//	if (__predict_false(KTRCHECKDRAIN(td)))				\
//		ktruserret(td);						\
//} while (0)


    // ktrace record types
    uint8 constant KTR_SYSCALL	= 1;        // system call record
    uint8 constant KTR_SYSRET	= 2;        // return from system call record
    uint8 constant KTR_NAMEI	= 3;        // record contains pathname
    uint8 constant KTR_GENIO	= 4;        // trace generic process i/o
    uint8 constant KTR_PSIG	    = 5;        // trace processed signal
    uint8 constant KTR_CSW	    = 6;        // trace context switches
    uint8 constant KTR_USER	    = 7;        // data coming from userland
    uint8 constant KTR_STRUCT	= 8;        // misc. structs
    uint8 constant KTR_SYSCTL	= 9;        // name of a sysctl MIB
    uint8 constant KTR_PROCCTOR	= 10;       // trace process creation (multiple ABI support)
    uint8 constant KTR_PROCDTOR	= 11;       // trace process destruction (multiple ABI support)
    uint8 constant KTR_CAPFAIL	= 12;       // trace capability check failures
    uint8 constant KTR_FAULT	= 13;       // page fault record
    uint8 constant KTR_FAULTEND	= 14;       // end of page fault record
    uint8 constant KTR_STRUCT_ARRAY = 15;   // array of misc. structs

    uint16 constant KTR_USER_MAXLEN =	2048;	// maximum length of passed data
    uint16 constant KTR_DROP =	0x8000;
    uint16 constant KTR_VERSIONED =	0x4000;
    uint16 constant KTR_TYPE =	(KTR_DROP | KTR_VERSIONED);
    uint32 constant KTRFAC_MASK =	0xffffff;
    uint16 constant KTRFAC_SYSCALL =     uint16(1) << KTR_SYSCALL;
    uint16 constant KTRFAC_SYSRET =	     uint16(1) << KTR_SYSRET;
    uint16 constant KTRFAC_NAMEI =	     uint16(1) << KTR_NAMEI;
    uint16 constant KTRFAC_GENIO =	     uint16(1) << KTR_GENIO;
    uint16 constant KTRFAC_PSIG =	     uint16(1) << KTR_PSIG;
    uint16 constant KTRFAC_CSW =	     uint16(1) << KTR_CSW;
    uint16 constant KTRFAC_USER =	     uint16(1) << KTR_USER;
    uint16 constant KTRFAC_STRUCT =	     uint16(1) << KTR_STRUCT;
    uint16 constant KTRFAC_SYSCTL =	     uint16(1) << KTR_SYSCTL;
    uint16 constant KTRFAC_PROCCTOR =    uint16(1) << KTR_PROCCTOR;
    uint16 constant KTRFAC_PROCDTOR =    uint16(1) << KTR_PROCDTOR;
    uint16 constant KTRFAC_CAPFAIL =     uint16(1) << KTR_CAPFAIL;
    uint16 constant KTRFAC_FAULT =	     uint16(1) << KTR_FAULT;
    uint16 constant KTRFAC_FAULTEND =    uint16(1) << KTR_FAULTEND;
    uint16 constant KTRFAC_STRUCT_ARRAY= uint16(1) << KTR_STRUCT_ARRAY;

    // KTR trace classes
    // Two of the trace classes (KTR_DEV and KTR_SUBSYS) are special in that they are really placeholders so that indvidual drivers and subsystems
    // can map their internal tracing to the general class when they wish to have tracing enabled and map it to 0 when they don't.
    uint32 constant KTR_GEN     = 0x00000001;		// General (TR)
    uint32 constant KTR_NET     = 0x00000002;		// Network
    uint32 constant KTR_DEV     = 0x00000004;		// Device driver
    uint32 constant KTR_LOCK    = 0x00000008;		// MP locking
    uint32 constant KTR_SMP     = 0x00000010;		// MP general
    uint32 constant KTR_SUBSYS  = 0x00000020;		// Subsystem.
    uint32 constant KTR_PMAP    = 0x00000040;		// Pmap tracing
    uint32 constant KTR_MALLOC  = 0x00000080;		// Malloc tracing
    uint32 constant KTR_TRAP    = 0x00000100;		// Trap processing
    uint32 constant KTR_INTR    = 0x00000200;		// Interrupt tracing
    uint32 constant KTR_SIG     = 0x00000400;		// Signal processing
    uint32 constant KTR_SPARE2  = 0x00000800;		// cxgb, amd64, xen, clk, &c
    uint32 constant KTR_PROC    = 0x00001000;		// Process scheduling
    uint32 constant KTR_SYSC    = 0x00002000;		// System call
    uint32 constant KTR_INIT    = 0x00004000;		// System initialization
    uint32 constant KTR_SPARE3  = 0x00008000;		// cxgb, drm2, ioat, ntb
    uint32 constant KTR_SPARE4  = 0x00010000;
    uint32 constant KTR_EVH     = 0x00020000;		// Eventhandler
    uint32 constant KTR_VFS     = 0x00040000;		// VFS events
    uint32 constant KTR_VOP     = 0x00080000;		// Auto-generated vop events
    uint32 constant KTR_VM      = 0x00100000;		// The virtual memory system
    uint32 constant KTR_INET    = 0x00200000;		// IPv4 stack
    uint32 constant KTR_RUNQ    = 0x00400000;		// Run queue
    uint32 constant KTR_SPARE5	= 0x00800000;
    uint32 constant KTR_UMA		= 0x01000000;		// UMA slab allocator
    uint32 constant KTR_CALLOUT	= 0x02000000;		// Callouts and timeouts
    uint32 constant KTR_GEOM	= 0x04000000;		// GEOM I/O events
    uint32 constant KTR_BUSDMA	= 0x08000000;		// busdma(9) events
    uint32 constant KTR_INET6	= 0x10000000;		// IPv6 stack
    uint32 constant KTR_SCHED	= 0x20000000;		// Machine parsed sched info.
    uint32 constant KTR_BUF		= 0x40000000;		// Buffer cache
    uint32 constant KTR_PTRACE	= 0x80000000;		// Process debugging.
    uint32 constant KTR_ALL		= 0xffffffff;

    uint32 constant KTR_COMPILE = KTR_ALL;

    // trace flags (also in p_traceflags)
    uint32 constant KTRFAC_ROOT =	0x80000000;	// root set this trace
    uint32 constant KTRFAC_INHERIT =0x40000000;	// pass trace flags to children
    uint32 constant KTRFAC_DROP =	0x20000000;	// last event was dropped

}