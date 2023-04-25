pragma ton-solidity >= 0.67.0;
//import "uio.h";
struct uio {
    iovec[] uio_iov;    // scatter/gather list
    uint8 uio_iovcnt;   // length of scatter/gather list
    uint16 uio_offset;  // offset in target object
    uint16 uio_resid;   // remaining bytes to process
    uio_seg uio_segflg; // address space
    uio_rw uio_rwo;     // operation
}
enum uio_rw { UIO_READ, UIO_WRITE }
enum uio_seg { UIO_USERSPACE, UIO_SYSSPACE, UIO_NOCOPY }
struct iovec {
    uint8 iov_base;
    uint8 iov_len;
}
