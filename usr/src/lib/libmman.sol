pragma ton-solidity >= 0.64.0;
import "ucred_h.sol";
import "filedesc_h.sol";
struct s_shmfd {
    uint32 shm_size; // vm_ooffset_t
    uint32 shm_object; // vm_object_t
    uint8 shm_refs;
    uint16 shm_uid;
    uint16 shm_gid;
    uint16 shm_mode;
    uint8 shm_kmappings;
    // Values maintained solely to make this a better-behaved file descriptor for fstat() to run on.
    uint32 shm_atime;
    uint32 shm_mtime;
    uint32 shm_ctime;
    uint32 shm_birthtime;
    uint16 shm_ino;
    //	s_label shm_label;		/* MAC label */
    string shm_path;
    uint16 shm_flags;
    uint16 shm_seals;
}

library libmman {

    uint8 constant INHERIT_SHARE =	0;
    uint8 constant INHERIT_COPY =	1;
    uint8 constant INHERIT_NONE =	2;
    uint8 constant INHERIT_ZERO =	3;

// Protections are chosen from these bits, or-ed together
    uint8 constant PROT_NONE	= 0x00;	// no permissions
    uint8 constant PROT_READ	= 0x01;	// pages can be read
    uint8 constant PROT_WRITE	= 0x02;	// pages can be written
    uint8 constant PROT_EXEC	= 0x04;	// pages can be executed
    uint8 constant _PROT_ALL =	PROT_READ | PROT_WRITE | PROT_EXEC;
//    uint8 constant PROT_EXTRACT(prot)	((prot) & _PROT_ALL)
    uint8 constant _PROT_MAX_SHIFT	= 16;
//    uint8 constant PROT_MAX(prot)		((prot) << _PROT_MAX_SHIFT)
//    uint8 constant PROT_MAX_EXTRACT(prot)	(((prot) >> _PROT_MAX_SHIFT) & _PROT_ALL)

// Flags contain sharing type and options. Sharing types; choose one.
    uint16 constant MAP_SHARED =	0x0001;		// share changes
    uint16 constant MAP_PRIVATE =	0x0002;		// changes are private
    uint16 constant MAP_COPY =	MAP_PRIVATE;	// Obsolete
    uint16 constant MAP_FIXED =	 0x0010;	    // map addr must be exactly as requested
    uint16 constant MAP_RESERVED0020 = 0x0020;	// previously unimplemented MAP_RENAME
    uint16 constant MAP_RESERVED0040 = 0x0040;	// previously unimplemented MAP_NORESERVE
    uint16 constant MAP_RESERVED0080 = 0x0080;	// previously misimplemented MAP_INHERIT
    uint16 constant MAP_RESERVED0100 = 0x0100;	// previously unimplemented MAP_NOEXTEND
    uint16 constant MAP_HASSEMAPHORE = 0x0200;	// region may contain semaphores
    uint16 constant MAP_STACK =	 0x0400;	    // region grows down, like a stack
    uint16 constant MAP_NOSYNC = 0x0800;        // page to but do not sync underlying file
    uint16 constant MAP_FILE =	 0x0000;	    // map from file (default)
    uint16 constant MAP_ANON =	 0x1000;	    // allocated from memory, swap space
    uint16 constant MAP_ANONYMOUS =	 MAP_ANON;  // For compatibility.

    uint32 constant MAP_GUARD =	 0x00002000;    // reserve but don't map address range
    uint32 constant MAP_EXCL =	 0x00004000;    // for MAP_FIXED, fail if address is used
    uint32 constant MAP_NOCORE = 0x00020000;    // dont include these pages in a coredump
    uint32 constant MAP_PREFAULT_READ = 0x00040000; // prefault mapping for reading
    uint32 constant MAP_32BIT =	 0x00080000;        // map in the low 2GB of address space
//#define	MAP_ALIGNED(n)	 ((n) << MAP_ALIGNMENT_SHIFT)
    uint32 constant MAP_ALIGNMENT_SHIFT =	24;
//    uint32 constant MAP_ALIGNMENT_MASK =	MAP_ALIGNED(0xff);
//    uint32 constant MAP_ALIGNED_SUPER =	MAP_ALIGNED(1); // align on a superpage
    uint32 constant SHM_RENAME_NOREPLACE =	(1 << 0); // Don't overwrite dest, if it exists
    uint32 constant SHM_RENAME_EXCHANGE =	(1 << 1); // Atomically swap src and dest
    uint16 constant MCL_CURRENT   =	0x0001;	// Lock only current memory
    uint16 constant MCL_FUTURE  =	0x0002;	// Lock all future memory as well
    uint16 constant MS_SYNC     =	0x0000;	// msync synchronously
    uint16 constant MS_ASYNC    =	0x0001;	// return immediately
    uint16 constant MS_INVALIDATE  =0x0002;	// invalidate all cached data
//#define MAP_FAILED	((void *)-1)
    uint8 constant _MADV_NORMAL =	0;	// no further special treatment
    uint8 constant _MADV_RANDOM =	1;	// expect random page references
    uint8 constant _MADV_SEQUENTIAL = 2;// expect sequential page references
    uint8 constant _MADV_WILLNEED =	3;	// will need these pages
    uint8 constant _MADV_DONTNEED =	4;	// dont need these pages
    uint8 constant MADV_NORMAL =	_MADV_NORMAL;
    uint8 constant MADV_RANDOM =	_MADV_RANDOM;
    uint8 constant MADV_SEQUENTIAL = _MADV_SEQUENTIAL;
    uint8 constant MADV_WILLNEED =	_MADV_WILLNEED;
    uint8 constant MADV_DONTNEED =	_MADV_DONTNEED;
    uint8 constant MADV_FREE =	5;	    // dont need these pages, and junk contents
    uint8 constant MADV_NOSYNC =	6;	// try to avoid flushes to physical media
    uint8 constant MADV_AUTOSYNC =	7;	// revert to default flushing strategy
    uint8 constant MADV_NOCORE =	8;	// do not include these pages in a core file
    uint8 constant MADV_CORE =	9;	    // revert to including pages in a core file
    uint8 constant MADV_PROTECT =	10;	// protect process from pageout kill
    uint8 constant MINCORE_INCORE =	 	 0x1;       // Page is incore
    uint8 constant MINCORE_REFERENCED =	 0x2;       // Page has been referenced by us
    uint8 constant MINCORE_MODIFIED =	 0x4;       // Page has been modified by us
    uint8 constant MINCORE_REFERENCED_OTHER = 0x8;  // Page has been referenced
    uint8 constant MINCORE_MODIFIED_OTHER =	0x10;   // Page has been modified
    uint8 constant MINCORE_SUPER =		0x60;       // Page is a "super" page
//#define	MINCORE_PSIND(i)	(((i) << 5) & MINCORE_SUPER) // Page size
//#define	SHM_ANON		((char *)1)
    uint32 constant SHM_ALLOW_SEALING   =	0x00000001;
    uint32 constant SHM_GROW_ON_WRITE   =	0x00000002;
    uint32 constant SHM_LARGEPAGE       =	0x00000004;
    uint8 constant SHM_LARGEPAGE_ALLOC_DEFAULT	= 0;
    uint8 constant SHM_LARGEPAGE_ALLOC_NOWAIT	= 1;
    uint8 constant SHM_LARGEPAGE_ALLOC_HARD	= 2;
    uint32 constant MFD_CLOEXEC =			0x00000001;
    uint32 constant MFD_ALLOW_SEALING =		0x00000002;
    uint32 constant MFD_HUGETLB =			0x00000004;
    uint32 constant MFD_HUGE_MASK =			0xFC000000;
    uint32 constant MFD_HUGE_SHIFT =			26;
    uint64 constant MFD_HUGE_64KB = 	uint64(16) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_512KB =    uint64(19) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_1MB =  	uint64(20) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_2MB =  	uint64(21) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_8MB =  	uint64(23) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_16MB = 	uint64(24) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_32MB = 	uint64(25) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_256MB =    uint64(28) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_512MB =    uint64(29) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_1GB =  	uint64(30) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_2GB =  	uint64(31) << MFD_HUGE_SHIFT;
    uint64 constant MFD_HUGE_16GB = 	uint64(34) << MFD_HUGE_SHIFT;
    uint32 constant POSIX_MADV_NORMAL =	_MADV_NORMAL;
    uint32 constant POSIX_MADV_RANDOM =	_MADV_RANDOM;
    uint32 constant POSIX_MADV_SEQUENTIAL =	_MADV_SEQUENTIAL;
    uint32 constant POSIX_MADV_WILLNEED =	_MADV_WILLNEED;
    uint32 constant POSIX_MADV_DONTNEED =	_MADV_DONTNEED;
//#define	MAP_32BIT_MAX_ADDR	((vm_offset_t)1 << 31)

    function shm_map(s_file fp, uint32 size, uint32 offset, uint32[] memp) internal returns (uint8) {}
    function shm_unmap(s_file fp, uint32 mem, uint32 size) internal returns (uint8) {}
    function shm_access(s_shmfd shmfd, s_ucred ucred, uint16 flags) internal returns (uint8) {}
    function shm_alloc(s_ucred ucred, uint16 mode, bool largepage) internal returns (s_shmfd) {}
    function shm_hold(s_shmfd shmfd) internal returns (s_shmfd) {}
    function shm_drop(s_shmfd shmfd) internal {}
    function shm_dotruncate(s_shmfd shmfd, uint32 length) internal returns (uint8) {}
    function shm_largepage(s_shmfd shmfd) internal returns (bool) {}
//    function shm_remove_prison(s_prison pr) internal {}
    function getpagesizes(uint32, int) internal returns (uint8) {}
    function madvise(uint32, uint32, int) internal returns (uint8) {}
    function mincore(uint32, uint32, string) internal returns (uint8) {}
    function minherit(uint32, uint32, int) internal returns (uint8) {}
    function mlock(uint32, uint32) internal returns (uint8) {}
    function mmap(uint32, uint32, int, int, int, uint32) internal returns (uint32) {}
    function mprotect(uint32, uint32, int) internal returns (uint8) {}
    function msync(uint32, uint32, int) internal returns (uint8) {}
    function munlock(uint32, uint32) internal returns (uint8) {}
    function munmap(uint32, uint32) internal returns (uint8) {}
    function posix_madvise(uint32, uint32, int) internal returns (uint8) {}
    function mlockall(int) internal returns (uint8) {}
    function munlockall() internal returns (uint8) {}
    function shm_open(string, int, uint16) internal returns (uint8) {}
    function shm_unlink(string) internal returns (uint8) {}
    function memfd_create(string, uint32) internal returns (uint8) {}
    function shm_create_largepage(string, int, int, int, uint16) internal returns (uint8) {}
    function shm_rename(string, string, int) internal returns (uint8) {}
}