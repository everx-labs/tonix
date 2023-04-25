pragma ton-solidity >= 0.66.0;
import "fs.h";
import "uio.h";
import "sb.h";
import "libmfiledesc.sol";

library libgenio {
    using libgenio for mapping (uint32 => TvmCell);
    using libfdt for fdescenttbl;
    uint8 constant ESUCCESS = 0;  // Operation completed successfully
    uint8 constant EPERM    = 1;  // Operation not permitted
    uint8 constant ENOENT   = 2;  // No such file or directory
    uint8 constant ESRCH    = 3;  // No such process
    uint8 constant EINTR    = 4;  // Interrupted system call
    uint8 constant EIO      = 5;  // Input/output error
    uint8 constant ENXIO    = 6;  // Device not configured
    uint8 constant ENOMEM   = 12; // Cannot allocate memory
    uint8 constant EACCES   = 13; // Permission denied
    uint8 constant EFAULT   = 14; // Bad address
    uint8 constant EBUSY    = 16; // Device busy
    uint8 constant EEXIST   = 17; // File exists
    uint8 constant ENOTDIR  = 20; // Not a directory
    uint8 constant EISDIR   = 21; // Is a directory
    uint8 constant EINVAL   = 22; // Invalid argument
    uint8 constant ENOTTY   = 25; // Inappropriate ioctl for device
    uint8 constant ENOSPC   = 28; // No space left on device
    uint8 constant ESPIPE   = 29; // Illegal seek
    uint8 constant EROFS    = 30; // Read-only filesystem
    uint8 constant ERANGE   = 34; // Result too large
    uint8 constant EAGAIN   = 35; // Resource temporarily unavailable
    uint8 constant EWOULDBLOCK = EAGAIN; // Operation would block
    uint8 constant ECONNREFUSED = 61; // Connection refused
    uint8 constant ENAMETOOLONG = 63; // File name too long
    uint8 constant ENOTEMPTY = 66; // Directory not empty
    uint8 constant EUSERS    = 68; // Too many users
    uint8 constant ENOSYS    = 78; // Function not implemented
    uint8 constant EAUTH     = 80; // Authentication error
    uint8 constant ENEEDAUTH = 81; // Need authenticator
    uint8 constant EDOOFUS   = 88; // Programming error
    uint8 constant EINTEGRITY   = 97; // Integrity check failed
    uint8 constant DFLAG_SEEKABLE = 0x02; // seekable / nonsequential
    uint8 constant FOF_OFFSET   = 0x01; // Use the offset in uio argument
    uint16 constant IOSIZE_MAX = 64000;
    function fsbtodb(fsb f, uint b) internal returns (uint) {
        return b << f.fsbtodb;
    }
    function cgtod(fsb f, uint c) internal returns (uint) {
        return cgstart(f, c) + f.cblkno;    /* cg block */
    }
    function cgstart(fsb f, uint c) internal returns (uint) {
        return f.fpg * c;
    }
    function blkstofrags(fsb f, uint n) internal returns (uint) {
        return n * f.frag;
    }
    function pread(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 fd, uint16 pbuf, uint8 nbyte, uint16 offset) internal returns (uint8 error, uint16 cnt, TvmBuilder pb) {
        if (nbyte > IOSIZE_MAX)
            return (EINVAL, 0, pb);
        uio auio = uio([iovec(uint8(pbuf), nbyte)], 1, offset, nbyte, uio_seg.UIO_USERSPACE, uio_rw.UIO_READ);
        if (auio.uio_resid == 0)
            return (0, 0, pb);
        (error, cnt, pb) = m.kern_preadv(fdt, fd, auio, offset);
//        error = m.fo_read(auio, m[fd].toSlice(), FOF_OFFSET);
//        uint16 cnt = nbyte;
        if (error > 0) {
            if (auio.uio_resid != nbyte && (error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
//      if (cnt >= auio.uio_resid)
//            cnt -= auio.uio_resid;
    }
//    function readsuper(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 devfd, uint16 sblockloc, uint8 flags) internal returns (uint8 error, fsb f) {
//        flags;
////        uint8 res;
//        uint16 cnt;
//        TvmBuilder b;
//        (error, cnt, b) = m.pread(fdt, devfd, 6, 57, sblockloc);
//        if (error == 0)
//            f = abi.decode(b.toCell(), fsb);
////        error = (devfd, sblockloc, (void **)fsp, SBLOCKSIZE);
//    }
//    function sbget(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 devfd, uint16 sblockloc, uint8 flags) internal returns (uint8 error, fsb f) {
////        uio auio;
////        auio.uio_resid = 58;
////        TvmBuilder b;
////        uint16 cnt;
////        (error, cnt) = m.pread(fdt, devfd, pbuf, 58, offset);
//        return ffs_sbget(m, fdt, devfd, sblockloc, flags);
////        if (error == 0)
////            //f = abi.decode(b.toCell(), fs);
////            f = abi.decode(m[pbuf], fs);
////        else
////            error = ENOENT;
//    }
//    function ffs_sbget(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 devfd, uint16 sblock, uint8 flags) internal returns (uint8 error, fsb f) {
//        (error, f) = m.readsuper(fdt, devfd, sblock, flags | libufs.UFS_ALTSBLK);
//      if (error != 0) {
//        }
//    }
    function dofileread(mapping (uint32 => TvmCell) m, file fp, uio auio, uint16 offset, uint8 flags) internal returns (uint8 error, uint16 retval, TvmBuilder b) {
        /* Finish zero length reads right here */
        if (auio.uio_resid == 0)
            return (0, 0, b);
        auio.uio_rwo = uio_rw.UIO_READ;
        auio.uio_offset = offset;
        uint16 cnt = auio.uio_resid;
        uint16 nread;
        (error, nread, b) = m.fo_read(fp, auio, flags);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
        cnt -= auio.uio_resid;
        return (error, cnt, b);
    }
    function kern_preadv(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 fd, uio auio, uint16 offset) internal returns (uint8 error, uint16 cnt, TvmBuilder b) {
        file fp;
        (error, fp) = fdt.fget_read(fd);
        if (error == 0) {
            if (offset < 0)// &&
                error = EINVAL;
            else
                (error, cnt, b) = m.dofileread(fp, auio, offset, FOF_OFFSET);
        }
    }
    function fo_read(mapping (uint32 => TvmCell) m, file fp, uio auio, uint8 flags) internal returns (uint8 error, uint16 cnt, TvmBuilder b) {
        flags;
        error = 0;
        TvmSlice s = m[fp.f_data].toSlice();
        (uint16 nb,) = s.size();
        (iovec[] uio_iov, , , uint16 uio_resid, , ) = auio.unpack();
        for (iovec iv: uio_iov) {
            (uint8 iov_base, uint8 iov_len) = iv.unpack();
            uint16 bil = uint16(iov_len) * 8;
            if (nb >= bil) {
                uint val = s.loadUnsigned(bil);
                if (b.remBits() < bil)
                    delete b;
                b.storeUnsigned(val, bil);
                m[iov_base] = b.toCell();
                nb -= bil;
                cnt += iov_len;
                if (uio_resid >= iov_len)
                    uio_resid -= iov_len;
                else
                    break;
            }
        }
    }
    function pwrite(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 fd, TvmCell pb, uint8 nbyte, uint16 offset) internal returns (uint8 error, uint16 cnt) {
        pb;
        if (nbyte > IOSIZE_MAX)
            return (EINVAL, 0);
        uio auio = uio([iovec(uint8(offset), nbyte)], 1, offset, nbyte, uio_seg.UIO_USERSPACE, uio_rw.UIO_WRITE);
        error = m.kern_pwritev(fdt, fd, auio, offset);
//        (error, cnt) = m.fo_write(fp, auio, pb, FOF_OFFSET);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
    }
    function dofilewrite(mapping (uint32 => TvmCell) m, file fp, uio auio, uint16 offset, uint8 flags) internal returns (uint8 error, uint16 retval) {
        uint16 cnt;
        auio.uio_rwo = uio_rw.UIO_WRITE;
        auio.uio_offset = offset;
        cnt = auio.uio_resid;
        (error, ) = m.fo_write(fp, auio, flags);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
        cnt -= auio.uio_resid;
        return (error, cnt);
    }
    function kern_pwritev(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 fd, uio auio, uint16 offset) internal returns (uint8 error) {
        file fp;
        (error, fp) = fdt.fget_write(fd);
        if (error > 0)
            return error;
        (error, )  = m.dofilewrite(fp, auio, offset, FOF_OFFSET);
    }
    function fo_write(mapping (uint32 => TvmCell) m, file fp, uio auio, uint8 flags) internal returns (uint8 error, uint16 cnt) {
        flags;
        error;
        cnt;
        TvmBuilder b;
        (iovec[] uio_iov, uint8 uio_iovcnt, , , , ) = auio.unpack();
//        if (uio_offset > 0)
//            s.skip()
        uint i;
        while (uio_iovcnt > 0) {
            (uint8 iov_base, uint8 iov_len) = uio_iov[i].unpack();
            uint16 bil = uint16(iov_len) * 8;
//            b.store(uio_iov[i].);
            TvmSlice s = m[iov_base].toSlice();
            (uint16 nb, ) = s.size();
            if (nb >= bil) {
                uint val = s.loadUnsigned(bil);
                b.storeUnsigned(val, bil);
            }
            uio_iovcnt--;
            i++;
//            iovec v = uio_iov[]
        }
        m[fp.f_data] = b.toCell();
    }
    function cgput(mapping (uint32 => TvmCell) m, fdescenttbl fdt, uint8 devfd, fsb f, cg cgp) internal returns (bool success) {
        (uint8 ec, uint16 cnt) = m.pwrite(fdt, devfd, abi.encode(cgp), f.cgsize, uint16(fsbtodb(f, cgtod(f, cgp.cg_cgx)) * (f.fsize / fsbtodb(f, 1))));
        ec;
        if (cnt == 0)
            return false;
        if (cnt != f.cgsize) {
            return false;
            //"short write to block device"
        }
        success = true;
    }
}