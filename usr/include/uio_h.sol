pragma ton-solidity >= 0.64.0;

struct s_iovec {
    uint32 iov_base; // Base address
    uint32 iov_len;  // Length
    bytes iov_data;
}
enum uio_rwo {
    UIO_READ,
    UIO_WRITE
}
enum uio_seg {    // Segment flag values
    UIO_USERSPACE,// from user data space
    UIO_SYSSPACE, // from system space
    UIO_NOCOPY    // don't copy, already in object
}
struct s_uio {
    s_iovec[] uio_iov;  // scatter/gather list
    uint8 uio_iovcnt;   // length of scatter/gather list
    uint32 uio_offset;  // offset in target object
    uint32 uio_resid;   // remaining bytes to process
    uio_seg uio_segflg; // address space
    uio_rwo uio_rw;     // operation
    uint16 uio_td;      // owner s_thread
}