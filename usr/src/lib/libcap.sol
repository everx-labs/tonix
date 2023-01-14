pragma ton-solidity >= 0.64.0;
import "ktr_h.sol";
import "filedesc_h.sol";
struct s_cap_rights {
//    uint64[CAP_RIGHTS_VERSION + 2] cr_rights;
    uint64 cr_rights;
}

//enum ktr_cap_fail_type {
//    CAPFAIL_NOTCAPABLE,	// insufficient capabilities in cap_check()
//    CAPFAIL_INCREASE,	// attempt to increase capabilities
//    CAPFAIL_SYSCALL,	// disallowed system call
//    CAPFAIL_LOOKUP		// disallowed VFS lookup
//}

library libcap {
    using libcap for uint64;
    uint8 constant ENOTCAPABLE  = 93; // Capabilities insufficient

    // General file I/O.
    uint64 constant CAP_READ      = 1 << 0; // Allows for openat(O_RDONLY), read(2), readv(2)
    uint64 constant CAP_WRITE     = 1 << 1; // Allows for openat(O_WRONLY | O_APPEND), write(2), writev(2)
    uint64 constant CAP_SEEK_TELL = 1 << 2; // Allows for lseek(fd, 0, SEEK_CUR)
    uint64 constant CAP_SEEK      = 1 << 3; // Allows for lseek(2)
    uint64 constant CAP_PREAD     = CAP_SEEK | CAP_READ; // Allows for aio_read(2), pread(2), preadv(2)
    uint64 constant CAP_PWRITE    = CAP_SEEK | CAP_WRITE; // Allows for aio_write(2), openat(O_WRONLY) (without O_APPEND), pwrite(2), pwritev(2)
    uint64 constant CAP_MMAP      = 1 << 4; // Allows for mmap(PROT_NONE)
    uint64 constant CAP_MMAP_R    = CAP_MMAP | CAP_SEEK | CAP_READ; // Allows for mmap(PROT_READ)
    uint64 constant CAP_MMAP_W    = CAP_MMAP | CAP_SEEK | CAP_WRITE; // Allows for mmap(PROT_WRITE)
    uint64 constant CAP_MMAP_X    = CAP_MMAP | CAP_SEEK | 1 << 5; // Allows for mmap(PROT_EXEC)
    uint64 constant CAP_MMAP_RW   = CAP_MMAP_R | CAP_MMAP_W; // Allows for mmap(PROT_READ | PROT_WRITE)
    uint64 constant CAP_MMAP_RX   = CAP_MMAP_R | CAP_MMAP_X; // Allows for mmap(PROT_READ | PROT_EXEC)
    uint64 constant CAP_MMAP_WX   = CAP_MMAP_W | CAP_MMAP_X; // Allows for mmap(PROT_WRITE | PROT_EXEC)
    uint64 constant CAP_MMAP_RWX  = CAP_MMAP_R | CAP_MMAP_W | CAP_MMAP_X; // Allows for mmap(PROT_READ | PROT_WRITE | PROT_EXEC)
    uint64 constant CAP_CREATE    = 1 << 6; // Allows for openat(O_CREAT)
    uint64 constant CAP_FEXECVE   = 1 << 7; // Allows for openat(O_EXEC) and fexecve(2) in turn
    uint64 constant CAP_FSYNC     = 1 << 8; // Allows for openat(O_SYNC), openat(O_FSYNC), fsync(2), aio_fsync(2)
    uint64 constant CAP_FTRUNCATE = 1 << 9; // Allows for openat(O_TRUNC), ftruncate(2)
    uint64 constant CAP_LOOKUP    = 1 << 10; // Lookups - used to constrain *at() calls

    // VFS methods.
    uint64 constant CAP_FCHDIR      = 1 << 11; // Allows for fchdir(2)
    uint64 constant CAP_FCHFLAGS    = 1 << 12; // Allows for fchflags(2)
    uint64 constant CAP_CHFLAGSAT   = CAP_FCHFLAGS | CAP_LOOKUP; // Allows for fchflags(2) and chflagsat(2)
    uint64 constant CAP_FCHMOD      = 1 << 13; // Allows for fchmod(2)
    uint64 constant CAP_FCHMODAT    = CAP_FCHMOD | CAP_LOOKUP; // Allows for fchmod(2) and fchmodat(2)
    uint64 constant CAP_FCHOWN      = 1 << 14;// Allows for fchown(2)
    uint64 constant CAP_FCHOWNAT    = CAP_FCHOWN | CAP_LOOKUP; // Allows for fchown(2) and fchownat(2)
    uint64 constant CAP_FCNTL       = 1 << 15; // Allows for fcntl(2)
    uint64 constant CAP_FLOCK       = 1 << 16; // Allows for flock(2), openat(O_SHLOCK), openat(O_EXLOCK),fcntl(F_SETLK_REMOTE), fcntl(F_SETLKW), fcntl(F_SETLK), fcntl(F_GETLK).
    uint64 constant CAP_FPATHCONF   = 1 << 17; // Allows for fpathconf(2)
    uint64 constant CAP_FSCK        = 1 << 18; // Allows for UFS background-fsck operations
    uint64 constant CAP_FSTAT       = 1 << 19;// Allows for fstat(2)
    uint64 constant CAP_FSTATAT     = CAP_FSTAT | CAP_LOOKUP; // Allows for fstat(2), fstatat(2) and faccessat(2)
    uint64 constant CAP_FSTATFS     = 1 << 20; // Allows for fstatfs(2)
    uint64 constant CAP_FUTIMES     = 1 << 21; // Allows for futimens(2) and futimes(2)
    uint64 constant CAP_FUTIMESAT   = CAP_FUTIMES | CAP_LOOKUP; // Allows for futimens(2), futimes(2), futimesat(2) and utimensat(2)
    uint64 constant CAP_LINKAT_TARGET = CAP_LOOKUP | 1 << 22; // Allows for linkat(2) (target directory descriptor)
    uint64 constant CAP_MKDIRAT     = CAP_LOOKUP | 1 << 23; // Allows for mkdirat(2) (CAP_LOOKUP | 0x0000000000800000ULL)
    uint64 constant CAP_MKFIFOAT    = CAP_LOOKUP | 1 << 24; // Allows for mkfifoat(2)
    uint64 constant CAP_MKNODAT     = CAP_LOOKUP | 1 << 25; // Allows for mknodat(2)
    uint64 constant CAP_RENAMEAT_SOURCE = CAP_LOOKUP | 1 << 26; // Allows for renameat(2) (source directory descriptor)
    uint64 constant CAP_SYMLINKAT   = CAP_LOOKUP | 1 << 27; // Allows for symlinkat(2)
    uint64 constant CAP_UNLINKAT    = CAP_LOOKUP | 1 << 28; // Allows for unlinkat(2) and renameat(2) if destination object exists and will be removed.

    // Socket operations.
    uint64 constant CAP_ACCEPT       = 1 << 26; // Allows for accept(2) and accept4(2)
    uint64 constant CAP_BIND         = 1 << 27; // Allows for bind(2)
    uint64 constant CAP_CONNECT      = 1 << 28; // Allows for connect(2)
    uint64 constant CAP_GETPEERNAME  = 1 << 29; // Allows for getpeername(2)
    uint64 constant CAP_GETSOCKNAME  = 1 << 30; // Allows for getsockname(2)
    uint64 constant CAP_GETSOCKOPT   = 1 << 31; // Allows for getsockopt(2)
    uint64 constant CAP_LISTEN       = 1 << 32; // Allows for listen(2)
    uint64 constant CAP_PEELOFF      = 1 << 33; // Allows for sctp_peeloff(2)
    uint64 constant CAP_RECV         = CAP_READ;
    uint64 constant CAP_SEND         = CAP_WRITE;
    uint64 constant CAP_SETSOCKOPT   = 1 << 34; // Allows for setsockopt(2)
    uint64 constant CAP_SHUTDOWN     = 1 << 35; // Allows for shutdown(2)

    uint64 constant CAP_BINDAT          = CAP_LOOKUP | 1 << 36; // Allows for bindat(2) on a directory descriptor
    uint64 constant CAP_CONNECTAT       = CAP_LOOKUP | 1 << 37; // Allows for connectat(2) on a directory descriptor
    uint64 constant CAP_LINKAT_SOURCE   = CAP_LOOKUP | 1 << 38; // Allows for linkat(2) (source directory descriptor)
    uint64 constant CAP_RENAMEAT_TARGET = CAP_LOOKUP | 1 << 39; // Allows for renameat(2) (target directory descriptor)      0x0000040000000000ULL)

    uint65 constant CAP_SOCK_CLIENT   = CAP_CONNECT | CAP_GETPEERNAME | CAP_GETSOCKNAME | CAP_GETSOCKOPT | CAP_PEELOFF | CAP_RECV | CAP_SEND | CAP_SETSOCKOPT | CAP_SHUTDOWN;
    uint65 constant CAP_SOCK_SERVER   = CAP_ACCEPT | CAP_BIND | CAP_GETPEERNAME | CAP_GETSOCKNAME | CAP_GETSOCKOPT | CAP_LISTEN | CAP_PEELOFF | CAP_RECV | CAP_SEND | CAP_SETSOCKOPT | CAP_SHUTDOWN;

    uint64 constant CAP_ALL0 = (1 << 40) - 1; // All used bits for index 0
    // Available bits for index 0
    uint64 constant CAP_UNUSED0_44 = 1 << 44;
    uint64 constant CAP_UNUSED0_57 = 1 << 57;

    // Allowed fcntl(2) commands.
    uint8 constant F_GETFL          = 3;
    uint8 constant F_SETFL          = 4;
    uint8 constant F_GETOWN         = 5;
    uint8 constant F_SETOWN         = 6;
    uint64 constant CAP_FCNTL_GETFL  = uint64(1) << F_GETFL;
    uint64 constant CAP_FCNTL_SETFL  = uint64(1) << F_SETFL;
    uint64 constant CAP_FCNTL_GETOWN = uint64(1) << F_GETOWN;
    uint64 constant CAP_FCNTL_SETOWN = uint64(1) << F_SETOWN;
    uint64 constant CAP_FCNTL_ALL    = CAP_FCNTL_GETFL | CAP_FCNTL_SETFL | CAP_FCNTL_GETOWN | CAP_FCNTL_SETOWN;
    uint64 constant CAP_IOCTLS_ALL   = SSIZE_MAX;
    uint64 constant SSIZE_MAX = 0xFFFFFFFFFFFFFFFF;

    uint8 constant CAP_RIGHTS_VERSION_00 = 0;
    uint8 constant CAP_RIGHTS_VERSION = CAP_RIGHTS_VERSION_00;
    uint8 constant CAPARSIZE_MIN = CAP_RIGHTS_VERSION_00 + 2;
    uint8 constant CAPARSIZE_MAX = CAP_RIGHTS_VERSION + 2;


    function CAP_ALL() internal returns (uint64) {
        return CAP_ALL0;
    }
    function right_to_index(uint64 right) internal returns (uint8 idx) {
//	    int8[] bit2idx = [-1, 0, 1, -1, 2, -1, -1, -1, 3, -1, -1, -1, -1, -1, -1, -1,
//	        4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
//    	idx = CAPIDXBIT(right);
//    	assert(idx >= 0 && idx < bit2idx.length);
//    	return bit2idx[idx];
    }

    function cap_rights_init_one(uint64 r, uint64 right) internal {
        r |= right;
    }

    function cap_write_rights(uint64 r) internal {
        r.cap_rights_init_one(CAP_WRITE);
    }

    function cap_rights_init(uint16 version, uint64 rights) internal returns (uint64) {}
    function cap_rights_set(uint64 rights) internal returns (uint64) {}
    function cap_rights_clear(uint64 rights) internal returns (uint64) {}
    function __cap_rights_is_set(uint64 rights) internal returns (bool) {}
    function cap_rights_is_valid(uint64 rights) internal returns (bool) {
//        uint j;
//        if (CAPVER(rights) != CAP_RIGHTS_VERSION_00)
//            return false;
//        if (CAPARSIZE(rights) < CAPARSIZE_MIN ||
//            CAPARSIZE(rights) > CAPARSIZE_MAX) {
//        	return false;
//        }
        uint64 allrights = CAP_ALL();
        if (!cap_rights_contains(allrights, rights))
            return false;
//        for (uint i = 0; i < CAPARSIZE(rights); i++) {
//            j = right_to_index(rights);
//            if (i != j)
//                return false;
//            if (i > 0) {
//                if (CAPRVER(rights.cr_rights[i]) != 0)
//                    return false;
//            }
//        }
        return true;
    }
    function cap_rights_merge(uint64 dst, uint64 src) internal returns (uint64) {
//        uint i;
//    	assert(CAPVER(dst) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(src) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(dst) == CAPVER(src));
//    	assert(cap_rights_is_valid(src));
//    	assert(cap_rights_is_valid(dst));
//    	uint n = CAPARSIZE(dst);
//    	assert(n >= CAPARSIZE_MIN && n <= CAPARSIZE_MAX);
//    	for (i = 0; i < n; i++)
//    		dst.cr_rights[i] |= src.cr_rights[i];
        dst |= src;
//    	assert(cap_rights_is_valid(src));
//    	assert(cap_rights_is_valid(dst));
        return dst;
    }
    function cap_rights_remove(uint64 dst, uint64 src) internal returns (uint64) {
//    	assert(CAPVER(dst) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(src) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(dst) == CAPVER(src));
//    	assert(cap_rights_is_valid(src));
//    	assert(cap_rights_is_valid(dst));
//    	uint n = CAPARSIZE(dst);
//    	assert(n >= CAPARSIZE_MIN && n <= CAPARSIZE_MAX);
        dst &= ~(src & 0x01FFFFFFFFFFFFFF);
//    	for (uint i = 0; i < n; i++) {
//    		dst.cr_rights[i] &= ~(src.cr_rights[i] & 0x01FFFFFFFFFFFFFF);
//    	}
//    	assert(cap_rights_is_valid(src));
//    	assert(cap_rights_is_valid(dst));
        return dst;
    }

    // Test whether a capability grants the requested rights.
    function cap_check(uint64 havep, uint64 needp) internal returns (uint16) {
	    return _cap_check(havep, needp, ktr_cap_fail_type.CAPFAIL_NOTCAPABLE);
    }

    function _cap_check(uint64 havep, uint64 needp, ktr_cap_fail_type ktype) internal returns (uint8) {
        if (!cap_rights_contains(havep, needp))
            return ENOTCAPABLE;
        return 0;
    }

    // For the purposes of procstat(1) and similar tools, allow kern_descrip.c to extract the rights from a capability.
    // Dereferencing fdep requires filedesc.h, but including it would cause significant pollution. Instead add a macro
    // for consumers which want it, most notably kern_descrip.c.
    function cap_rights_fde(s_filedescent fde) internal returns (uint64 ) {
        return fde.fde_caps.fc_rights;
    }
    function cap_rights(s_filedesc fdp, uint8 fd) internal returns (uint64 ) {
        return cap_rights_fde(fdp.fd_files.fdt_ofiles[fd]);
    }

    function cap_ioctl_check(s_filedesc fdp, uint8 fd, uint8 cmd) internal returns (uint16) {
//      KASSERT(fd >= 0 && fd < fdp.fd_nfiles, ("%s: invalid fd=%d", __func__, fd));
        s_filedescent fdep;// = libfdt.fdeget_noref(fdp, fd);
//      KASSERT(fdep != NULL, ("%s: invalid fd=%d", __func__, fd));
        uint8 ncmds = fdep.fde_caps.fc_nioctls;
        if (ncmds == 0)
            return 0;
        uint8[] cmds = fdep.fde_caps.fc_ioctls;
        for (uint i = 0; i < ncmds; i++) {
            if (cmds[i] == cmd)
                return 0;
        }
        return ENOTCAPABLE;
    }
    function cap_fcntl_check_fde(s_filedescent fde, uint16 cmd) internal returns (uint16) {
    	uint32 fcntlcap = (uint32(1) << cmd);
//    	KASSERT((CAP_FCNTL_ALL & fcntlcap) != 0, ("Unsupported fcntl=%d.", cmd));
    	if ((fde.fde_caps.fc_fcntls & fcntlcap) > 0)
    		return 0;
    	return ENOTCAPABLE;
    }
    function cap_fcntl_check(s_filedesc fdp, uint8 fd, uint16 cmd) internal returns (uint16) {
//    	KASSERT(fd >= 0 && fd < fdp.fd_nfiles, ("%s: invalid fd=%d", __func__, fd));
    	return cap_fcntl_check_fde(fdp.fd_files.fdt_ofiles[fd], cmd);
    }

    function cap_enter() internal returns (uint16) {
    }

    // Are we sandboxed (in capability mode)? This is a libc wrapper around the cap_getmode(2) system call.
    function cap_sandboxed() internal returns (bool) {
    }

    // cap_getmode(): Are we in capability mode?
    function cap_getmode(uint16 modep) internal returns (uint16) {
    }

    // Returns capability rights for the given descriptor.
    function cap_rights_get(uint8 fd, uint64 rights) internal returns (uint16) {
        //return __cap_rights_get(CAP_RIGHTS_VERSION, fd, rights);
    }
    // Limits capability rights for the given descriptor (CAP_*).
    function cap_rights_limit(uint8 fd, uint64 rights) internal returns (uint16) {
    }
    function cap_rights_contains(uint64 big, uint64 little) internal returns (bool) {
//    	unsigned int n;
//    	assert(CAPVER(big) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(little) == CAP_RIGHTS_VERSION_00);
//    	assert(CAPVER(big) == CAPVER(little));
//    	n = CAPARSIZE(big);
//    	assert(n >= CAPARSIZE_MIN && n <= CAPARSIZE_MAX);
//    	for (uint i = 0; i < n; i++) {
    		if ((big & little) != little)
    			return false;
//    		}
//    	}
    	return true;
    }

    // Returns array of allowed ioctls for the given descriptor. If all ioctls are allowed,
    // the cmds array is not populated and the function returns CAP_IOCTLS_ALL.
     function cap_ioctls_get(uint8 fd, uint16 maxcmds) internal returns (uint32[] cmds) {
    }
    //  Limits allowed ioctls for the given descriptor.
    function cap_ioctls_limit(uint8 fd, uint32[] cmds, uint16 ncmds) internal returns (uint16) {
    }
    // Returns bitmask of allowed fcntls for the given descriptor.
    function cap_fcntls_get(uint8 fd, uint32 fcntlrightsp) internal returns (uint16) {
    }
    // Limits allowed fcntls for the given descriptor (CAP_FCNTL_*).
    function cap_fcntls_limit(uint8 fd, uint32 fcntlrights) internal returns (uint16) {
    }
}
