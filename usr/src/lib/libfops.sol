pragma ton-solidity >= 0.64.0;

import "filedesc_h.sol";
import "proc_h.sol";
import "uio_h.sol";

library libfops {

    uint8 constant ESUCCESS = 0; // Operation completed successfully
    uint8 constant EPERM    = 1; // Operation not permitted
    uint8 constant ENOENT   = 2; // No such file or directory
    uint8 constant ESRCH    = 3; // No such process
    uint8 constant EINTR    = 4; // Interrupted system call
    uint8 constant EIO      = 5; // Input/output error
    uint8 constant ENXIO    = 6; // Device not configured
    uint8 constant E2BIG    = 7; // Argument list too long
    uint8 constant ENOEXEC  = 8; // Exec format error
    uint8 constant EBADF    = 9; // Bad file descriptor
    uint8 constant ECHILD   = 10; // No child processes
    uint8 constant EDEADLK  = 11; // Resource deadlock avoided
    uint8 constant ENOMEM   = 12; // Cannot allocate memory
    uint8 constant EACCES   = 13; // Permission denied
    uint8 constant EFAULT   = 14; // Bad address
    uint8 constant ENOTBLK  = 15; // Block device required
    uint8 constant EBUSY    = 16; // Device busy
    uint8 constant EEXIST   = 17; // File exists
    uint8 constant EXDEV    = 18; // Cross-device link
    uint8 constant ENODEV   = 19; // Operation not supported by device
    uint8 constant ENOTDIR  = 20; // Not a directory
    uint8 constant EISDIR   = 21; // Is a directory
    uint8 constant EINVAL   = 22; // Invalid argument
    uint8 constant EOPNOTSUPP = 45; // Operation not supported
    uint8 constant ERESTART    = 1; // restart syscall
    uint8 constant EAGAIN   = 35; // Resource temporarily unavailable
    uint8 constant EWOULDBLOCK = EAGAIN; // Operation would block

    uint8 constant FOF_OFFSET	 = 0x01;	// Use the offset in uio argument
    uint8 constant DTYPE_NONE	= 0;    // not yet initialized
    uint8 constant DTYPE_VNODE	= 1;    // file
    uint8 constant DTYPE_SOCKET	= 2;    // communications endpoint
    uint8 constant DTYPE_PIPE	= 3;    // pipe
    uint8 constant DTYPE_FIFO	= 4;    // fifo (named pipe)
    uint8 constant DTYPE_KQUEUE	= 5;    // event queue
    uint8 constant DTYPE_CRYPTO	= 6;    // crypto
    uint8 constant DTYPE_MQUEUE	= 7;    // posix message queue
    uint8 constant DTYPE_SHM	= 8;    // swap-backed shared memory
    uint8 constant DTYPE_SEM	= 9;    // posix semaphore
    uint8 constant DTYPE_PTS	= 10;   // pseudo teletype master device
    uint8 constant DTYPE_DEV	= 11;   // Device specific fd type
    uint8 constant DTYPE_PROCDESC = 12;	// process descriptor
    uint8 constant DTYPE_EVENTFD  = 13;	// eventfd
    uint8 constant DTYPE_LINUXTFD = 14;	// emulation timerfd type

    uint16 constant FREAD       = 0x0001;
    uint16 constant FWRITE      = 0x0002;
    uint32 constant O_EXEC      = 0x00040000; // Open for execute only
    uint32 constant O_SEARCH    = O_EXEC;
    uint32 constant FEXEC       = O_EXEC;
    uint32 constant nofileops = 0;
    uint32 constant badfileops = 1;
    uint32 constant path_fileops = 2;
    uint32 constant vnops = 3;
    uint32 constant socketops = 4;
    function get_fops(uint32 fps) internal returns (fops fo) { // 3276923529
        if (fps == badfileops) { fo.fo_read = 708540085; fo.fo_write = 708540085; }
        if (fps == path_fileops) { fo.fo_read = 3765352703; fo.fo_write = 785085867; }
        if (fps == nofileops) { fo.fo_read = 1214234951; fo.fo_write = 1214234951; }
    }
    function nofo_rdwr(s_file, s_uio, s_ucred, uint16, s_thread) internal returns (uint8) { // 1214234951
	    return EOPNOTSUPP;
    }

    function badfo_readwrite(s_file, s_uio, s_ucred, uint16, s_thread) internal returns (uint8) { // 708540085
	    return EBADF;
    }
    function fdrop(s_file fp, s_thread td) internal returns (uint8 error) { // 1430377419
        if (fp.f_count-- == 0)
            error = _fdrop(fp, td);
	}
    function _fdrop(s_file fp, s_thread) internal returns (uint8 error) {
//      error = fo_close(fp, td);
        error = 0;
//      openfiles--;
        delete fp.f_cred;
//      free(fp.f_advice, M_FADVISE);
//      uma_zfree(file_zone, fp);
    }

    function finit(s_file fp, uint16 flag, uint8 ftype, bytes data, uint32 ops) internal { // 2534457232
    	fp.f_data = data;
    	fp.f_flag = flag;
    	fp.f_type = ftype;
    	fp.f_ops = ops;
    }

    function fget_read(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) { // 576449177
        return _fget(td, fd, FREAD, rightsp);
    }
    function fget_write(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) { // 396819964
        return _fget(td, fd, FWRITE, rightsp);
    }
    function fget(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) { // 1558613054
        return _fget(td, fd, 0, rightsp);
    }
    function _fget(s_thread td, uint8 fd, uint16 flags, uint64 needrightsp) internal returns (uint8 error, s_file fp) {
        (error, fp) = fget_unlocked(td, fd, needrightsp);
        if (error > 0)
            return (error, fp);
        if (fp.f_ops == badfileops) {
            fdrop(fp, td);
            return (EBADF, fp);
        }
        // FREAD and FWRITE failure return EBADF as per POSIX.
        error = 0;
        if (flags == FREAD || flags == FWRITE) {
            if ((fp.f_flag & flags) == 0)
            	error = EBADF;
        } else if (flags == FEXEC) {
            if (fp.f_ops != path_fileops &&
              ((fp.f_flag & (FREAD | FEXEC)) == 0 ||
              (fp.f_flag & FWRITE) > 0))
            error = EBADF;
        } else if (flags > 0) {
//          KASSERT(0, "wrong flags");
        }
        if (error > 0) {
            fdrop(fp, td);
            return (error, fp);
        }
        return (0, fp);
    }
    function fget_unlocked(s_thread td, uint8 fd, uint64) internal returns (uint8, s_file fp) { // 2635781655
        s_filedesc fdp = td.td_proc.p_fd.fd_fd;
        s_fdescenttbl fdt = fdp.fd_files;
        if (fd >= fdt.fdt_nfiles)
            return (EBADF, fp);
//      seqc_t seq = seqc_read_notmodify(fd_seqc(fdt, fd));
        s_filedescent fde = fdt.fdt_ofiles[fd];
//      uint64 haverights = cap_rights_fde_inline(fde);
        fp = fde.fde_file;
    }
    function dofilewrite(s_thread td, uint8 fd, s_file fp, s_uio auio, uint32 offset, uint16 flags) internal returns (uint8 error, s_file fpp) {
        fpp = fp;   // 3547684677
        auio.uio_rw = uio_rwo.UIO_WRITE;
        auio.uio_td = td.td_tid;
        auio.uio_offset = offset;
        uint32 cnt = auio.uio_resid;
        (error, fpp) = fo_write(fpp, auio, td.td_ucred, flags, td);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == ERESTART || error == EINTR || error == EWOULDBLOCK))
                error = 0;
            // Socket layer is responsible for issuing SIGPIPE.
//            if (fp.f_type != DTYPE_SOCKET && error == err.EPIPE) {
//                libsignal.tdsignal(td, libsignal.SIGPIPE);
//            }
        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }
    function fo_write(s_file fp, s_uio auio, s_ucred uc, uint16 flags, s_thread td) internal returns (uint8, s_file fpp) { // 785085867
//        fpp = fp;
        uint32 ops = fp.f_ops;
        fops fo = get_fops(ops);
        function (s_file, s_uio, s_ucred, uint16, s_thread) internal returns (uint8, s_file) fwrite;
        fwrite = fo.fo_write;
        return fwrite(fp, auio, uc, flags, td);
        /*bytes buf;
        for (s_iovec v: auio.uio_iov)
            buf.append(v.iov_data);
        fpp.f_data.append(buf);*/
    }
    // 899981548
    function dofileread(s_thread td, uint8 fd, s_file fp, s_uio auio, uint32 offset, uint16 flags) internal returns (uint8 error, bytes buf) {
        // Finish zero length reads right here
        if (auio.uio_resid == 0) {
            td.td_retval = 0;
            return (0, buf);
        }
        auio.uio_rw = uio_rwo.UIO_READ;
        auio.uio_offset = offset;
        auio.uio_td = td.td_tid;
        uint32 cnt = auio.uio_resid;
//        (error, buf) = fp.fo_read(auio, td.td_ucred, flags, td);
        (error, buf) = fo_read(fp, auio, td.td_ucred, flags, td);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == ERESTART || error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }
    function fo_read(s_file fp, s_uio auio, s_ucred uc, uint16 flags, s_thread td) internal returns (uint8, bytes buf) { // 3765352703
        uint32 ops = fp.f_ops;
//        fileops fo = get_fileops(ops);
        fops fo = get_fops(ops);
        function (s_file, s_uio, s_ucred, uint16, s_thread) internal returns (uint8, bytes) fread;
        fread = fo.fo_read;
        return fread(fp, auio, uc, flags, td);
/*        buf = fp.f_data;
        if (buf.empty()) {
            for (s_iovec v: auio.uio_iov)
                buf.append(v.iov_data);
        }
*/
    }
}