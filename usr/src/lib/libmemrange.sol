pragma ton-solidity >= 0.64.0;

struct s_mem_range_ops {
	uint32 init; // (s_mem_range_softc sc);
	uint32 set; // (s_mem_range_softc sc, s_mem_range_desc mrd, uint32 arg) returns uint8;
    uint32 initAP; // (s_mem_range_softc sc);
    uint32 reinit; // (s_mem_range_softc sc);
}
struct mem_range_softc {
    s_mem_range_ops	mr_op;
    uint8 mr_cap;
    uint8 mr_ndesc;
    s_mem_range_desc mr_desc;
}

struct s_mem_region {
    uint32 mr_start;
    uint32 mr_size;
}
struct s_mem_range_desc {
    uint32 mr_base;
    uint32 mr_len;
    uint32 mr_flags;
    string mr_owner; // [8]
}
struct mem_range_op {
    s_mem_range_desc mo_desc;
    uint32[2] mo_arg;
    // XXX want a flag that says "set and undo when I exit"
}
struct mem_extract {
    uint32 me_vaddr;
    uint32 me_paddr;
    uint8 me_domain;
    uint8 me_state;
}
struct mem_livedump_arg {
    uint8 fd;
    uint32 flags;
    uint8 compression;
}
library libmemrange {
/* Memory range attributes */
    uint32 constant MDF_UNCACHEABLE	=	(1<<0)	; // region not cached
    uint32 constant MDF_WRITECOMBINE	=(1<<1)	; // region supports "write combine" action
    uint32 constant MDF_WRITETHROUGH	=(1<<2)	; // write-through cached
    uint32 constant MDF_WRITEBACK	=	(1<<3)	; // write-back cached
    uint32 constant MDF_WRITEPROTECT	=(1<<4)	; // read-only region
    uint32 constant MDF_UNKNOWN	=	(1<<5)	    ; // any state we don't understand
    uint32 constant MDF_ATTRMASK	=	(0x00ffffff);
    uint32 constant MDF_FIXBASE	=	(1<<24); // fixed base
    uint32 constant MDF_FIXLEN	=	(1<<25); // fixed length
    uint32 constant MDF_FIRMWARE=	(1<<26); // set by firmware (XXX not useful?)
    uint32 constant MDF_ACTIVE	=	(1<<27); // currently active
    uint32 constant MDF_BOGUS	=	(1<<28); // we don't like it
    uint32 constant MDF_FIXACTIVE=	(1<<29); // can't be turned off
    uint32 constant MDF_BUSY	=	(1<<30); // range is in use
    uint32 constant MDF_FORCE	=	(1<<31); // force risky changes

    uint8 constant MEMRANGE_SET_UPDATE	= 0;
    uint8 constant MEMRANGE_SET_REMOVE	= 1;
    uint8 constant ME_STATE_INVALID	= 0;
    uint8 constant ME_STATE_VALID		= 1;
    uint8 constant ME_STATE_MAPPED		= 2;
//#define MEMRANGE_GET	_IOWR('m', 50, struct mem_range_op)
//#define MEMRANGE_SET	_IOW('m', 51, struct mem_range_op)
//#define	MEM_EXTRACT_PADDR	_IOWR('m', 52, struct mem_extract)
//#define	MEM_KERNELDUMP	_IOW('m', 53, struct mem_livedump_arg)

//MALLOC_DECLARE(M_MEMDESC);

//extern struct mem_range_softc mem_range_softc;

    function mem_range_init() internal {}
    function mem_range_destroy() internal {}
    function mem_range_attr_get(s_mem_range_desc mrd, uint32 arg) internal returns (uint8) {}
    function mem_range_attr_set(s_mem_range_desc mrd, uint32 arg) internal returns (uint8) {}

    uint8 constant EXFLAG_NODUMP	= 0x01;
    uint8 constant EXFLAG_NOALLOC	= 0x02;

    function physmem_hardware_region(uint32 pa, uint32 sz) internal {}
    function physmem_exclude_region(uint32 pa, uint32 sz, uint32 flags) internal {}
    function physmem_avail(uint32 avail, uint32 maxavail) internal returns (uint32) {}
    function physmem_init_kernel_globals() internal {}
    function physmem_print_tables() internal {}

    function physmem_hardware_regions(s_mem_region[] mrptr, uint8 mrcount) internal {
        while (mrcount-- > 0) {
            s_mem_region mr = mrptr[mrcount];
            physmem_hardware_region(mr.mr_start, mr.mr_size);
//          ++mrptr;
        }
    }

    function physmem_exclude_regions(s_mem_region[] mrptr, uint8 mrcount, uint32 exflags) internal {
    	while (mrcount-- > 0) {
            s_mem_region mr = mrptr[mrcount];
    		physmem_exclude_region(mr.mr_start, mr.mr_size, exflags);
//    		++mrptr;
    	}
    }

}