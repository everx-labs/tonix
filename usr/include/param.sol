pragma ton-solidity >= 0.58.0;

library param {
    uint16 constant PAGE_SHIFT = 12;              // LOG2(PAGE_SIZE)
    uint16 constant PAGE_SIZE = uint16(1) << PAGE_SHIFT;

    uint32 constant ARG_MAX     = 256 * 1024; // max bytes for KVA-starved archs
    uint8 constant CHILD_MAX   = 40;   // max simultaneous processes
    uint8 constant MAX_CANON   = 255;  // max bytes in term canon input line
    uint8 constant MAX_INPUT   = 255;  // max bytes in terminal input
    uint8 constant NAME_MAX    = 255;  // max bytes in a file name
    uint16 constant NGROUPS_MAX = 1023; // max supplemental group id's
    uint8 constant OPEN_MAX    = 64;   // max open files per process
    uint16 constant PATH_MAX    = 1024; // max bytes in pathname
    uint16 constant PIPE_BUF    = 512;  // max bytes for atomic pipe writes
    uint16 constant IOV_MAX     = 1024; // max elements in i/o vector

    uint16 constant MAXCOMLEN      = 19;              // max command name remembered
    uint16 constant MAXINTERP      = PATH_MAX;        // max interpreter file name length
    uint16 constant MAXLOGNAME     = 33;              // max login name length (incl. NUL)
    uint16 constant MAXUPRC        = CHILD_MAX;       // max simultaneous processes
    uint32 constant NCARGS         = ARG_MAX;         // max bytes for an exec function
    uint16 constant NGROUPS        = NGROUPS_MAX + 1; // max number groups
    uint16 constant NOFILE         = OPEN_MAX;        // max open files per process
    uint16 constant NOGROUP        = 65535;           // marker for empty group set member
    uint16 constant MAXHOSTNAMELEN = 256;             // max hostname size
    uint16 constant SPECNAMELEN    = 255;             // max length of devicename

    uint16 constant FALSE          = 0;
    uint16 constant TRUE           = 1;
    uint16 constant DEV_BSHIFT     = 9;               // log2(DEV_BSIZE)
    uint16 constant DEV_BSIZE      = uint16(1) << DEV_BSHIFT;
    uint16 constant BLKDEV_IOSIZE  = PAGE_SIZE;       // default block device I/O size
    uint64 constant DFLTPHYS       = 64 * 1024;      // default max raw I/O transfer size
    uint64 constant MAXPHYS        = 128 * 1024;
    uint64 constant MAXDUMPPGS     = DFLTPHYS / PAGE_SIZE;

    /*
     * Constants related to network buffer management.
     * MCLBYTES must be no larger than PAGE_SIZE.
     */
    uint16 constant MSIZE         = 256; // size of an mbuf
    uint16 constant MCLSHIFT      = 11; // convert bytes to mbuf clusters
    uint16 constant MCLBYTES      = uint16(1) << MCLSHIFT; // size of an mbuf cluster
    uint16 constant MJUMPAGESIZE  = MCLBYTES;
    uint16 constant MJUM9BYTES    = (9 * 1024); // jumbo cluster 9k
    uint16 constant MJUM16BYTES   = (16 * 1024); // jumbo cluster 16k

    uint16 constant PRIMASK = 0x0ff;
    uint16 constant PCATCH  = 0x100; // OR'd with pri for tsleep to check signals
    uint16 constant PDROP   = 0x200; // OR'd with pri to stop re-entry of interlock mutex
    uint16 constant NZERO   = 0; // default "nice"
    uint16 constant NBBY    = 8; // number of bits in a byte
    uint16 constant NBPW    = 4; // number of bytes per word (integer)
    uint16 constant CMASK   = 0x12; // default file mask: S_IWGRP|S_IWOTH
    uint16 constant NODEV   = 0; // non-existent device
/*
 * File system parameters and macros.
 *
 * MAXBSIZE -   Filesystems are made out of blocks of at most MAXBSIZE bytes
 *              per block.  MAXBSIZE may be made larger without effecting
 *              any existing filesystems as long as it does not exceed MAXPHYS,
 *              and may be made smaller at the risk of not being able to use
 *              filesystems which require a block size exceeding MAXBSIZE.
 *
 * MAXBCACHEBUF - Maximum size of a buffer in the buffer cache.  This must
 *              be >= MAXBSIZE and can be set differently for different
 *              architectures by defining it in <machine/param.h>.
 *              Making this larger allows NFS to do larger reads/writes.
 *
 * BKVASIZE -   Nominal buffer space per buffer, in bytes.  BKVASIZE is the
 *              minimum KVM memory reservation the kernel is willing to make.
 *              Filesystems can of course request smaller chunks.  Actual
 *              backing memory uses a chunk size of a page (PAGE_SIZE).
 *              The default value here can be overridden on a per-architecture
 *              basis by defining it in <machine/param.h>.
 *
 *              If you make BKVASIZE too small you risk seriously fragmenting
 *              the buffer KVM map which may slow things down a bit.  If you
 *              make it too big the kernel will not be able to optimally use
 *              the KVM memory reserved for the buffer cache and will wind
 *              up with too-few buffers.
 *
 *              The default is 16384, roughly 2x the block size used by a
 *              normal UFS filesystem.
 */
    uint16 constant MAXBSIZE       = 32768;    // must be power of 2
    uint16 constant MAXBCACHEBUF   = MAXBSIZE; // must be a power of 2 >= MAXBSIZE
    uint16 constant BKVASIZE       = 16384;    // must be power of 2
    uint16 constant BKVAMASK       = (BKVASIZE-1);

/*
 * MAXPATHLEN defines the longest permissible path length after expanding
 * symbolic links. It is used to allocate a temporary buffer from the buffer
 * pool in which to do the name expansion, hence should be a power of two,
 * and must be less than or equal to MAXBSIZE.  MAXSYMLINKS defines the
 * maximum number of symbolic links that may be expanded in a path name.
 * It should be set high enough to allow all legitimate uses, but halt
 * infinite loops reasonably quickly.
 */
    uint16 constant MAXPATHLEN  = PATH_MAX;
    uint16 constant MAXSYMLINKS = 32;
    uint16 constant FSHIFT      = 11;              // bits to right of fixed binary point
    uint16 constant FSCALE      = uint16(1) << FSHIFT;

    uint32 constant P_OSREL_SIGWAIT              = 700000;
    uint32 constant P_OSREL_SIGSEGV              = 700004;
    uint32 constant P_OSREL_MAP_ANON             = 800104;
    uint32 constant P_OSREL_MAP_FSTRICT          = 1100036;
    uint32 constant P_OSREL_SHUTDOWN_ENOTCONN    = 1100077;
    uint32 constant P_OSREL_MAP_GUARD            = 1200035;
    uint32 constant P_OSREL_WRFSBASE             = 1200041;
    uint32 constant P_OSREL_CK_CYLGRP            = 1200046;
    uint32 constant P_OSREL_VMTOTAL64            = 1200054;
    uint32 constant P_OSREL_CK_SUPERBLOCK        = 1300000;
    uint32 constant P_OSREL_CK_INODE             = 1300005;
    uint32 constant P_OSREL_POWERPC_NEW_AUX_ARGS = 1300070;

/*#define setbit(a,i)     (((unsigned char *)(a))[(i)/NBBY] |= 1<<((i)%NBBY))
#define clrbit(a,i)     (((unsigned char *)(a))[(i)/NBBY] &= ~(1<<((i)%NBBY)))
#define isset(a,i) (((const unsigned char *)(a))[(i)/NBBY] & (1<<((i)%NBBY)))
#define isclr(a,i) ((((const unsigned char *)(a))[(i)/NBBY] & (1<<((i)%NBBY))) == 0)
#define howmany(x, y)   (((x)+((y)-1))/(y))
#define nitems(x)       (sizeof((x)) / sizeof((x)[0]))
#define rounddown(x, y) (((x)/(y))*(y))
#define rounddown2(x, y) ((x)&(~((y)-1)))          // if y is power of two
#define roundup(x, y)   ((((x)+((y)-1))/(y))*(y))  // to any y
#define roundup2(x, y)  (((x)+((y)-1))&(~((y)-1))) // if y is powers of two
#define powerof2(x)     ((((x)-1)&(x))==0)
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))*/

}