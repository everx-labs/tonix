pragma ton-solidity >= 0.64.0;
import "proc_h.sol";
import "libuio.sol";
import "select_h.sol";
import "libfops.sol";
import "libmalloc.sol";
library libselect {

    uint8 constant EINVAL   = 22; // Invalid argument

    using libuio for s_uio;
    uint64 constant cap_read_rights = 1 << 0; //libcap.CAP_READ;
    uint64 constant cap_write_rights = 1 << 1; //libcap.CAP_WRITE;
    uint64 constant cap_pwrite_rights = (1 << 3) + (1 << 1); // CAP_SEEK | CAP_WRITE
    uint64 constant cap_pread_rights = (1 << 3) + (1 << 0); // CAP_SEEK | CAP_READ
//    uint64 constant cap_fcntl_rights = (1 << CAP_FCNTL); // CAP_SEEK | CAP_READ

    function sys_read(s_thread td, read_args uap) internal returns (uint8 error, bytes buf) {
        s_uio auio;
        s_iovec aiov;
        if (uap.nbytes > libuio.IOSIZE_MAX)
            return (EINVAL, buf);
//        aiov.iov_base = uap.buf;
        aiov.iov_len = uap.nbytes;
        auio.uio_iov = [aiov];
        auio.uio_iovcnt = 1;
        auio.uio_resid = uap.nbytes;
        auio.uio_segflg = uio_seg.UIO_USERSPACE;
        (error, buf) = kern_readv(td, uap.fd, auio);
    }

    function sys_pread(s_thread td, pread_args uap) internal returns (uint8 error, bytes buf) {
        return kern_pread(td, uap.fd, uap.nbytes, uap.offset);
    }

    function kern_pread(s_thread td, uint8 fd, uint32 nbytes, uint32 offset) internal returns (uint8 error, bytes buf) {
        s_uio auio;
        s_iovec aiov;
        if (nbytes > libuio.IOSIZE_MAX)
            return (EINVAL, buf);
        aiov.iov_base = offset;
        aiov.iov_len = nbytes;
        auio.uio_iov = [aiov];
        auio.uio_iovcnt = 1;
        auio.uio_resid = nbytes;
        auio.uio_segflg = uio_seg.UIO_USERSPACE;
        (error, buf) = kern_preadv(td, fd, auio, offset);
    }

    function sys_readv(s_thread td, readv_args uap) internal returns (uint8 error, bytes buf) {
        s_uio auio;
        error = auio.copyinuio(uap.iovp, uap.iovcnt);
        if (error > 0)
            return (error, buf);
        (error, buf) = kern_readv(td, uap.fd, auio);
//      libmalloc.free(auio, libmalloc.M_IOV);
    }

    function kern_readv(s_thread td, uint8 fd, s_uio auio) internal returns (uint8 error, bytes buf) {
        s_file fp;
        (error, fp) = libfdt.fget_read(td, fd, cap_read_rights);
        if (error > 0)
            return (error, buf);
        (error, buf) = dofileread(td, fd, fp, auio, 0, 0);
        libfdt.fdrop(fp, td);
    }

    function sys_preadv(s_thread td, preadv_args uap) internal returns (uint8 error, bytes buf) {
        s_uio auio;
        error = auio.copyinuio(uap.iovp, uap.iovcnt);
        if (error > 0)
            return (error, buf);
        (error, buf) = kern_preadv(td, uap.fd, auio, uap.offset);
//      libmalloc.free(auio, libmalloc.M_IOV);
    }

    function kern_preadv(s_thread td, uint8 fd, s_uio auio, uint32 offset) internal returns (uint8 error, bytes buf) {
        s_file fp;
        (error, fp) = libfdt.fget_read(td, fd, cap_pread_rights);
        if (error > 0)
            return (error, buf);
//        if ((fp.f_ops.fo_flags & libfdt.DFLAG_SEEKABLE) == 0)
//            error = err.ESPIPE;
        else if (offset < 0 && (fp.f_vnode == 0 || fp.f_type != uint8(vtype.VCHR)))
            error = EINVAL;
        else
            (error, buf) = dofileread(td, fd, fp, auio, offset, libfdt.FOF_OFFSET);
        libfdt.fdrop(fp, td);
    }

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
        (error, buf) = libfdt.fo_read(fp, auio, td.td_ucred, flags, td);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == err.ERESTART || error == err.EINTR || error == err.EWOULDBLOCK))
                error = 0;
        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }

    function sys_write(s_thread td, write_args uap) internal returns (uint8 error) {
        s_uio auio;
        s_iovec aiov;
        if (uap.nbyte > libuio.IOSIZE_MAX)
            return EINVAL;
        //aiov.iov_base = uap.buf;
        aiov.iov_len = uap.nbyte;
        auio.uio_iov = [aiov];
        auio.uio_iovcnt = 1;
        auio.uio_resid = uap.nbyte;
        auio.uio_segflg = uio_seg.UIO_USERSPACE;
        error = kern_writev(td, uap.fd, auio);
    }

    function kern_writev(s_thread td, uint8 fd, s_uio auio) internal returns (uint8 error)  {
        s_file fp;
        (error, fp) = libfdt.fget_write(td, fd, cap_write_rights);
        if (error > 0)
            return error;
        error = dofilewrite(td, fd, fp, auio, 0, 0);
        libfdt.fdrop(fp, td);
    }

    // Common code for writev and pwritev that writes data to a file using the passed in uio, offset, and flags.
    function dofilewrite(s_thread td, uint8 fd, s_file fp, s_uio auio, uint32 offset, uint16 flags) internal returns (uint8 error) {
        auio.uio_rw = uio_rwo.UIO_WRITE;
        auio.uio_td = td.td_tid;
        auio.uio_offset = offset;
        uint32 cnt = auio.uio_resid;
        if ((error = libfdt.fo_write(fp, auio, td.td_ucred, flags, td)) > 0) {
            if (auio.uio_resid != cnt && (error == err.ERESTART || error == err.EINTR || error == err.EWOULDBLOCK))
                error = 0;
            // Socket layer is responsible for issuing SIGPIPE.
            if (fp.f_type != libfdt.DTYPE_SOCKET && error == err.EPIPE) {
//                libsignal.tdsignal(td, libsignal.SIGPIPE);
            }
        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }

    function sys_pwrite(s_thread td, pwrite_args uap) internal returns (uint8 error) {
        return kern_pwrite(td, uap.fd, uap.buf, uap.nbyte, uap.offset);
    }

    function kern_pwrite(s_thread td, uint8 fd, bytes buf, uint32 nbyte, uint32 offset) internal returns (uint8 error) {
        s_uio auio;
        s_iovec aiov;
        if (nbyte > libuio.IOSIZE_MAX)
            return EINVAL;
        //aiov.iov_base = buf; alloc
        aiov.iov_len = nbyte;
        auio.uio_iov = [aiov];
        auio.uio_iovcnt = 1;
        auio.uio_resid = nbyte;
        auio.uio_segflg = uio_seg.UIO_USERSPACE;
        error = kern_pwritev(td, fd, auio, offset);
    }

    function sys_writev(s_thread td, writev_args uap) internal returns (uint8 error) {
        s_uio auio;
        error = auio.copyinuio(uap.iovp, uap.iovcnt);
        if (error > 0)
            return error;
        error = kern_writev(td, uap.fd, auio);
//    	libmalloc.free(auio, libmalloc.M_IOV);
    }

    function sys_pwritev(s_thread td,  pwritev_args uap) internal returns (uint8 error) {
        s_uio auio;
        error = auio.copyinuio(uap.iovp, uap.iovcnt);
        if (error > 0)
            return error;
        error = kern_pwritev(td, uap.fd, auio, uap.offset);
//    	libmalloc.free(auio, libmalloc.M_IOV);
    }

    function kern_pwritev(s_thread td, uint8 fd, s_uio auio, uint32 offset) internal returns (uint8 error) {
        s_file fp;
        (error, fp) = libfdt.fget_write(td, fd, cap_pwrite_rights);
        if (error > 0)
            return error;
//        if ((fp.f_ops.fo_flags & libfdt.DFLAG_SEEKABLE) == 0)
//            error = err.ESPIPE;
        else if (offset < 0 && (fp.f_vnode == 0 || fp.f_type != uint8(vtype.VCHR)))
            error = EINVAL;
        else
            error = dofilewrite(td, fd, fp, auio, offset, libfdt.FOF_OFFSET);
        libfdt.fdrop(fp, td);
    }

}