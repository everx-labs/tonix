pragma ton-solidity >= 0.64.0;
import "uio_h.sol";
import "proc_h.sol";
import "param.sol";
library libuio {

    uint16 constant UIO_MAXIOV = 1024;
    uint16 constant IOSIZE_MAX = 0xFFFF;
    using libuio for s_uio;
    uint8 constant EINVAL   = 22; // Invalid argument

    function uiomove_fromphys(s_uio uio, bytes[] pages, uint32 offset, uint32 n) internal returns (uint8 error) {
        s_thread td;// = curthread;
        s_iovec iov;
//        bytes cp;
        uint32 page_offset;
//        uint32 vaddr;
        uint32 cnt;
        bool mapped;
        // KASSERT(uio.uio_rw == UIO_READ || uio.uio_rw == UIO_WRITE, "uiomove_fromphys: mode");
        // KASSERT(uio.uio_segflg != UIO_USERSPACE || uio.uio_td == curthread, "uiomove_fromphys proc");
//        td.td_pflags |= libproc.TDP_DEADLKTREAT;
        mapped = false;
        while (n > 0 && uio.uio_resid > 0) {
            iov = uio.uio_iov[n - 1];
            cnt = iov.iov_len;
            if (cnt == 0) {
//              uio.uio_iov++;
                uio.uio_iovcnt--;
                continue;
            }
            if (cnt > n)
                cnt = n;
            page_offset = offset & param.PAGE_MASK;
            cnt = math.min(cnt, param.PAGE_SIZE - page_offset);
            if (uio.uio_segflg != uio_seg.UIO_NOCOPY) {
//              mapped = pmap_map_io_transient(ma[offset >> param.PAGE_SHIFT], vaddr, 1, true);
                //cp = vaddr + page_offset;
            }
            if (uio.uio_segflg == uio_seg.UIO_USERSPACE) {
                if (uio.uio_rw == uio_rwo.UIO_READ)
                    (error, pages) = copyout(pages[cnt], iov.iov_base, cnt);
                else
                    (error, pages) = copyin(pages[cnt], iov.iov_base, cnt);
                /*if (uio.uio_rw == uio_rwo.UIO_READ)
                    error = libcopy.copyout(cp, iov.iov_base, cnt);
                else
                    error = libcopy.copyin(iov.iov_base, cp, cnt);*/
                    if (error > 0) {
//                      if (mapped)
//                          pmap_unmap_io_transient(ma[offset >> param.PAGE_SHIFT], vaddr, 1, true);
//                      td.td_pflags &= ~TDP_DEADLKTREAT;
                        return error;
                    }
                    break;
            } else if (uio.uio_segflg == uio_seg.UIO_SYSSPACE) {
                    /*if (uio.uio_rw == uio_rwo.UIO_READ)
                        libcopy.bcopy(cp, iov.iov_base, cnt);
                    else
                        libcopy.bcopy(iov.iov_base, cp, cnt);
                    break;*/
            } else if (uio.uio_segflg == uio_seg.UIO_NOCOPY)
                break;
            if (mapped) {
//              pmap_unmap_io_transient(ma[offset >> param.PAGE_SHIFT], vaddr, 1, true);
                mapped = false;
            }
            iov.iov_base = iov.iov_base + cnt;
            iov.iov_len -= cnt;
            uio.uio_resid -= cnt;
            uio.uio_offset += cnt;
            offset += cnt;
            n -= cnt;
        }
//      if (mapped)
//          pmap_unmap_io_transient(ma[offset >> param.PAGE_SHIFT], vaddr, 1, true);
//        td.td_pflags &= ~libproc.TDP_DEADLKTREAT;
    }

    function uiomove_faultflag(s_uio uio, bytes cp, uint32 n, bool nofault) internal returns (uint8 error, string[] pages) {
        s_iovec iov;
        uint32 cnt;
//        uint newflags;
        uint pos;
        //KASSERT(uio.uio_rw == UIO_READ || uio.uio_rw == UIO_WRITE, "uiomove: mode");
        //KASSERT(uio.uio_segflg != UIO_USERSPACE || uio.uio_td == curthread, "uiomove proc");
        if (uio.uio_segflg == uio_seg.UIO_USERSPACE) {
//          newflags = TDP_DEADLKTREAT;
            if (nofault) {
                // Fail if a non-spurious page fault occurs.
//              newflags |= TDP_NOFAULTING | TDP_RESETSPUR;
            } else {
//              WITNESS_WARN(WARN_GIANTOK | WARN_SLEEPOK, NULL, "Calling uiomove()");
            }
//          save = curthread_pflags_set(newflags);
        } else {
//          KASSERT(nofault == 0, "uiomove: nofault");
        }
        while (n > 0 && uio.uio_resid > 0) {
            iov = uio.uio_iov[n - 1];
            cnt = iov.iov_len;
            if (cnt == 0) {
//              uio.uio_iov++;
                uio.uio_iovcnt--;
                continue;
            }
            if (cnt > n)
                cnt = n;
            if (uio.uio_segflg == uio_seg.UIO_USERSPACE) {
//                error = uio.uio_rw == uio_rwo.UIO_READ ? libcopy.copyout(cp, iov.iov_base, cnt) : libcopy.copyin(iov.iov_base, cp, cnt);
                (error, pages) = uio.uio_rw == uio_rwo.UIO_READ ? copyout(cp, iov.iov_base, cnt) : copyin(cp, iov.iov_base, cnt);
                if (error > 0)
                    return (error, pages);
                break;
            } else if (uio.uio_segflg == uio_seg.UIO_SYSSPACE) {
                /*if (uio.uio_rw == uio_rwo.UIO_READ)
                    pages.push(libcopy.bcopy(cp, cnt));
                else
                    pages.push(libcopy.bcopy(cp, cnt));
                break;*/
            } else if (uio.uio_segflg == uio_seg.UIO_NOCOPY) {
                break;
            }
            iov.iov_base = iov.iov_base + cnt;
            iov.iov_len -= cnt;
            uio.uio_resid -= cnt;
            uio.uio_offset += cnt;
            pos += cnt;
            n -= cnt;
        }
    }

    function cloneuio(s_uio uiop) internal returns (s_uio uio) {
	    uio = uiop;
    }
    function copyiniov(s_uio uio, s_iovec[] iovp, uint8 iovcnt) internal returns (uint8 error, s_iovec[] iov) {
        if (iovcnt > UIO_MAXIOV)
            return (error, iov);
        //uint16 iovlen = iovcnt;// * sizeof (struct iovec);
        //error = libcopy.copyin(iovp, iov, iovlen);
        iov = iovp;
        uio.uio_iov = iov;
        uio.uio_iovcnt = iovcnt;
        uio.uio_segflg = uio_seg.UIO_USERSPACE;
        uio.uio_offset = 0; // -1;
        uio.uio_resid = 0;
//        error = copyin(iovp, iov, iovlen);
        if (error > 0)
            delete iov;
    }
    function copyinuio(s_uio uio, s_iovec[] iov, uint8 iovcnt) internal returns (uint8 error) {
//        s_iovec[] iov;
//        s_uio uio;
//        uint16 iovlen;
        if (iovcnt > UIO_MAXIOV)
            return EINVAL;
//      iovlen = iovcnt * sizeof (struct iovec);
//      iov = s_iovec(uio + 1);
        //error = libcopy.copyin(iovp, iov, iovlen);
        //error = copyin(iovp, iov, iovlen);
//        iov = iovp;
        if (error > 0) {
            delete uio;
            return error;
        }
        uio.uio_iov = iov;
        uio.uio_iovcnt = iovcnt;
        uio.uio_segflg = uio_seg.UIO_USERSPACE;
        uio.uio_offset = 0; // -1;
        uio.uio_resid = 0;
        for (uint i = 0; i < iovcnt; i++) {
            if (iov[i].iov_len > IOSIZE_MAX - uio.uio_resid) {
                delete uio;
                return EINVAL;
            }
            uio.uio_resid += iov[i].iov_len;
//          iov++;
        }
    }
    function copyout_map(s_thread td, uint32 addr, uint32 sz) internal returns (uint8 error) {
        /*s_vmspace vms = td.td_proc.p_vmspace;
        // Map somewhere after heap in process memory.
        addr = round_page(vms.vm_daddr + lim_max(td, RLIMIT_DATA));
        // round size up to page boundary
        uint32 size = round_page(sz);
        if (size == 0)
            return EINVAL;
        error = vm_mmap_object(vms.vm_map, addr, size, VM_PROT_READ | VM_PROT_WRITE, VM_PROT_ALL, MAP_PRIVATE | MAP_ANON, NULL, 0, false, td);
        */
    }
    function copyout_unmap(s_thread td, uint32 addr, uint32 sz) internal returns (uint8) {
        /*
        if (sz == 0)
            return 0;
        vm_map_t map = td.td_proc.p_vmspace.vm_map;
        uint32 size = round_page(sz);
        if (vm_map_remove(map, addr, addr + size) != KERN_SUCCESS)
            return EINVAL;
        return 0;*/
    }
    function PHYS_PAGE_COUNT(uint32 len) internal returns (uint16) {
        return uint16(len / param.PAGE_SIZE + 1);
    }
    function physcopyin(s_uio uio, bytes src, uint32 dst, uint32 len) internal returns (uint8) {
        src = src;
        uint16 mlen = PHYS_PAGE_COUNT(len);
        string[] m;
        s_iovec[1] iov;
        //iov[0].iov_base = src;
        iov[0].iov_len = len;
        uio.uio_iov = iov;
        uio.uio_iovcnt = 1;
        uio.uio_offset = 0;
        uio.uio_resid = len;
        uio.uio_segflg = uio_seg.UIO_SYSSPACE;
        uio.uio_rw = uio_rwo.UIO_WRITE;
        for (uint i = 0; i < PHYS_PAGE_COUNT(len); i++){
            dst += param.PAGE_SIZE;
            m[i] = PHYS_TO_VM_PAGE(m, dst);
        }
        return uio.uiomove_fromphys(m, dst & param.PAGE_MASK, len);
    }
    function physcopyout(s_uio uio, uint32 src, bytes dst, uint32 len) internal returns (uint8) {
        //uint16 mlen = PHYS_PAGE_COUNT(len);
        string[] m;
        s_iovec[1] iov;
        iov[0].iov_base = src;
        iov[0].iov_len = len;
        uio.uio_iov = iov;
        uio.uio_iovcnt = 1;
        uio.uio_offset = 0;
        uio.uio_resid = len;
        uio.uio_segflg = uio_seg.UIO_SYSSPACE;
        uio.uio_rw = uio_rwo.UIO_READ;
        for (uint i = 0; i < PHYS_PAGE_COUNT(len); i++) {
            src += param.PAGE_SIZE;
            m[i] = PHYS_TO_VM_PAGE(m, src);
        }
        return uio.uiomove_fromphys(m, src & param.PAGE_MASK, len);
    }
    function uiomove(s_uio uio, bytes cp, uint32 n) internal returns (uint8, string[]) {
        return uio.uiomove_faultflag(cp, n, false);
    }
    function uiomove_frombuf(s_uio uio, bytes buf, uint16 buflen) internal returns (uint8, string[] res) {
        uint32 offset;
        uint32 n;
        if (uio.uio_offset < 0 || uio.uio_resid < 0 || (offset = uio.uio_offset) != uio.uio_offset)
            return (EINVAL, res);
        if (buflen <= 0 || offset >= buflen)
            return (0, res);
        if ((n = buflen - offset) > IOSIZE_MAX)
            return (EINVAL, res);
        return uio.uiomove(buf, n);
    }
    function uiomove_nofault(s_uio uio, bytes cp, uint32 n) internal returns (uint8, string[] pages) {
        return uio.uiomove_faultflag(cp, n, true);
    }

    function copyin(bytes uaddr, uint32 kaddr, uint32 len) internal returns (uint8, string[] pages) {
        pages.push(uaddr[kaddr : kaddr + len]);
    }
    function copyin_nofault(bytes uaddr, bytes kaddr, uint32 len) internal returns (uint8) {}
    function copyout(bytes kaddr, uint32 uaddr, uint32 len) internal returns (uint8, string[] pages) {
//        for (
            pages.push(kaddr[uaddr : uaddr + len]);
    }
    /*function readv(uint8 fd, s_iovec[], uint8 iovcnt) internal returns (uint32) {}
    function writev(uint8 fd, s_iovec[], uint8 iovcnt) internal returns (uint32) {}
    function preadv(uint8 fd, s_iovec[], uint8 iovcnt, uint32 off_t) internal returns (uint32) {}
    function pwritev(uint8 fd, s_iovec[], uint8 iovcnt, uint32 off_t) internal returns (uint32) {}*/
    function PHYS_TO_VM_PAGE(string[] pages, uint32 pa) internal returns (string) {
        uint pn = pa >> 16;
        if (pn < pages.length)
            return pages[pn];
    }
}