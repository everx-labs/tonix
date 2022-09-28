pragma ton-solidity >= 0.64.0;
import "uio_h.sol";

//#define	KTR_VERSION	2
//#define	KTR_PARMS	6

struct ktr_entry {
    uint32 ktr_timestamp;
    uint8 ktr_cpu;
    uint8 ktr_line;
    string ktr_file;
    string ktr_desc;
    uint16 ktr_thread;   // s_thread
    uint32[6] ktr_parms; // [KTR_PARMS]
}

// ktrace record header
 struct ktr_header_v0 {
    uint8 ktr_len;   // length of buf
    uint8 ktr_type;  // trace record type
    uint16 ktr_pid;  // process id
    string ktr_comm; // [MAXCOMLEN + 1]; command name
    uint32 ktr_time; // timestamp
    uint16 ktr_tid;  // was ktr_buffer
}

struct ktr_header {
    uint8 ktr_len;      // length of buf
    uint8 ktr_type;     // trace record type
    uint8 ktr_version;  // ktr_header version
    uint16 ktr_pid;     // process id
    string ktr_comm;    // [MAXCOMLEN + 1];/* command name
    uint32 ktr_time;    // timestamp
    uint16 ktr_tid;     // thread id
    uint8 ktr_cpu;      // cpu id
}

struct ktr_syscall {
    uint16 ktr_code;    // syscall number
    uint8 ktr_narg;     // number of arguments
    uint16[1] ktr_args; // followed by ktr_narg register_t
}

struct ktr_sysret {
    uint8 ktr_code;
    uint8 ktr_eosys;
    uint8 ktr_error;
    uint32 ktr_retval;
}

struct ktr_genio {
    uint8 ktr_fd;
    uio_rwo ktr_rw; // followed by data successfully read/written
}

struct ktr_psig {
    uint8 signo;
    uint8 action;
    uint8 code;
    uint32 mask;
}

struct ktr_csw {
    uint8 out;	 // 1 if switch out, 0 if switch in
    uint8 user;	 // 1 if usermode (ivcsw), 0 if kernel (vcsw)
    string wmesg;//[8];
}

struct ktr_proc_ctor {
	uint16 sv_flags; //struct sysentvec sv_flags copy
}
enum ktr_cap_fail_type {
    CAPFAIL_NOTCAPABLE,	// insufficient capabilities in cap_check()
    CAPFAIL_INCREASE,   // attempt to increase capabilities
    CAPFAIL_SYSCALL,    // disallowed system call
    CAPFAIL_LOOKUP      // disallowed VFS lookup
}
struct ktr_cap_fail {
    ktr_cap_fail_type cap_type;
    uint64 cap_needed;
    uint64 cap_held;
}

struct ktr_fault {
    uint32 vaddr;
    uint8 ktype;
}

struct ktr_faultend {
    uint32 result;
}

struct ktr_struct_array {
    uint32 struct_size; // Followed by null-terminated structure name and then payload contents.
}
