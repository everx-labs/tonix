struct s_cap_rights {
    uint64        cr_rights[CAP_RIGHTS_VERSION + 2];
}

library cap {
    // General file I/O.
    uint32 constant CAP_READ = 1 << 0; // Allows for openat(O_RDONLY), read(2), readv(2).
    uint32 constant CAP_WRITE = 1 << 1; // Allows for openat(O_WRONLY | O_APPEND), write(2), writev(2).
    uint32 constant CAP_SEEK_TELL = 1 << 2; // Allows for lseek(fd, 0, SEEK_CUR).
    uint32 constant CAP_SEEK = 1 << 3; // Allows for lseek(2)
    uint32 constant CAP_PREAD = CAP_SEEK | CAP_READ; // Allows for aio_read(2), pread(2), preadv(2).
    uint32 constant CAP_PWRITE = CAP_SEEK | CAP_WRITE; //  * Allows for aio_write(2), openat(O_WRONLY) (without O_APPEND), pwrite(2), pwritev(2).
    uint32 constant CAP_MMAP = 1 << 4; // Allows for mmap(PROT_NONE)
    uint32 constant CAP_MMAP_R = CAP_MMAP | CAP_SEEK | CAP_READ; // Allows for mmap(PROT_READ)
    uint32 constant CAP_MMAP_W = CAP_MMAP | CAP_SEEK | CAP_WRITE; // Allows for mmap(PROT_WRITE)
    uint32 constant CAP_MMAP_X = CAP_MMAP | CAP_SEEK | 1 << 5; // Allows for mmap(PROT_EXEC)
    uint32 constant CAP_MMAP_RW = CAP_MMAP_R | CAP_MMAP_W; // Allows for mmap(PROT_READ | PROT_WRITE)
    uint32 constant CAP_MMAP_RX = CAP_MMAP_R | CAP_MMAP_X; // Allows for mmap(PROT_READ | PROT_EXEC)
    uint32 constant CAP_MMAP_WX = CAP_MMAP_W | CAP_MMAP_X; // Allows for mmap(PROT_WRITE | PROT_EXEC)
    uint32 constant CAP_MMAP_RWX = CAP_MMAP_R | CAP_MMAP_W | CAP_MMAP_X; // Allows for mmap(PROT_READ | PROT_WRITE | PROT_EXEC)
    uint32 constant CAP_CREATE = 1 << 6; // Allows for openat(O_CREAT)
    uint32 constant CAP_FEXECVE = 1 << 7; // Allows for openat(O_EXEC) and fexecve(2) in turn
    uint32 constant CAP_FSYNC = 1 << 8; // Allows for openat(O_SYNC), openat(O_FSYNC), fsync(2), aio_fsync(2)
    uint32 constant CAP_FTRUNCATE = 1 << 9; // Allows for openat(O_TRUNC), ftruncate(2)
    uint32 constant CAP_LOOKUP = 1 << 10; // Lookups - used to constrain *at() calls

    // VFS methods.
    uint32 constant CAP_FCHDIR = 1 << 11; // Allows for fchdir(2)
    uint32 constant CAP_FCHFLAGS = 1 << 12; // Allows for fchflags(2)
    uint32 constant CAP_CHFLAGSAT = CAP_FCHFLAGS | CAP_LOOKUP; // Allows for fchflags(2) and chflagsat(2)
    uint32 constant CAP_FCHMOD = 1 << 13; // Allows for fchmod(2)
    uint32 constant CAP_FCHMODAT = CAP_FCHMOD | CAP_LOOKUP; // Allows for fchmod(2) and fchmodat(2)
    uint32 constant CAP_FCHOWN = 1 << 14;// Allows for fchown(2)
    uint32 constant CAP_FCHOWNAT = CAP_FCHOWN | CAP_LOOKUP; // Allows for fchown(2) and fchownat(2)
    uint32 constant CAP_FCNTL = 1 << 15; // Allows for fcntl(2)
    uint32 constant CAP_FLOCK = 1 << 16; // Allows for flock(2), openat(O_SHLOCK), openat(O_EXLOCK),fcntl(F_SETLK_REMOTE), fcntl(F_SETLKW), fcntl(F_SETLK), fcntl(F_GETLK).
    uint32 constant CAP_FPATHCONF = 1 << 17; // Allows for fpathconf(2)
    uint32 constant CAP_FSCK = 1 << 18; // Allows for UFS background-fsck operations
    uint32 constant CAP_FSTAT = 1 << 19;// Allows for fstat(2)
    uint32 constant CAP_FSTATAT = CAP_FSTAT | CAP_LOOKUP; // Allows for fstat(2), fstatat(2) and faccessat(2)
    uint32 constant CAP_FSTATFS = 1 << 20; // Allows for fstatfs(2)
    uint32 constant CAP_FUTIMES = 1 << 21; // Allows for futimens(2) and futimes(2)
    uint32 constant CAP_FUTIMESAT = CAP_FUTIMES | CAP_LOOKUP; // Allows for futimens(2), futimes(2), futimesat(2) and utimensat(2)
    uint32 constant CAP_LINKAT_TARGET = CAP_LOOKUP | 1 << 22; // Allows for linkat(2) (target directory descriptor)
    uint32 constant CAP_MKDIRAT = CAP_LOOKUP | 1 << 23; // Allows for mkdirat(2)            (CAP_LOOKUP | 0x0000000000800000ULL)
    uint32 constant CAP_MKFIFOAT = CAP_LOOKUP | 1 << 24; // Allows for mkfifoat(2)
    uint32 constant CAP_MKNODAT = CAP_LOOKUP | 1 << 25; // Allows for mknodat(2)
    uint32 constant CAP_RENAMEAT_SOURCE = CAP_LOOKUP | 1 << 26; // Allows for renameat(2) (source directory descriptor)
    uint32 constant CAP_SYMLINKAT = CAP_LOOKUP | 1 << 27; // Allows for symlinkat(2)
    uint32 constant CAP_UNLINKAT  =  CAP_LOOKUP | 1 << 28; // Allows for unlinkat(2) and renameat(2) if destination object exists and will be removed.

    // Socket operations.
    uint32 constant CAP_ACCEPT  = 1 << 26; //// Allows for accept(2) and accept4(2)
    uint32 constant CAP_BIND  = 1 << 27;  // Allows for bind(2)
    uint32 constant CAP_CONNECT  = 1 << 28;             // Allows for connect(2)
    uint32 constant CAP_GETPEERNAME  = 1 << 29;         // Allows for getpeername(2)
    uint32 constant CAP_GETSOCKNAME  = 1 << 30;         // Allows for getsockname(2)
    uint32 constant CAP_GETSOCKOPT  = 1 << 31;          // Allows for getsockopt(2)
    uint32 constant CAP_LISTEN  = 1 << 32; // Allows for listen(2)
    uint32 constant CAP_PEELOFF  = 1 << 33; // Allows for sctp_peeloff(2)
    uint32 constant CAP_RECV = CAP_READ;
    uint32 constant CAP_SEND = CAP_WRITE;
    uint32 constant CAP_SETSOCKOPT  = 1 << 34; // Allows for setsockopt(2)
    uint32 constant CAP_SHUTDOWN  = 1 << 35; // // Allows for shutdown(2)

    uint32 constant CAP_BINDAT = CAP_LOOKUP | 1 << 36; // Allows for bindat(2) on a directory descriptor
    uint32 constant CAP_CONNECTAT = CAP_LOOKUP | 1 << 37; // Allows for connectat(2) on a directory descriptor
    uint32 constant CAP_LINKAT_SOURCE  = CAP_LOOKUP | 1 << 38; // Allows for linkat(2) (source directory descriptor)
    uint32 constant CAP_RENAMEAT_TARGET  = CAP_LOOKUP | 1 << 39 ; // Allows for renameat(2) (target directory descriptor)      0x0000040000000000ULL)

    uint32 constant CAP_SOCK_CLIENT = CAP_CONNECT | CAP_GETPEERNAME | CAP_GETSOCKNAME | CAP_GETSOCKOPT | CAP_PEELOFF | CAP_RECV | CAP_SEND | CAP_SETSOCKOPT | CAP_SHUTDOWN;
    uint32 constant CAP_SOCK_SERVER = CAP_ACCEPT | CAP_BIND | CAP_GETPEERNAME | CAP_GETSOCKNAME | CAP_GETSOCKOPT | CAP_LISTEN | CAP_PEELOFF | CAP_RECV | CAP_SEND | CAP_SETSOCKOPT | CAP_SHUTDOWN;

    uint32 constant CAP_ALL0 = (1 << 40) - 1; // All used bits for index 0
    // Available bits for index 0
    uint32 constant CAP_UNUSED0_44 = 1 << 44;
    uint32 constant CAP_UNUSED0_57 = 1 << 57;

    // Allowed fcntl(2) commands.
    uint32 constant CAP_FCNTL_GETFL  = 1 << F_GETFL;
    uint32 constant CAP_FCNTL_SETFL  = 1 << F_SETFL;
    uint32 constant CAP_FCNTL_GETOWN = 1 << F_GETOWN;
    uint32 constant CAP_FCNTL_SETOWN = 1 << F_SETOWN;
    uint32 constant CAP_FCNTL_ALL    = CAP_FCNTL_GETFL | CAP_FCNTL_SETFL | CAP_FCNTL_GETOWN | CAP_FCNTL_SETOWN;
    uint32 constant CAP_IOCTLS_ALL   = SSIZE_MAX;

    function cap_rights_init(uint16 version, s_cap_rights rights) internal returns (cap_rights_t) {}
    function cap_rights_set(s_cap_rights rights) internal returns (s_cap_rights) {}
    function cap_rights_clear(s_cap_rights rights) internal returns (cap_rights_t) {}
    function __cap_rights_is_set(s_cap_rights rights) internal returns (bool) {}
    function cap_rights_is_valid(s_cap_rights rights) internal returns (bool) {}
    function cap_rights_merge(s_cap_rights dst, s_cap_rights src) internal returns (s_cap_rights) {}
    function cap_rights_remove(s_cap_rights dst, s_cap_rights src) internal returns (s_cap_rights) {}

    // Test whether a capability grants the requested rights.
    function cap_check(const cap_rights_t *havep, const cap_rights_t *needp) internal returns (uint16) {
    }

    // For the purposes of procstat(1) and similar tools, allow kern_descrip.c to extract the rights from a capability.
    // Dereferencing fdep requires filedesc.h, but including it would cause significant pollution. Instead add a macro
    // for consumers which want it, most notably kern_descrip.c.
    function cap_rights_fde(s_filedescent fde) internal returns (s_cap_rights ) {
    }
    function cap_rights(s_filedesc fdp, uint16 fd) internal returns (s_cap_rights ) {
    }

    function cap_ioctl_check(s_filedesc fdp, uint16 fd, u_long cmd) internal returns (uint16) {
    }
    function cap_fcntl_check_fde(s_filedescent fde, uint16 cmd) internal returns (uint16) {
    }
    function cap_fcntl_check(s_filedesc fdp, uint16 fd, uint16 cmd) internal returns (uint16) {
    }

    uint16 cap_enter() internal returns (uint16) {
    }

    // Are we sandboxed (in capability mode)? This is a libc wrapper around the cap_getmode(2) system call.
    function cap_sandboxed(void) internal returns (bool) {
    }

    // cap_getmode(): Are we in capability mode?
    function cap_getmode(uint16 modep) internal returns (uint16) {
    }

    // Returns capability rights for the given descriptor.
    function cap_rights_get(uint16 fd, rights) internal returns (uint16) {
    }
    // Limits capability rights for the given descriptor (CAP_*).
    function cap_rights_limit(uint16 fd, s_cap_rights rights) internal returns (uint16) {
    }
    // Returns array of allowed ioctls for the given descriptor. If all ioctls are allowed,
    // the cmds array is not populated and the function returns CAP_IOCTLS_ALL.
     function cap_ioctls_get(uint16 fd, uint16 maxcmds) internal returns (uint32[] cmds) {
    }
    //  Limits allowed ioctls for the given descriptor.
    function cap_ioctls_limit(uint16 fd, uint32[] cmds, uint16 ncmds) internal returns (uint16) {
    }
    // Returns bitmask of allowed fcntls for the given descriptor.
    function cap_fcntls_get(uint16 fd, uint32 fcntlrightsp) internal returns (uint16) {
    }
    // Limits allowed fcntls for the given descriptor (CAP_FCNTL_*).
    function cap_fcntls_limit(uint16 fd, uint32 fcntlrights) internal returns (uint16) {
    }
}
