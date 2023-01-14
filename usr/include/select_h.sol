pragma ton-solidity >= 0.64.0;
import "uio_h.sol";

// One seltd per-thread allocated on demand as needed.
struct s_seltd {
    uint32 st_selq;   // STAILQ_HEAD(, selfd); List of selfds
    s_selfd st_free1; // free fd for read set
    s_selfd st_free2; // free fd for write set
    uint32 st_wait;   // s_cv; Wait channel
    uint8 st_flags;	  // SELTD_ flags
}

//#define	SELTD_PENDING	0x0001			// We have pending events.
//#define	SELTD_RESCAN	0x0002			// Doing a rescan.

// One selfd allocated per-thread per-file-descriptor.
struct s_selfd {
    uint32 sf_link;	    // STAILQ_ENTRY(selfd); fds owned by this td
    uint32 sf_threads;	// TAILQ_ENTRY(selfd); fds on this selinfo
    s_selinfo sf_si;    // selinfo when linked
    uint32 sf_td;       // owning seltd
    uint32 sf_cookie;   // fd or pollfd
}

struct s_selinfo {
    uint32[] si_tdlist; // struct selfdlist; List of sleeping threads
    uint32[] si_note;   // struct knlist; kernel note list
}

struct read_args {
    uint8 fd;
    uint32 nbytes;
}

struct readv_args {
    uint8 fd;
    s_iovec[] iovp;
    uint8 iovcnt;
}

// Positioned read system call
struct pread_args {
    uint8 fd;
    uint32 nbytes;
    uint32 offset;
}

// Scatter positioned read system call
struct preadv_args {
    uint8 fd;
    s_iovec[] iovp;
    uint8 iovcnt;
    uint32 offset;
}

struct write_args {
    uint8 fd;
    bytes buf;
    uint32 nbytes;
}
// Positioned write system call.
struct pwrite_args {
    uint8 fd;
    bytes buf;
    uint32 nbytes;
    uint32 offset;
}

// Gather write system call.
struct writev_args {
    uint8 fd;
    s_iovec[] iovp;
    uint8 iovcnt;
}

// Gather positioned write system call.
struct pwritev_args {
    uint8 fd;
    s_iovec[] iovp;
    uint8 iovcnt;
    uint32 offset;
}

struct ftruncate_args {
    uint8 fd;
    uint32 length;
}

struct oftruncate_args {
    uint8 fd;
    uint32 length;
}

struct ioctl_args {
    uint8 fd;
    uint32 com;
    uint32 data;
}

struct select_args {
    uint8 nd;
    fd_set fin;
    fd_set ou;
    fd_set ex;
    uint32 tv;
}

//#define	FD_SETSIZE	1024
struct fd_set {
    uint __fds_bits;//[_howmany(FD_SETSIZE, _NFDBITS)];
}

// Convert a select bit set to poll flags.
// The backend always returns POLLHUP/POLLERR if appropriate and we return this as a set bit in any set.
//static const int select_flags[3] = {
//    POLLRDNORM | POLLHUP | POLLERR,
//    POLLWRNORM | POLLHUP | POLLERR,
//    POLLRDBAND | POLLERR
//}

