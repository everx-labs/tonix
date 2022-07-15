pragma ton-solidity >= 0.57.0;

// I/O control block
struct s_aiocb {
    uint16 aio_fildes;   // File descriptor
    uint32 aio_offset;   // File offset for I/O
    bytes aio_buf;       // I/O buffer in process space
    uint32 aio_nbytes;   // Number of bytes for I/O
    uint8 aio_lio_opcode;// LIO opcode
    uint8 status;
    uint8 error;
}

struct iovec	{
    uint32 iov_base;  // Base address
	uint32 iov_len;    // Length
}

struct Ar {
    uint8 ar_type;
    uint16 index;
    string path;
    string text;
}

library aio {

    uint8 constant WR_COPY           = 1;
    uint8 constant ALLOCATE          = 2;
    uint8 constant TRUNCATE          = 3;
    uint8 constant MKFILE            = 4;
    uint8 constant MKDIR             = 5;
    uint8 constant HARDLINK          = 6;
    uint8 constant SYMLINK           = 7;
    uint8 constant UNLINK            = 8;
    uint8 constant CHATTR            = 9;
    uint8 constant ACCESS            = 10;
    uint8 constant PERMISSION        = 11;
    uint8 constant UPDATE_TIME       = 12;
    uint8 constant UPDATE_TEXT_DATA  = 13;
    uint8 constant MKBIN             = 15;
    uint8 constant MKNOD             = 16;
    uint8 constant ADD_DIR_ENTRY     = 17;
    uint8 constant UPDATE_DIR_ENTRY  = 18;

    uint8 constant AIO_CANCELED     = 1;
    uint8 constant AIO_NOTCANCELED  = 2;
    uint8 constant AIO_ALLDONE      = 3;

    uint8 constant LIO_NOP      = 0;
    uint8 constant LIO_WRITE    = 1;
    uint8 constant LIO_READ     = 2;
    uint8 constant LIO_VECTORED = 4;
    uint8 constant LIO_WRITEV   = (LIO_WRITE | LIO_VECTORED);
    uint8 constant LIO_READV    = (LIO_READ | LIO_VECTORED);
    uint8 constant LIO_SYNC     = 8;
    uint8 constant LIO_DSYNC    = (16 | LIO_SYNC);
    uint8 constant LIO_MLOCK    = 32;

    uint8 constant LIO_NOWAIT   = 0;
    uint8 constant LIO_WAIT     = 1;

    uint8 constant AIO_LISTIO_MAX   = 16;
    uint8 constant MAX_AIO_PROCS    = 32;
    uint8 constant TARGET_AIO_PROCS = 4;
//    uint8 constant AIOD_LIFETIME_DEFAULT = (30 * hz);

    // Asynchronously read from a file
    function aio_read(s_aiocb cb) internal returns (bytes) {
        return cb.aio_buf;
//        (uint16 aio_fildes, uint32 aio_offset, bytes aio_buf, uint32 aio_nbytes, uint8 aio_lio_opcode, uint8 status, uint8 error) = iocb.unpack();

    }
//    function aio_readv(s_aiocb iocb) internal returns () {}

    // Asynchronously write to file
    function aio_write(s_aiocb cb, bytes bts) internal {
        uint len = bts.length;
        uint32 cap = uint32(math.min(len, cb.aio_nbytes));
        if (len <= cb.aio_nbytes) {
            cb.aio_buf.append(bts);
            cb.aio_nbytes -= cap;
            cb.aio_offset += cap;
        } else {

        }
//        (uint16 aio_fildes, uint32 aio_offset, bytes aio_buf, uint32 aio_nbytes, uint8 aio_lio_opcode, uint8 status, uint8 error) = iocb.unpack();
    }
//    function aio_writev(s_aiocb iocb) internal returns () {}

    // List I/O Asynchronously/synchronously read/write to/from file
    //      "lio_mode" specifies whether or not the I/O is synchronous.
    //      "acb_list" is an array of "nacb_listent" I/O control blocks.
    //      when all I/Os are complete, the optional signal "sig" is sent.
    /*function lio_listio(uint8 lio_mode, s_aiocb[] acb_list) internal returns (uint8) {
        for (s_aiocb cb: acb_list) {

        }
   }*/

    // Get completion status returns EINPROGRESS until I/O is complete.
    function aio_error(s_aiocb cb) internal returns (uint8) {
        return cb.error;
    }

    // Finish up I/O, releasing I/O resources and returns the value
    //      that would have been associated with a synchronous I/O request.
    //      This routine must be called once and only once for each
    function aio_return(s_aiocb iocb) internal returns (uint8) {
        return iocb.status;
    }

    // Cancel I/O
    function aio_cancel(uint16 fildes, s_aiocb iocb) internal returns (uint8) {
    }

    // Suspend until all specified I/O or timeout is complete.
    function aio_suspend(s_aiocb[], uint16, uint32) internal returns (uint8) {}

    // Asynchronous mlock
    function aio_mlock(s_aiocb iocb) internal returns (uint8) {}

    function aio_waitcomplete(s_aiocb iocb, uint32) internal returns (uint8) {}
    function aio_fsync(uint16 op, s_aiocb iocb) internal returns (uint8) {}
}
