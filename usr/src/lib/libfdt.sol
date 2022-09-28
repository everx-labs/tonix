pragma ton-solidity >= 0.64.0;

import "filedesc_h.sol";
import "proc_h.sol";
import "cdev_h.sol";
import "uio_h.sol";
//import "liberr.sol";
import "libstat.sol";
import "dirent.sol";
import "path.sol";
import "libpoll.sol";
import "libdevice.sol";
import "libsignal.sol";
enum fddp {
    FDDUP_NORMAL,// dup() behavior
    FDDUP_FCNTL, // fcntl()-style errors
    FDDUP_FIXED, // Force fixed allocation
    FDDUP_LASTMODE
}

library libfdt {

    uint8 constant ENOENT   = 2; // No such file or directory
    uint8 constant EINTR    = 4; // Interrupted system call
    uint8 constant ENOSYS   = 78; // Function not implemented
    uint8 constant ERESTART = 1; // restart syscall
    uint8 constant EBADF    = 9; // Bad file descriptor
    uint8 constant ENODEV   = 19; // Operation not supported by device
    uint8 constant ENOTDIR  = 20; // Not a directory
    uint8 constant EINVAL   = 22; // Invalid argument
    uint8 constant ENOTTY   = 25; // Inappropriate ioctl for device
    uint8 constant EPIPE    = 32; // Broken pipe
    uint8 constant EAGAIN   = 35; // Resource temporarily unavailable
    uint8 constant EWOULDBLOCK = EAGAIN; // Operation would block

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

    uint8 constant DFLAG_PASSABLE = 0x01;
    uint8 constant DFLAG_SEEKABLE = 0x02; // seekable / nonsequential

    uint16 constant FREAD       = 0x0001;
    uint16 constant FWRITE      = 0x0002;
    uint16 constant O_RDONLY    = 0x0000; // open for reading only
    uint16 constant O_WRONLY    = 0x0001; // open for writing only
    uint16 constant O_RDWR      = 0x0002; // open for reading and writing
    uint16 constant O_ACCMODE   = 0x0003; // mask for above modes
    uint16 constant O_NONBLOCK  = 0x0004; // no delay
    uint16 constant O_APPEND    = 0x0008; // set append mode
    uint16 constant O_SHLOCK    = 0x0010; // open with shared file lock
    uint16 constant O_EXLOCK    = 0x0020; // open with exclusive file lock
    uint16 constant O_ASYNC     = 0x0040; // signal pgrp when data ready
    uint16 constant O_FSYNC     = 0x0080; // synchronous writes
    uint16 constant O_SYNC      = 0x0080; // POSIX synonym for O_FSYNC
    uint16 constant O_NOFOLLOW  = 0x0100; // don't follow symlinks
    uint16 constant O_CREAT     = 0x0200; // create if nonexistent
    uint16 constant O_TRUNC     = 0x0400; // truncate to zero length
    uint16 constant O_EXCL      = 0x0800; // error if already exists
    uint16 constant FHASLOCK    = 0x4000; // descriptor holds advisory lock
    uint16 constant O_NOCTTY    = 0x8000; // don't assign controlling terminal
    uint32 constant O_DIRECT    = 0x00010000;
    uint32 constant O_DIRECTORY = 0x00020000; // Fail if not directory
    uint32 constant O_EXEC      = 0x00040000; // Open for execute only
    uint32 constant O_SEARCH    = O_EXEC;
    uint32 constant FEXEC       = O_EXEC;
    uint32 constant FSEARCH     = O_SEARCH;
    uint32 constant O_TTY_INIT  = 0x00080000; // Restore default termios attributes
    uint32 constant O_CLOEXEC   = 0x00100000;
    uint32 constant O_VERIFY    = 0x00200000; // open only after verification
    uint32 constant O_PATH      = 0x00400000; // fd is only a path
    uint32 constant O_RESOLVE_BENEATH = 0x00800000; // Do not allow name resolution to walk out of cwd
    uint32 constant O_DSYNC     = 0x01000000; // POSIX data sync
    uint32 constant O_EMPTY_PATH = 0x02000000;
    uint32 constant FLASTCLOSE	= O_DIRECTORY;
    uint32 constant FREVOKE     = O_VERIFY;
    uint32 constant FOPENFAILED	= O_TTY_INIT;

    uint16 constant __SLBF	= 0x0001; // line buffered
    uint16 constant __SNBF	= 0x0002; // unbuffered
    uint16 constant __SRD	= 0x0004; // OK to read
    uint16 constant __SWR	= 0x0008; // OK to write
    uint16 constant __SRW	= 0x0010; // open for reading & writing
    uint16 constant __SEOF	= 0x0020; // found EOF
    uint16 constant __SERR	= 0x0040; // found error
    uint16 constant __SMBF	= 0x0080; // _bf._base is from malloc
    uint16 constant __SAPP	= 0x0100; // fdopen()ed in append mode
    uint16 constant __SSTR	= 0x0200; // this is an sprintf/snprintf string
    uint16 constant __SOPT	= 0x0400; // do fseek() optimization
    uint16 constant __SNPT	= 0x0800; // do not do fseek() optimization
    uint16 constant __SOFF	= 0x1000; // set iff _offset is in fact correct
    uint16 constant __SMOD	= 0x2000; // true => fgetln modified _p text
    uint16 constant __SALC	= 0x4000; // allocate string space dynamically
    uint16 constant __SIGN	= 0x8000; // ignore this file in _fwalk
    uint16 constant __S2OAP	= 0x0001; // O_APPEND mode is set

    uint8 constant F_DUPFD          = 0;  // duplicate file descriptor
    uint8 constant F_GETFD          = 1;  // get file descriptor flags
    uint8 constant F_SETFD          = 2;  // set file descriptor flags
    uint8 constant F_GETFL          = 3;  // get file status flags
    uint8 constant F_SETFL          = 4;  // set file status flags
    uint8 constant F_GETOWN         = 5;  // get SIGIO/SIGURG proc/pgrp
    uint8 constant F_SETOWN         = 6;  // set SIGIO/SIGURG proc/pgrp
    uint8 constant F_OGETLK         = 7;  // get record locking information
    uint8 constant F_OSETLK         = 8;  // set record locking information
    uint8 constant F_OSETLKW        = 9;  // F_SETLK; wait if blocked
    uint8 constant F_DUP2FD         = 10; // duplicate file descriptor to arg
    uint8 constant F_GETLK          = 11; // get record locking information
    uint8 constant F_SETLK          = 12; // set record locking information
    uint8 constant F_SETLKW         = 13; // F_SETLK; wait if blocked
    uint8 constant F_SETLK_REMOTE   = 14; // debugging support for remote locks
    uint8 constant F_READAHEAD      = 15; // read ahead
    uint8 constant F_RDAHEAD        = 16; // Darwin compatible read ahead
    uint8 constant F_DUPFD_CLOEXEC  = 17; // Like F_DUPFD, but FD_CLOEXEC is set
    uint8 constant F_DUP2FD_CLOEXEC = 18; // Like F_DUP2FD, but FD_CLOEXEC is set
    uint8 constant F_ADD_SEALS      = 19;
    uint8 constant F_GET_SEALS      = 20;
    uint8 constant F_ISUNIONSTACK   = 21; // Kludge for libc, don't use it.
    uint8 constant F_KINFO =		22;	// Return kinfo_file for this fd

    // Seals (F_ADD_SEALS, F_GET_SEALS).
    uint16 constant F_SEAL_SEAL	= 0x0001;		// Prevent adding sealings
    uint16 constant F_SEAL_SHRINK	= 0x0002;		// May not shrink
    uint16 constant F_SEAL_GROW	= 0x0004;		// May not grow
    uint16 constant F_SEAL_WRITE	= 0x0008;		// May not write

    // record locking flags (F_GETLK, F_SETLK, F_SETLKW)
    uint8 constant F_RDLCK	= 	1;	// shared or read lock
    uint8 constant F_UNLCK	= 	2;	// unlock
    uint8 constant F_WRLCK	= 	3;	// exclusive or write lock
    uint8 constant F_UNLCKSYS= 4;	// purge locks for a given system ID
    uint8 constant F_CANCEL	= 5	;	// cancel an async lock request

    uint16 constant F_WAIT		= 0x010;    // Wait until lock is granted
    uint16 constant F_FLOCK		= 0x020;    // Use flock(2) semantics for lock
    uint16 constant F_POSIX		= 0x040;    // Use POSIX semantics for lock
    uint16 constant F_REMOTE	= 0x080;    // Lock owner is remote NFS client
    uint16 constant F_NOINTR	= 0x100;    // Ignore signals when waiting
    uint16 constant F_FIRSTOPEN	= 0x200;    // First right to advlock file

    uint16 constant FRDAHEAD = O_CREAT;

    uint16 constant FAPPEND     = O_APPEND;   // kernel/compat
    uint16 constant FASYNC      = O_ASYNC;    // kernel/compat
    uint16 constant FFSYNC      = O_FSYNC;    // kernel
    uint32 constant FDSYNC      = O_DSYNC;    // kernel
    uint16 constant FNONBLOCK   = O_NONBLOCK; // kernel
    uint16 constant FNDELAY     = O_NONBLOCK; // compat
    uint16 constant O_NDELAY	= O_NONBLOCK; // compat

    // Generic file-descriptor ioctl's.
    uint8 constant FIOCLEX   = 1; // _IO('f', 1)          // set close on exec on fd
    uint8 constant FIONCLEX  = 2; // _IO('f', 2)          // remove close on exec
    uint8 constant FIONREAD  = 127; //_IOR('f', 127, int) // get # bytes to read
    uint8 constant FIONBIO   = 126; //_IOW('f', 126, int) // set/clear non-blocking i/o
    uint8 constant FIOASYNC  = 125; //_IOW('f', 125, int) // set/clear async i/o
    uint8 constant FIOSETOWN = 124; //_IOW('f', 124, int) // set owner
    uint8 constant FIOGETOWN = 123; //_IOR('f', 123, int) // get owner
    uint8 constant FIODTYPE  = 122; //_IOR('f', 122, int) // get d_flags type part
    uint8 constant FIOGETLBA = 121; //_IOR('f', 121, int) // get start blk #

    // file descriptor flags (F_GETFD, F_SETFD)
    uint8 constant FD_CLOEXEC =	1;       // close-on-exec flag
    uint8 constant FDDUP_FLAG_CLOEXEC = 0x1;// Atomically set UF_EXCLOSE.
    uint8 constant UF_EXCLOSE   = 0x01;	 // auto-close on exec
//    uint8 constant F_POSIX      = 0x040; // Use POSIX semantics for lock
    uint16 constant INT_MAX     = 0xFFFF;

    uint32 constant FMASK      = FREAD | FWRITE | FAPPEND | FASYNC | FFSYNC | FDSYNC | FNONBLOCK | O_DIRECT | FEXEC | O_PATH; // bits to save after open
    uint32 constant FCNTLFLAGS = FAPPEND | FASYNC | FFSYNC | FDSYNC | FNONBLOCK | FRDAHEAD | O_DIRECT; // bits settable by fcntl(F_SETFL, ...)

    uint8 constant FOF_OFFSET	 = 0x01;	// Use the offset in uio argument
    uint8 constant FOF_NOLOCK	 = 0x02;	// Do not take FOFFSET_LOCK
    uint8 constant FOF_NEXTOFF_R = 0x04;	// Also update f_nextoff[UIO_READ]
    uint8 constant FOF_NEXTOFF_W = 0x08;	// Also update f_nextoff[UIO_WRITE]
    uint8 constant FOF_NOUPDATE	 = 0x10;	// Do not update f_offset

    uint8 constant POSIX_FADV_NORMAL	= 0; // no special treatment
    uint8 constant POSIX_FADV_RANDOM	= 1; // expect random page references
    uint8 constant POSIX_FADV_SEQUENTIAL= 2; // expect sequential page references
    uint8 constant POSIX_FADV_WILLNEED	= 3; // will need these pages
    uint8 constant POSIX_FADV_DONTNEED	= 4; // dont need these pages
    uint8 constant POSIX_FADV_NOREUSE	= 5; // access data only once

    uint64 constant cap_fcntl_rights = uint64(1) << 15;//libcap.CAP_FCNTL;
    uint64 constant cap_no_rights = 0;
    uint32 constant nofileops = 0;
    uint32 constant badfileops = 1;
    uint32 constant path_fileops = 2;
    uint32 constant vnops = 3;
    uint32 constant socketops = 4;

    uint8 constant NDFILE = 20;
    uint8 constant NDSLOTSIZE = 4;
    uint8 constant CHAR_BIT = 8;
    uint8 constant NDENTRIES = NDSLOTSIZE * CHAR_BIT;

    function NDSLOT(uint32 x) internal returns (uint32) {
        return x / NDENTRIES;
    }

    function NDBIT(uint32 x) internal returns (uint32) {
        return uint32(1) << (x % NDENTRIES);
    }

    function NDSLOTS(uint32 x) internal returns (uint32) {
        return (x + NDENTRIES - 1) / NDENTRIES;
    }

//    struct fdescenttbl0 {
//        uint8 fdt_nfiles;
//        s_filedescent[NDFILE] fdt_ofiles;
//    }
//
//    struct filedesc0 {
//        s_filedesc fd_fd;
////      SLIST_HEAD(, freetable) fd_free;
//        fdescenttbl0 fd_dfiles;
////      NDSLOTTYPE fd_dmap[NDSLOTS(NDFILE)];
//    }

// File Descriptor pseudo-device driver (/dev/fd/).
// Opening minor device N dup()s the file (if any) connected to file descriptor N belonging to the calling process.  Note that this driver
// consists of only the ``open()'' routine, because all subsequent references to this file will be direct to the other driver.
// XXX: we could give this one a cloning event handler if necessary.

    function fdopen(s_cdev dev, uint16 mode, uint8 ftype, s_thread td) internal returns (uint8) { // 3926427505
    	td.td_dupfd = libdevice.dev2unit(dev);
    	return ENODEV;
    }

//    struct fildesc_cdevsw = {
//    	.d_version = D_VERSION,
//    	.d_open =	fdopen,
//    	.d_name =	"FD",
//    }

    function fildesc_drvinit(bytes) internal { // 1509197048
        //s_cdevsw fildesc_cdevsw;
        //fildesc_cdevsw.d_open = 3926427505;//fdopen;
        //fildesc_cdevsw.d_name = "FD";
        uint32 fildesc_cdevsw;
    	s_cdev dev;
//        s_ucred cr;
        uint8 ec;
    	(ec, dev) = libdevice.make_dev_credf(libdevice.MAKEDEV_ETERNAL, fildesc_cdevsw, 0, 0, conf.UID_ROOT, conf.GID_WHEEL, 438, "fd/0");
//    	make_dev_alias(dev, "stdin");
    	(ec, dev) = libdevice.make_dev_credf(libdevice.MAKEDEV_ETERNAL, fildesc_cdevsw, 1, 0, conf.UID_ROOT, conf.GID_WHEEL, 438, "fd/1");
//    	make_dev_alias(dev, "stdout");
    	(ec, dev) = libdevice.make_dev_credf(libdevice.MAKEDEV_ETERNAL, fildesc_cdevsw, 2, 0, conf.UID_ROOT, conf.GID_WHEEL, 438, "fd/2");
//    	make_dev_alias(dev, "stderr");
    }

    function fdfree(s_filedesc fdp, uint8 fd) internal { // 4166525885
    	s_filedescent fde = fdp.fd_files.fdt_ofiles[fd];
    	delete fde.fde_file;
    	fdefree_last(fde);
    	fdunused(fdp, fd);
    }
    function fdefree_last(s_filedescent fde) internal {
//    	filecaps_free(fde.fde_caps);
        delete fde.fde_caps;
    }
    // Mark a file descriptor as used.
    function fdused_init(s_filedesc fdp, uint8 fd) internal {
    //	KASSERT(!fdisused(fdp, fd), ("fd=%d is already used", fd));
//    	fdp.fd_map[NDSLOT(fd)] |= NDBIT(fd);
        fdp.fd_map |= NDBIT(fd);
    }

    function fdused(s_filedesc fdp, uint8 fd) internal {
    	fdused_init(fdp, fd);
    	if (fd == fdp.fd_freefile)
    		fdp.fd_freefile++;
    }

    // Mark a file descriptor as unused.
    function fdunused(s_filedesc fdp, uint8 fd) internal { // 3188257943
    	//KASSERT(fdisused(fdp, fd), ("fd=%d is already unused", fd));
    	//KASSERT(fdp->fd_ofiles[fd].fde_file == NULL, ("fd=%d is still in use", fd));
//    	fdp.fd_map[NDSLOT(fd)] &= ~NDBIT(fd);
    	fdp.fd_map &= ~NDBIT(fd);
    	if (fd < fdp.fd_freefile)
    		fdp.fd_freefile = fd;
    }

    function closef(s_file fp, s_thread td) internal returns (uint8) { // 305215061
    	s_vnode vp;
    	s_filedesc_to_leader fdtol;
    	s_filedesc fdp;
    //	MPASS(td != NULL);
    	// POSIX record locking dictates that any close releases ALL locks owned by this process.  This is handled by setting
    	// a flag in the unlock to free ONLY locks obeying POSIX semantics, and not to free BSD-style file locks.
    	// If the descriptor was in a message, POSIX-style locks aren't passed with the descriptor, and the thread pointer
    	// will be NULL.  Callers should be careful only to pass a NULL thread pointer when there really is no owning
    	// context that might have locks, or the locks will be leaked.
    	if (fp.f_type == DTYPE_VNODE) {
//    		vp = fp.f_vnode;
//    		if ((td.td_proc.p_leader.p_flag & P_ADVLOCK) > 0) {
//    			lf.l_whence = SEEK_SET;
//    			lf.l_start = 0;
//    			lf.l_len = 0;
//    			lf.l_type = F_UNLCK;
////    			VOP_ADVLOCK(vp, td.td_proc.p_leader, F_UNLCK, lf, F_POSIX);
//    		}
//    		fdtol = td.td_proc.p_fdtol;
    		if (fdtol.fdl_leader > 0) {
    			// Handle special case where file descriptor table is shared between multiple process leaders.
    			fdp = td.td_proc.p_fd.fd_fd;
//    			for (fdtol = fdtol.fdl_next; fdtol != td.td_proc.p_fdtol; fdtol = fdtol.fdl_next) {
//    				if ((fdtol.fdl_leader.p_flag & libproc.P_ADVLOCK) == 0)
//    					continue;
    				fdtol.fdl_holdcount++;
//    				lf.l_whence = SEEK_SET;
//    				lf.l_start = 0;
//    				lf.l_len = 0;
//    				lf.l_type = F_UNLCK;
//    				vp = fp.f_vnode;
//    				VOP_ADVLOCK(vp, fdtol.fdl_leader, F_UNLCK, lf, F_POSIX);
    				fdtol.fdl_holdcount--;
    				if (fdtol.fdl_holdcount == 0 && fdtol.fdl_wakeup > 0) {
    					fdtol.fdl_wakeup = 0;
//    					wakeup(fdtol);
    				}
//    			}
    		}
    	}
    	return fdrop(fp, td);
    }

    // Build a new filedesc structure from another. If fdp is not NULL, return with it shared locked.
    function fdinit() internal returns (s_filedesc newfdp) { // 3502217490
    	filedesc0 newfdp0;
    //	newfdp0 = uma_zalloc(filedesc0_zone, M_WAITOK | M_ZERO);
    	newfdp = newfdp0.fd_fd;
    	// Create the file descriptor table.
    	newfdp.fd_refcnt = 1;
//    	newfdp.fd_holdcnt = 1;
//    	newfdp.fd_map = newfdp0.fd_dmap;
//    	newfdp.fd_files = newfdp0.fd_dfiles;
    	newfdp.fd_files.fdt_nfiles = NDFILE;
    	return newfdp;
    }

    function fdclose(s_thread td, s_file fp, uint8 idx) internal { // 4282731538
    	s_filedesc fdp = td.td_proc.p_fd.fd_fd;
    	if (fdp.fd_files.fdt_ofiles[idx].fde_file.f_vnode == fp.f_vnode) {
    		fdfree(fdp, idx);
    		fdrop(fp, td);
    	}
    }

    function finit(s_file fp, uint16 flag, uint8 ftype, bytes data, uint32 ops) internal { // 3143355715
    	fp.f_data = data;
    	fp.f_flag = flag;
    	fp.f_type = ftype;
    	fp.f_ops = ops;
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
//        (error, buf) = fp.fo_read(auio, td.td_ucred, flags, td);
        (error, buf) = fo_read(fp, auio, td.td_ucred, flags, td);
        if (error > 0) {
            if (auio.uio_resid != cnt && (error == ERESTART || error == EINTR || error == EWOULDBLOCK))
                error = 0;
        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }

    function fo_read(s_file fp, s_uio auio, s_ucred uc, uint16 flags, s_thread td) internal returns (uint8, bytes buf) { // 2798694612
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
    function dofilewrite(s_thread td, uint8 fd, s_file fp, s_uio auio, uint32 offset, uint16 flags) internal returns (uint8 error, s_file fpp) {
        fpp = fp;
        auio.uio_rw = uio_rwo.UIO_WRITE;
        auio.uio_td = td.td_tid;
        auio.uio_offset = offset;
        uint32 cnt = auio.uio_resid;
//        if ((error = fpp.fo_write(auio, td.td_ucred, flags, td)) > 0) {
            if (auio.uio_resid != cnt && (error == ERESTART || error == EINTR || error == EWOULDBLOCK))
                error = 0;
            // Socket layer is responsible for issuing SIGPIPE.
            if (fp.f_type != DTYPE_SOCKET && error == EPIPE) {
                libsignal.tdsignal(td, libsignal.SIGPIPE);
            }
//        }
        cnt -= auio.uio_resid;
        td.td_retval = cnt;
    }
    function fo_write(s_file fp, s_uio auio, s_ucred uc, uint16 flags, s_thread td) internal returns (uint8) { // 1237979137
        bytes buf;
        for (s_iovec v: auio.uio_iov)
            buf.append(v.iov_data);
        fp.f_data.append(buf);
    }
    function badfo_chown(s_file, uint16, uint16, s_ucred, s_thread) internal returns (uint8) { // 1887369647
	    return EBADF;
    }
    function badfo_chmod(s_file, uint16, uint16, s_ucred, s_thread) internal returns (uint8) { // 1946356014
	    return EBADF;
    }
    function badfo_sendfile(s_file, uint8, s_uio, s_uio, uint32, uint32, uint32, uint16, s_thread) internal returns (uint8) { // 3507474671
	    return EBADF;
    }
    function badfo_readwrite(s_file, s_uio, s_ucred, uint16, s_thread) internal returns (uint8) { // 3648250732
	    return EBADF;
    }

    function badfo_truncate(s_file, uint32, s_ucred, s_thread) internal returns (uint8) { // 3322050532
	    return EINVAL;
    }
    function badfo_ioctl(s_file, uint8, uint32, s_ucred, s_thread) internal returns (uint8) { // 361904981
	    return EBADF;
    }
    function path_poll(s_file, uint16, s_ucred, s_thread) internal returns (uint8) { // 1228135550
	    return libpoll.POLLNVAL;
    }
    function path_close(s_file fp, s_thread) internal returns (uint8) { // 2175320012
        if (fp.f_type == DTYPE_VNODE)
//        MPASS(fp.f_type == DTYPE_VNODE);
        fp.f_ops = badfileops;
//        vrele(fp.f_vnode);
        return 0;
    }

    function badfo_poll(s_file, uint16, s_ucred, s_thread) internal returns (uint8) { // 3913204049
	    return 0;
    }

    function badfo_close(s_file, s_thread) internal returns (uint8) { // 1388140539
        return 0;
    }

    function badfo_stat(s_file, s_stat, s_ucred) internal returns (uint8) { // 1050093750
        return EBADF;
    }

    function get_fops(uint32 fps) internal returns (fops fo) { // 3124712959
        if (fps == badfileops) fo.fo_read = 3648250732;
    }

    function get_fileops(uint32 fops) internal returns (fileops fo) { // 3124712959
//        if (fops == nofileops) return get_bad_fileops();
//        if (fops == badfileops) return get_bad_fileops();
//        if (fops == path_fileops) return get_path_fileops();
        if (fops == vnops) return get_path_fileops();
//        if (fops == socketops) return get_path_fileops();
        return get_bad_fileops();
    }
    function get_bad_fileops() internal returns (fileops fo) { // 2126758752
        fo.fo_read = 3648250732;//badfo_readwrite;
        fo.fo_write = 3648250732;//badfo_readwrite;
        fo.fo_truncate = 3322050532;//badfo_truncate;
        fo.fo_ioctl = 361904981;//badfo_ioctl;
        fo.fo_poll = 3913204049;//badfo_poll;
//      fo.fo_kqfilter = badfo_kqfilter;
        fo.fo_stat = 1050093750;//badfo_stat;
        fo.fo_close = 1388140539;//badfo_close;
        fo.fo_chmod = 1946356014;//badfo_chmod;
        fo.fo_chown = 1887369647;//badfo_chown;
        fo.fo_sendfile = 3507474671;//badfo_sendfile;
//      fo.fo_fill_kinfo = badfo_fill_kinfo;
    }

    function get_path_fileops() internal returns (fileops fo) { // 3131174780
        fileops bad_fo = get_bad_fileops();
        fo = bad_fo;
        fo.fo_poll = 1228135550;//path_poll;
//        fo.fo_kqfilter = vn_kqfilter_opath;
//        fo.fo_stat = vn_statfile;
        fo.fo_close = 2175320012;//path_close;
        fo.fo_flags = DFLAG_PASSABLE;
//      fo.fo_read = 3648250732;//badfo_readwrite;
//      fo.fo_write = 3648250732;//badfo_readwrite;
//      fo.fo_truncate = 3322050532;//badfo_truncate;
//      fo.fo_ioctl = 361904981;//badfo_ioctl;
//      fo.fo_poll = path_poll;
//      fo.fo_kqfilter = vn_kqfilter_opath;
//      fo.fo_stat = vn_statfile;
//      fo.fo_close = path_close;
//      fo.fo_chmod = badfo_chmod;
//      fo.fo_chown = badfo_chown;
//      fo.fo_sendfile = badfo_sendfile;
//      fo.fo_fill_kinfo = vn_fill_kinfo;
//        fo.fo_flags = DFLAG_PASSABLE;
    }

    // See the comments in fget_unlocked_seq for an explanation of how this works.
    // This is a simplified variant which bails out to the aforementioned routine if anything goes wrong. In practice this only happens when userspace is
    // racing with itself.
    function fget_unlocked(s_thread td, uint8 fd, uint64) internal returns (uint8, s_file fp) {
//      seqc_t seq;
//      uint64 haverights;
        s_filedesc fdp = td.td_proc.p_fd.fd_fd;
        s_fdescenttbl fdt = fdp.fd_files;
        if (fd >= fdt.fdt_nfiles) {
            return (EBADF, fp);
        }
//      seq = seqc_read_notmodify(fd_seqc(fdt, fd));
        s_filedescent fde = fdt.fdt_ofiles[fd];
//      haverights = cap_rights_fde_inline(fde);
//      fp = fde.fde_file;
        fp = fdt.fdt_ofiles[fd].fde_file;
//      if ((fp == NULL))
//          goto out_fallback;
//      if ((cap_check_inline_transient(haverights, needrightsp)))
//          goto out_fallback;
//      if ((!refcount_acquire_if_not_zero(fp.f_count)))
//          goto out_fallback;
        // Use an acquire barrier to force re-reading of fdt so it is refreshed for verification.
//        fdt = fdp.fd_files;
//      if ((fp != fdt.fdt_ofiles[fd].fde_file))
//          goto out_fdrop;
//        fpp = fp;
//        return (0, fpp);
    //out_fdrop:
//      fdrop(fp, td);
    //out_fallback:
    //  *fpp = NULL;
    //  return (fget_unlocked_seq(td, fd, needrightsp, fpp, NULL));
    }

    function fget_noref(s_filedesc fdp, uint8 fd) internal returns (s_file) {
        if (fd < fdp.fd_files.fdt_nfiles)
            return fdp.fd_files.fdt_ofiles[fd].fde_file;
    }
    function fdeget_noref(s_filedesc fdp, uint8 fd) internal returns (s_filedescent fde) {
        if (fd < fdp.fd_files.fdt_nfiles) {
            fde = fdp.fd_files.fdt_ofiles[fd];
            if (fde.fde_file.f_type > 0)
                return fde;
        }
    }

    function fget_read(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) { // 3816287562
        return _fget(td, fd, FREAD, rightsp);
    }

    function fget_write(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) { // 396819964
        return _fget(td, fd, FWRITE, rightsp);
    }

    function fget(s_thread td, uint8 fd, uint64 rightsp) internal returns (uint8 error, s_file fp) {
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

    function kern_dup(s_thread td, fddp mode, uint8 flags, uint8 old, uint8 dnew) internal returns (uint8 error) {
        uint8 maxfd;
        s_proc p = td.td_proc;
        s_filedesc fdp = td.td_proc.p_fd.fd_fd;
        //MPASS((flags & ~(FDDUP_FLAG_CLOEXEC)) == 0);
        //MPASS(mode < FDDUP_LASTMODE);
        // Verify we have a valid descriptor to dup from and possibly to dup to. Unlike dup() and dup2(), fcntl()'s F_DUPFD should
        // return EINVAL when the new descriptor is out of bounds.
        if (old < 0)
            return EBADF;
        if (dnew < 0)
            return mode == fddp.FDDUP_FCNTL ? EINVAL : EBADF;
//          maxfd = getmaxfd(td);
        if (dnew >= maxfd)
            return mode == fddp.FDDUP_FCNTL ? EINVAL : EBADF;
        error = EBADF;
        fget_noref(fdp, old);
//      if ( == NULL)
        if (mode == fddp.FDDUP_FIXED && old == dnew) {
            td.td_retval = dnew;
            if ((flags & FDDUP_FLAG_CLOEXEC) > 0)
                fdp.fd_files.fdt_ofiles[dnew].fde_flags |= UF_EXCLOSE;
            return 0;
        }
        s_filedescent oldfde = fdp.fd_files.fdt_ofiles[old];
        s_file oldfp = oldfde.fde_file;
        // If the caller specified a file descriptor, make sure the file table is large enough to hold it, and grab it.  Otherwise, just
        // allocate a new descriptor the usual way.
        if (mode == fddp.FDDUP_NORMAL || mode == fddp.FDDUP_FCNTL) {
            //if ((error = fdalloc(td, dnew, dnew)) > 0) {
                fdrop(oldfp, td);
  //             goto unlock;
//           }
        } else if (mode == fddp.FDDUP_FIXED) {
            if (dnew >= fdp.fd_files.fdt_nfiles) {
                // The resource limits are here instead of e.g. fdalloc(), because the file descriptor table may be shared between processes, so we
                // can't really use racct_add()/racct_sub().  Instead of counting the number of actually allocated descriptors, just put the limit on the size
                // of the file descriptor table.
//              fdgrowtable_exp(fdp, new + 1);
            }
    //      if (!fdisused(fdp, dnew))
//              fdused(fdp, dnew);
            return error;
//          KASSERT(0, "%s unsupported mode %d", __func__, mode);
        }
//      KASSERT(old != new, "new fd is same as old");
        // Refetch oldfde because the table may have grown and old one freed
        oldfde = fdp.fd_files.fdt_ofiles[old];
        //KASSERT(oldfp == oldfde.fde_file, "fdt_ofiles shift from growth observed at fd %d", old);
        s_filedescent newfde = fdp.fd_files.fdt_ofiles[dnew];
        s_file delfp = newfde.fde_file;
        // Duplicate the source descriptor.
//      fde_copy(oldfde, newfde);
        newfde = oldfde;
        if ((flags & FDDUP_FLAG_CLOEXEC) > 0)
            newfde.fde_flags = oldfde.fde_flags | UF_EXCLOSE;
        else
            newfde.fde_flags = oldfde.fde_flags & ~UF_EXCLOSE;
        td.td_retval = dnew;
        error = 0;
//      if (delfp > 0) {
  //        closefp(fdp, dnew, delfp, td, true, false);
//      } else {
//      }
    }

    function FFLAGS(uint32 oflags) internal returns (uint32) {
        return (oflags & O_EXEC) > 0 ? oflags : oflags + 1;
    }

    function OFLAGS(uint32 fflags) internal returns (uint32) {
        return (fflags & (O_EXEC | O_PATH)) > 0 ? fflags : fflags - 1;
    }

    function fdrop(s_file fp, s_thread td) internal returns (uint8 error) {
//      if (fp.count-- == 0)
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

    function fo_ioctl(s_file, uint8, bytes, s_ucred, s_thread) internal returns (uint8) {
	    return ENOTTY;
    }

    function fget_fcntl(s_thread td, uint8 fd, uint64 rightsp, uint8) internal returns (uint8 error, s_file fp) {
    	return fget_unlocked(td, fd, rightsp);
    }

    function kern_fcntl(s_thread td, uint8 fd, uint8 cmd, uint8 arg) internal returns (uint8 error) {
        s_file fp;
//      s_file fp2;
        s_filedescent fde;
//      s_vnode vp;
//      s_mount mp;
        uint8 tmp;
        uint32 ttmp;
//      uint64 bsize;
//      uint32 foffset;
        error = 0;
        uint16 flg = F_POSIX;
        s_proc p = td.td_proc;
        s_filedesc fdp = p.p_fd.fd_fd;
        if (cmd == F_DUPFD) {
            tmp = arg;
            error = kern_dup(td, fddp.FDDUP_FCNTL, 0, fd, tmp);
        } else if (cmd == F_DUPFD_CLOEXEC) {
            tmp = arg;
            error = kern_dup(td, fddp.FDDUP_FCNTL, FDDUP_FLAG_CLOEXEC, fd, tmp);
        } else if (cmd == F_DUP2FD) {
            tmp = arg;
            error = kern_dup(td, fddp.FDDUP_FIXED, 0, fd, tmp);
        } else if (cmd == F_DUP2FD_CLOEXEC) {
            tmp = arg;
            error = kern_dup(td, fddp.FDDUP_FIXED, FDDUP_FLAG_CLOEXEC, fd, tmp);
        } else if (cmd == F_GETFD) {
            error = EBADF;
            fde = fdeget_noref(fdp, fd);
            if (fde.fde_file.f_type > 0) {
                td.td_retval = (fde.fde_flags & UF_EXCLOSE) > 0 ? FD_CLOEXEC : 0;
                error = 0;
            }
        } else if (cmd == F_SETFD) {
            error = EBADF;
            fde = fdeget_noref(fdp, fd);
            if (fde.fde_file.f_type > 0) {
                fde.fde_flags = (fde.fde_flags & ~UF_EXCLOSE) | ((arg & FD_CLOEXEC) > 0 ? UF_EXCLOSE : 0);
                error = 0;
            }
        } else if (cmd == F_GETFL) {
            (error, fp) = fget_fcntl(td, fd, cap_fcntl_rights, F_GETFL);
            if (error > 0)
                return error;
            td.td_retval = OFLAGS(fp.f_flag);
            fdrop(fp, td);
        } else if (cmd == F_SETFL) {
            (error, fp) = fget_fcntl(td, fd, cap_fcntl_rights, F_SETFL);
            if (error > 0)
                return error;
            if (fp.f_ops == path_fileops) {
                fdrop(fp, td);
                error = EBADF;
            }
            do {
                ttmp = flg = fp.f_flag;
                ttmp &= ~FCNTLFLAGS;
                ttmp |= FFLAGS(arg & ~O_ACCMODE) & FCNTLFLAGS;
            } while (fp.f_flag == flg);
            ttmp = fp.f_flag & FNONBLOCK;
            error = fo_ioctl(fp, FIONBIO, "", td.td_ucred, td);
            if (error > 0) {
                fdrop(fp, td);
                return error;
            }
            ttmp = fp.f_flag & FASYNC;
            error = fo_ioctl(fp, FIOASYNC, "", td.td_ucred, td);
            if (error == 0) {
                fdrop(fp, td);
                return error;
            }
            fp.f_flag &= ~FNONBLOCK;
            tmp = 0;
            fo_ioctl(fp, FIONBIO, "", td.td_ucred, td);
            fdrop(fp, td);
        } else if (cmd == F_GETOWN) {
            (error, fp) = fget_fcntl(td, fd, cap_fcntl_rights, F_GETOWN);
            if (error > 0)
                return error;
            error = fo_ioctl(fp, FIOGETOWN, "", td.td_ucred, td);
            if (error == 0)
                td.td_retval = tmp;
            fdrop(fp, td);
        } else if (cmd == F_SETOWN) {
            (error, fp) = fget_fcntl(td, fd, cap_fcntl_rights, F_SETOWN);
            if (error > 0)
                return error;
            tmp = arg;
            error = fo_ioctl(fp, FIOSETOWN, "", td.td_ucred, td);
            fdrop(fp, td);
        } else if (cmd == F_RDAHEAD) {
//          arg = arg ? 128 * 1024: 0;
            // FALLTHROUGH
        } else if (cmd == F_READAHEAD) {
            (error, fp) = fget_unlocked(td, fd, cap_no_rights);
            if (error > 0)
                return error;
            if (fp.f_type != DTYPE_VNODE || fp.f_ops == path_fileops) {
                fdrop(fp, td);
                return EBADF;
            }
//            vp = fp.f_vnode;
            if (fp.f_type != uint8(vtype.VREG)) {
                fdrop(fp, td);
                return ENOTTY;
            }
//          error = vn_lock(vp, LK_EXCLUSIVE);
            if (error > 0) {
                fdrop(fp, td);
                return error;
            }
            if (arg >= 0) {
//              bsize = fp.f_vnode.v_mount.mnt_stat.f_iosize;
//              arg = math.min(arg, INT_MAX - bsize + 1);
//              fp.f_seqcount[UIO_READ] = MIN(IO_SEQMAX, (arg + bsize - 1) / bsize);
                fp.f_flag |= FRDAHEAD;
            } else {
                fp.f_flag &= ~FRDAHEAD;
            }
            fdrop(fp, td);
            return error;
        } else {
            return EINVAL;
        }
        return error;
    }

    // Return the (stdio) flags for a given mode.  Store the flags to be passed to an _open() syscall through *optr. Return 0 on error.
    function __sflags(string mode) internal returns (uint16 ret, uint32 optr) {
        uint32 m;
        uint32 o;
        uint8 known;
        for (byte b: mode) {
            if (b == 'r') { // open for reading
                ret = __SRD;
                m = O_RDONLY;
                o = 0;
                break;
            } else if (b == 'w') { // open for writing
               	ret = __SWR;
               	m = O_WRONLY;
               	o = O_CREAT | O_TRUNC;
                break;
            } else if (b == 'a') {	// open for appending
                ret = __SWR;
                m = O_WRONLY;
                o = O_CREAT | O_APPEND;
                break;
            } else { // illegal mode
//              errno = err.EINVAL;
                return (0, 0);
            }
        }
        for (byte b: mode) {
            known = 1;
            if (b == 'b') // 'b' (binary) is ignored
                break;
            else if (b == '+') { // [rwa][b]\+ means read and write
                ret = __SRW;
                m = O_RDWR;
                break;
            } else if (b == 'x') { // 'x' means exclusive (fail if the file exists)
                o |= O_EXCL;
                break;
            } else if (b == 'e') { // set close-on-exec
                o |= O_CLOEXEC;
                break;
            } else if (b == 'v') { // verify
                o |= O_VERIFY;
                break;
            } else {
                known = 0;
                break;
            }
        }
        if ((o & O_EXCL) > 0 && m == O_RDONLY) {
//       	errno = err.EINVAL;
            return (0, 0);
        }
        optr = m | o;
    }

//    using xio for s_of;
//    using sbuf for s_sbuf;
    uint8 constant STDIN_FILENO  = 0;
    uint8 constant STDOUT_FILENO = 1;
    uint8 constant STDERR_FILENO = 2;
    uint8 constant ERRNO_FILENO  = 3;

    uint16 constant SYS_open   = 5;
    uint16 constant SYS_close  = 6;
    uint16 constant SYS_chdir  = 12;
    uint16 constant SYS_fchdir = 13;
    uint16 constant SYS_access = 33;
    uint16 constant SYS_dup    = 41;
    uint16 constant SYS_umask  = 60;
    uint16 constant SYS_getdtablesize = 89;
    uint16 constant SYS_dup2   = 90;
    uint16 constant SYS_freebsd11_getdents  = 272;
    uint16 constant SYS___getcwd    = 326;
    uint16 constant SYS_openat             = 499;
    uint16 constant SYS_freebsd12_closefrom = 509;
    uint16 constant SYS_getdirentries      = 554;
    uint16 constant SYS_close_range        = 575;

    using libfdt for s_thread;
    using libfdt for s_of[];
    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS___getcwd) return 0;
        else if (n == SYS_chdir || n == SYS_fchdir || n == SYS_close || n == SYS_freebsd11_getdents || n == SYS_getdirentries || n == SYS_dup || n == SYS_freebsd12_closefrom || n == SYS_umask)
            return 1;
        else if (n == SYS_open || n == SYS_access || n == SYS_close_range)
            return 2;
    }

    function syscall_ids() internal returns (uint16[]) {
        return [SYS_open, SYS_chdir, SYS_fchdir, SYS___getcwd, SYS_close, SYS_access, SYS_freebsd11_getdents, SYS_getdirentries, SYS_dup, SYS_freebsd12_closefrom, SYS_close_range, SYS_umask];
    }

    function syscall_name(uint16 number) internal returns (string) {
        if (number == SYS_open) return "open";
        if (number == SYS_chdir) return "chdir";
        if (number == SYS_fchdir) return "fchdir";
        if (number == SYS___getcwd) return "__getcwd";
        if (number == SYS_close) return "close";
        if (number == SYS_access) return "access";
        if (number == SYS_freebsd11_getdents) return "getdents";
        if (number == SYS_getdirentries) return "getdirentries";
        if (number == SYS_dup) return "dup";
        if (number == SYS_freebsd12_closefrom) return "closefrom";
        if (number == SYS_close_range) return "close_range";
        if (number == SYS_umask) return "umask";
    }
    function _get_dirent(s_dirent[] des, string sp) internal returns (s_dirent) {
        for (s_dirent de: des) {
            if (de.d_name == sp)
                return de;
        }
    }
    function chdir(s_thread t) internal returns (s_of cdir) {
        return t.td_proc.p_pd.pwd_cdir;
    }
    function open(s_thread t, string sp, uint16 mode) internal returns (uint8 ec, uint16 rv) {
        bool abspath = sp.substr(0, 1) == "/";
        if (abspath) {
            uint fd = fdfetch(t.td_proc.p_fd.fdt_ofiles, sp);
            if (fd > 0) {
                rv = t.td_proc.p_fd.fdt_ofiles[fd - 1].file;
                return (ec, rv);
            }
            (string sdir, string snotdir) = path.dir(sp);
//            (ec, idx) = access(t, sdir, mode | O_DIRECTORY);
            uint16 didx;
            uint16 fidx;
            (ec, didx) = access(t, sdir, mode | O_DIRECTORY);
            (ec, rv) = access(t, snotdir, mode);
            if (ec == 0)
                rv = fidx;
        }

    }
    function access(s_thread t, string sp, uint32 mode) internal returns (uint8 ec, uint16 idx) {
        bool abspath = sp.substr(0, 1) == "/";
        s_of dd = abspath ? t.td_proc.p_pd.pwd_rdir : t.td_proc.p_pd.pwd_cdir;
        uint8 dfd;
        s_dirent res;
        s_dirent[] des;
        if (abspath) {
            (string sdir, string snotdir) = path.dir(sp);
            (ec, idx) = access(t, sdir, mode);
            if (ec == 0) {
                (ec, des) = getdents(t, dfd);
                res = _get_dirent(des, snotdir);
            }
        } else {
            (ec, des) = getdents(t, uint8(dd.file));
            if (ec == 0)
                res = _get_dirent(des, sp);
        }
	    idx = res.d_fileno;
    }

    function lookup_dir(s_of[] t, string s) internal returns (uint8 ec, s_of df) {
        uint n = fdfetch(t, s);
        if (n > 0) {
            df = t[n - 1];
            if (!libstat.is_dir(libstat.st_mode(df.attr)))
                ec = ENOTDIR;
        } else
            ec = ENOENT;
    }

    function lookup(s_of[] t, uint8 dfd, string s) internal returns (uint8 ec, s_dirent de) {
        s_of dd;
        (ec, dd) = fdopen(t, dfd);
        if (ec == 0) {
            uint16 mode = libstat.st_mode(dd.attr);
            if (libstat.is_dir(mode)) {
                (string[] lines, ) = libstring.split(dd.buf.buf, "\n");
                for (string line: lines) {
                    s_dirent d0 = dirent.parse_dirent(line);
                    if (d0.d_name == s)
                        return (ec, d0);
                }
                ec = ENOENT;
            } else
                ec = EINVAL;
        }
    }
    function getdents(s_thread t, uint8 fd) internal returns (uint8 ec, s_dirent[] dirents) {
//        ec = 0;
        s_of[] fdt = t.td_proc.p_fd.fdt_ofiles;
//        if (fd < fdt.length) {
//            s_of dd = fdt[fd];
        s_of dd;
        (ec, dd) = fdopen(fdt, fd);
        if (ec == 0) {
            uint16 mode = libstat.st_mode(dd.attr);
            if (libstat.is_dir(mode)) {
                string bf = dd.buf.buf;
                (string[] lines, ) = libstring.split(bf, "\n");
                for (string line: lines)
                    dirents.push(dirent.parse_dirent(line));
            } else
                ec = EINVAL;
        }
    }

    function fdt_syscall(s_thread td, uint16 number, string[] args) internal {
        td.do_syscall(number, args);
    }
    function do_syscall(s_thread td, uint16 number, string[] args) internal {
        uint16 rv;
        uint8 ec;
        s_dirent[] dirents;
        s_of[] fdt_in = td.td_proc.p_fd.fdt_ofiles;
        s_of[] fdt;
//        uint len = fdt_in.length;
        uint n_args = args.length;
        string sarg1 = n_args > 0 ? args[0] : "";
        string sarg2 = n_args > 1 ? args[1] : "";
        uint8 arg1 = n_args > 0 ? uint8(str.toi(sarg1)) : 0;
        uint8 arg2 = n_args > 1 ? uint8(str.toi(sarg2)) : 0;
        if (number == SYS___getcwd) {
            rv = libstat.st_ino(td.td_proc.p_pd.pwd_cdir.attr);
            if (rv > 0)
                ec == 0;
        } else if (number == SYS_chdir || number == SYS_fchdir) {
            fdt = fdt_in;
            s_proc p = td.td_proc;
            s_xpwddesc pd = p.p_pd;
            s_of nd;
            if (number == SYS_fchdir) {
                (ec, nd) = fdopen(fdt_in, arg1);
                if (ec == 0) {
                    if (!libstat.is_dir(libstat.st_mode(nd.attr)))
                        ec = ENOTDIR;
                    else
                        td.td_proc.p_pd.pwd_cdir = nd;
                }
            } else if (number == SYS_chdir) {
                bool abspath = sarg1.substr(0, 1) == "/";
                s_of dd = abspath ? pd.pwd_rdir : pd.pwd_cdir;
                s_of fpd;
                (ec, fpd) = lookup_dir(fdt, abspath ? sarg1 : dd.path + sarg1);
                if (ec == 0)
                    td.td_proc.p_pd.pwd_cdir = fpd;
            }
        } else if (number == SYS_dup) {
            s_of f;
            (ec, f) = fdopen(fdt, arg1);
            if (ec == 0)
                td.td_proc.p_fd.fdt_ofiles.fddup(arg1);
        } else if (number == SYS_open) {
            fdt = fdt_in;
            s_xpwddesc pd = td.td_proc.p_pd;
//            uint16 mode = mode_to_flags(sarg2);
            bool abspath = sarg1.substr(0, 1) == "/";
            s_of dd = abspath ? pd.pwd_rdir : pd.pwd_cdir;
            (ec, dirents) = getdents(td, uint8(dd.file));
            s_dirent de;
            if (abspath) {
                uint n = fdfetch(fdt, sarg1);
                if (n > 0) {
                    td.td_retval = uint32(n - 1);
                    return;
                }
                (string sdir, string snotdir) = path.dir(sarg1);
                s_of fpd;
                (ec, fpd) = lookup_dir(fdt, sdir);
                if (ec == 0)
                    (ec, de) = lookup(fdt, uint8(fpd.file), snotdir);
            } else
                (ec, de) = lookup(fdt, uint8(dd.file), sarg1);
            if (ec == 0) {
                uint16 dem = dirent.DTTOIF(de.d_type);
                uint attr = (uint(de.d_fileno) << 208) + (uint(dem) << 192);
                s_sbuf buf;
                fdt.push(s_of(attr, 0, uint16(fdt.length), sarg1, 0, buf));
            }
            if (ec == 0) {
                td.td_proc.p_fd.fdt_ofiles = fdt;
                td.td_proc.p_fd.fdt_nfiles = uint16(fdt.length);
            }
        }  else if (number == SYS_close || number == SYS_freebsd12_closefrom || number == SYS_close_range) {
            if (number == SYS_close) {
                fdt = fdt_in;
                if (arg1 < fdt.length)
                    delete fdt[arg1];
                else
                    ec = EBADF;
            } else if (number == SYS_freebsd12_closefrom) {
                for (s_of f: fdt_in) {
                    if (f.file < arg1)
                        fdt.push(f);
                }
            } else if (number == SYS_close_range) {
                for (s_of f: fdt_in) {
                    if (f.file < arg1 || f.file > arg2)
                        fdt.push(f);
                }
            }
            if (ec == 0) {
                td.td_proc.p_fd.fdt_ofiles = fdt;
                td.td_proc.p_fd.fdt_nfiles = uint16(fdt.length);
            }
        } else if (number == SYS_access)
            (ec, rv) = access(td, sarg1, mode_to_flags(sarg2));
        else if (number == SYS_freebsd11_getdents || number == SYS_getdirentries) {
            if (number == SYS_freebsd11_getdents)
                (ec, dirents) = getdents(td, arg1);
        } else if (number == SYS_umask)
            rv = arg1;
        else
            ec = ENOSYS;
        td.td_errno = ec;
        td.td_retval = rv;
    }
    /*uint16 constant O_RDONLY  = 0;
    uint16 constant O_WRONLY    = 1;
    uint16 constant O_RDWR      = 2;
    uint16 constant O_ACCMODE   = 3;
    uint16 constant O_LARGEFILE = 16;
    uint16 constant O_DIRECTORY = 32;
    uint16 constant O_NOFOLLOW  = 64;
    uint16 constant O_CLOEXEC   = 128;
    uint16 constant O_CREAT     = 256;
    uint16 constant O_EXCL      = 512;
    uint16 constant O_NOCTTY    = 1024;
    uint16 constant O_TRUNC     = 2048;
    uint16 constant O_APPEND    = 4096;
    uint16 constant O_NONBLOCK  = 8192;
    uint16 constant O_DSYNC     = 16384;
    uint16 constant FASYNC      = 32768;*/
    function mode_to_flags(string mode) internal returns (uint16 flags) {
        if (mode == "r" || mode == "rb")
            flags |= O_RDONLY;
        if (mode == "w" || mode == "wb")
            flags |= O_WRONLY;
        if (mode == "a" || mode == "ab")
            flags |= O_APPEND;
        if (mode == "r+" || mode == "rb+" || mode == "r+b")
            flags |= O_RDWR;
        if (mode == "w+" || mode == "wb+" || mode == "w+b")
            //Truncate to zero length or create file for update.
            flags |= O_TRUNC | O_CREAT;
        if (mode == "a+" || mode == "ab+" || mode == "a+b")
            // Append; open or create file for update, writing at end-of-file.
            flags |= O_APPEND | O_CREAT;
    }

    function fdfetch(s_of[] t, string path) internal returns (uint) {
        for (uint i = 0; i < t.length; i++)
            if (t[i].path == path)
                return i + 1;
    }

    function fderror(s_of[] t, uint8 ec, string reason) internal {
        s_of f = t[STDERR_FILENO];
        string err_msg;// = err.strerror(ec);
        f.buf.error = ec;
        if (!reason.empty())
            err_msg.append(reason + " ");
//        f.fputs(err_msg);
        t[STDERR_FILENO] = f;
    }

    function fdflush(s_of[] t) internal returns (string out, string err) {
//        out = t[STDOUT_FILENO].fflush();
//        err = t[STDERR_FILENO].fflush();
//        t[3].fflush();
    }

    function fderrno(s_of[] t) internal returns (uint8) {
        s_of f = t[STDERR_FILENO];
        return f.buf.error;
    }

    function fdputs(s_of[] t, string str) internal {
//        t[STDOUT_FILENO].fputs(str + "\n");
//        f.fputs(str);
//        t[STDOUT_FILENO] = f;
    }
    function fdfputs(s_of[] t, string str, s_of f) internal {
//        uint16 idx = f.fileno();
//        if (idx >= 0 && idx < t.length) {
//            f.fputs(str);
//            t[idx] = f;
//        }
    }
    function fdputchar(s_of[] t, byte c) internal {
        s_sbuf s = t[STDOUT_FILENO].buf;
//        s.sbuf_putc(c);
        t[STDOUT_FILENO].buf = s;
    }
    function fdstdin(s_of[] t) internal returns (s_of) {
        return t[STDIN_FILENO];
    }
    function fdstdout(s_of[] t) internal returns (s_of) {
        return t[STDOUT_FILENO];
    }
    function fdstderr(s_of[] t) internal returns (s_of) {
        return t[STDERR_FILENO];
    }

    function getdirdesc(s_of[] t, uint8 fd) internal returns (s_dirdesc) {
        (uint8 ec, s_of f) = fdopen(t, fd);
        if (ec == 0)
            return s_dirdesc(uint8(f.file), 0, uint16(f.buf.size), f.buf.buf, uint16(f.buf.size), 0, 0, 0);
    }

    function opendir(s_of[] t, string filename) internal returns (s_dirdesc) {
        uint n = fdfetch(t, filename);
        if (n > 0)
            return getdirdesc(t, uint8(n - 1));
    }

    function fdopendir(s_of[] t, uint8 fd) internal returns (s_dirdesc) {
        return getdirdesc(t, fd);
    }
    function fdopen(s_of[] t, uint8 fd) internal returns (uint8 ec, s_of) {
        for (s_of f: t)
            if (f.file == fd)
                return (ec, f);
        ec = EBADF;
    }
    function fddup(s_of[] t, uint8 fd) internal {
        (, s_of f) = fdopen(t, fd);
        f.file = uint8(t.length);
        t.push(f);
    }

}
