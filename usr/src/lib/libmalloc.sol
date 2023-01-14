pragma ton-solidity >= 0.64.0;
import "malloc_h.sol";
library libmalloc {
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

    uint8 constant M_VERSION = 1;

//    uint8 constant M_KOBJ = 1;
//    uint8 constant M_BUS = 2;
//    uint8 constant M_IOV = 3;

//    uint8 constant KOBJ_OPS = 1;

    uint16 constant CELL_BYTE_SIZE = 127;
    uint16 constant CELL_BIT_SIZE = 1023;

//    function _sizeof(uint8 t) internal returns (uint32) {
//        if (t == KOBJ_OPS) return uint32(CELL_BIT_SIZE) * 2 + 32;
//    }

//    function kmem_zalloc(uint32 size, uint16 flags) internal returns (uint32 p) {
////	    uint32 p = Malloc(size, __FILE__, __LINE__);
//        p = Malloc(size, "libmalloc", 41);
//	    if (p == 0 && (flags & M_WAITOK) > 0) {
////		    panic("Could not malloc %zd bytes with M_WAITOK from %s line %d",size, __FILE__, __LINE__);
//        }
//    }

//    function Free(uint32 p, string file, uint16 line) internal {
//
//    }
//    function Malloc(uint32 nbytes, string file, uint16 line) internal returns (uint32) {
//    }
//
//    function free(uint32 addr, uint8 mtype) internal {
//        if (mtype <= M_KOBJ)
//            addr = 0;
//    }
//    function zfree(uint32 addr, uint8 mtype) internal {
//        if (mtype <= M_KOBJ)
//            addr = 0;
//    }
//    function malloc(uint32 size, uint8 mtype, uint16 flags) internal returns (uint32) {
//        if (mtype > M_KOBJ)
//            return 0;
//        if ((flags & M_NOWAIT) > 0)
//            return 0;
//        if (size > CELL_BIT_SIZE)
//            return 0;
//        return 1;
//    }

}