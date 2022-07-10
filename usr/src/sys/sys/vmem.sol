pragma ton-solidity >= 0.58.0;

struct s_qcache {
    uint16 qc_cache;
    uint16 qc_vmem;
    uint32 qc_size;
    string qc_name; //[QC_NAME_MAX];
}

struct s_vmem_btag {
    uint32 bt_start;
    uint32 bt_size;
    uint8  bt_type;
}

struct s_vmem {
    string vm_name; // [VMEM_NAME_MAX+1];
    uint32 vm_qcache_max;
    uint32 vm_quantum_mask;
    uint32 vm_import_quantum;
    uint8  vm_quantum_shift;
    uint32 vm_inuse;
    uint32 vm_size;
    uint32 vm_limit;
    s_vmem_btag vm_cursor;
    bytes[] vm_pages;
}

struct s_vmem_org {
    string vm_name; // [VMEM_NAME_MAX+1];
    s_vmem_btag[16] vm_hash0; // VMEM_HASHSIZE_MIN
    s_vmem_btag[44] vm_freelist; // VMEM_MAXORDER
    s_vmem_btag[] vm_seglist;
    s_vmem_btag[] m_hashlist;
    uint32 vm_hashsize;
    uint32 vm_qcache_max;
    uint32 vm_quantum_mask;
    uint32 vm_import_quantum;
    uint8  vm_quantum_shift;
    s_vmem_btag[] vm_freetags;
    uint8 vm_nfreetags;
    uint8 vm_nbusytag;
    uint32 vm_inuse;
    uint32 vm_size;
    uint32 vm_limit;
    s_vmem_btag vm_cursor;
    s_qcache[16] vm_qcache; // VMEM_QCACHE_IDX_MAX
}

struct s_xswdev {
    uint16 xsw_version;
    uint16 xsw_dev;
    uint16 xsw_flags;
    uint16 xsw_nblks;
    uint16 xsw_used;
}

library vmem {
    uint16 constant M_NOWAIT      = 0x0001; // do not block
    uint16 constant M_WAITOK      = 0x0002; // ok to block
    uint16 constant M_NORECLAIM   = 0x0080; // do not reclaim after failure
    uint16 constant M_ZERO        = 0x0100; // bzero the allocation
    uint16 constant M_NOVM        = 0x0200; // don't ask VM for pages
    uint16 constant M_USE_RESERVE = 0x0400; // can alloc out of reserve memory
    uint16 constant M_NODUMP      = 0x0800; // don't dump pages in this allocation
    uint16 constant M_FIRSTFIT    = 0x1000; // only for vmem, fast fit
    uint16 constant M_BESTFIT     = 0x2000; // only for vmem, low fragmentation
    uint16 constant M_EXEC        = 0x4000; // allocate executable space
    uint16 constant M_NEXTFIT     = 0x8000; // only for vmem, follow cursor

    uint8 constant VMEM_NAME_MAX =  16;
    uint8 constant BT_MAXALLOC =    4;
    uint8 constant BT_MAXFREE = (BT_MAXALLOC * 8);
    uint8 constant VMEM_OPTORDER =  5;
    uint8 constant VMEM_OPTVALUE =  uint8(1) << VMEM_OPTORDER;
    uint8 constant VMEM_MAXORDER = VMEM_OPTVALUE - 1 + 2 * 8 - VMEM_OPTORDER;
    uint8 constant VMEM_HASHSIZE_MIN =  16;
    uint32 constant VMEM_HASHSIZE_MAX = 131072;
    uint8 constant VMEM_QCACHE_IDX_MAX = 16;
    uint16 constant VMEM_FITMASK = M_BESTFIT | M_FIRSTFIT | M_NEXTFIT;
    uint16 constant VMEM_FLAGS   = M_NOWAIT | M_WAITOK | M_USE_RESERVE | M_NOVM | M_BESTFIT | M_FIRSTFIT | M_NEXTFIT;
    uint16 constant BT_FLAGS     = M_NOWAIT | M_WAITOK | M_USE_RESERVE | M_NOVM;
    uint8 constant QC_NAME_MAX    = 16;
    uint8 constant VMEM_ADDR_MIN         =  0;
    uint8 constant VMEM_ADDR_QCACHE_MIN  =  1;
    uint8 constant VMEM_ALLOC           = 0x01;
    uint8 constant VMEM_FREE            = 0x02;
    uint8 constant VMEM_MAXFREE         = 0x10;
    uint8 constant BT_TYPE_SPAN         = 1; // Allocated from importfn
    uint8 constant BT_TYPE_SPAN_STATIC  = 2; // vmem_add() or create.
    uint8 constant BT_TYPE_FREE         = 3; // Available space.
    uint8 constant BT_TYPE_BUSY         = 4; // Used space.
    uint8 constant BT_TYPE_CURSOR       = 5; // Cursor for nextfit allocations.

    uint8 constant VM_TOTAL               = 1;  // struct vmtotal
    uint8 constant VM_METER        = VM_TOTAL;  // deprecated, use VM_TOTAL
    uint8 constant VM_LOADAVG             = 2;  // struct loadavg
    uint8 constant VM_V_FREE_MIN          = 3;  // vm_cnt.v_free_min
    uint8 constant VM_V_FREE_TARGET       = 4;  // vm_cnt.v_free_target
    uint8 constant VM_V_FREE_RESERVED     = 5;  // vm_cnt.v_free_reserved
    uint8 constant VM_V_INACTIVE_TARGET   = 6;  // vm_cnt.v_inactive_target
    uint8 constant VM_OBSOLETE_7          = 7;  // unused, formerly v_cache_min
    uint8 constant VM_OBSOLETE_8          = 8;  // unused, formerly v_cache_max
    uint8 constant VM_V_PAGEOUT_FREE_MIN  = 9;  // vm_cnt.v_pageout_free_min
    uint8 constant VM_OBSOLETE_10         = 10; // pageout algorithm
    uint8 constant VM_SWAPPING_ENABLED    = 11; // swapping enabled
    uint8 constant VM_OVERCOMMIT          = 12; // vm.overcommit
    uint8 constant VM_MAXID               = 13; // number of valid vm ids

    uint8 constant KERN_SUCCESS            = 0;
    uint8 constant KERN_INVALID_ADDRESS    = 1;
    uint8 constant KERN_PROTECTION_FAILURE = 2;
    uint8 constant KERN_NO_SPACE           = 3;
    uint8 constant KERN_INVALID_ARGUMENT   = 4;
    uint8 constant KERN_FAILURE            = 5;
    uint8 constant KERN_RESOURCE_SHORTAGE  = 6;
    uint8 constant KERN_NOT_RECEIVER       = 7;
    uint8 constant KERN_NO_ACCESS          = 8;
    uint8 constant KERN_OUT_OF_BOUNDS      = 9;
    uint8 constant KERN_RESTART            = 10;

    uint8 constant VM_PHYSSEG_MAX       = 17;
    uint8 constant KSTACK_MAX_PAGES     = 32;
    uint8 constant PHYS_AVAIL_ENTRIES   = VM_PHYSSEG_MAX * 2;
    uint8 constant PHYS_AVAIL_COUNT     = PHYS_AVAIL_ENTRIES + 2;
    uint8 constant XSWDEV_VERSION       = 2;

    function vmem_create(string name, uint32 base, uint16 size, uint16 quantum, uint16 qcache_max, uint16 flags) internal returns (s_vmem vm) {
        vm.vm_name = name;
        vm.vm_cursor = s_vmem_btag(base, size, BT_TYPE_CURSOR);
        vm.vm_size = quantum;//size;
        vm.vm_qcache_max = qcache_max;
        vm.vm_quantum_mask = flags;
        vm.vm_import_quantum = quantum;
    }
    /*string vm_name; // [VMEM_NAME_MAX+1];
    s_vmem_btag[16] vm_hash0; // VMEM_HASHSIZE_MIN
    s_vmem_btag[44] vm_freelist; // VMEM_MAXORDER
    s_vmem_btag[] vm_seglist;
    s_vmem_btag[] m_hashlist;
    uint32 vm_hashsize;
    uint32 vm_qcache_max;
    uint32 vm_quantum_mask;
    uint32 vm_import_quantum;
    uint8  vm_quantum_shift;
    s_vmem_btag[] vm_freetags;
    uint8 vm_nfreetags;
    uint8 vm_nbusytag;
    uint32 vm_inuse;
    uint32 vm_size;
    uint32 vm_limit;
    s_vmem_btag vm_cursor;
    s_qcache[16] vm_qcache; */
    function vmem_init(s_vmem vm, string name, uint32 base, uint16 size, uint16 quantum, uint16 qcache_max, uint16 flags) internal returns (s_vmem) {}
    function vmem_destroy(s_vmem ) internal {}
    function vmem_alloc(s_vmem vm, uint16 size, uint16 /*flags*/) internal returns (uint8, uint32 addrp) {
        bytes b;
        vm.vm_pages.push(b);
        vm.vm_inuse += size;
        addrp = vm.vm_inuse;
    }
    function vmem_free(s_vmem vm, uint32 addr, uint16 size) internal {}
    function vmem_xalloc(s_vmem vm, uint16 size, uint16 align, uint16 phase, uint16 nocross, uint32 minaddr, uint32 maxaddr, uint16 flags, uint32 addrp) internal returns (int) {}
    function vmem_xfree(s_vmem vm, uint32 addr, uint16 size) internal {}
    function vmem_add(s_vmem vm, uint32 addr, uint16 size, uint16 flags) internal returns (uint16) {}
    function vmem_roundup_size(s_vmem vm, uint16 size) internal returns (uint16) {}
    function vmem_size(s_vmem vm, uint16 typemask) internal returns (uint16) {}
    function vmem_whatis(uint32 addr, string ) internal {}
    function vmem_print(uint32 addr, string , string ) internal {}
    function vmem_printall(string , string ) internal {}
    function vmem_startup() internal {}
    function vmem_fetch_page(s_vmem vm, uint16 idx) internal returns (string) {
        return idx < vm.vm_pages.length ? vm.vm_pages[idx] : "Page fault";
    }
}