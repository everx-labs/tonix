pragma ton-solidity >= 0.61.2;

import "ucred_h.sol";
import "liberr.sol";
import "priv.sol";
import "vnode_h.sol";
import "sb_h.sol";
import "mount_h.sol";
import "conf.sol";
import "libstat.sol";

library vn {

    using libstat for s_stat;
    uint16 constant VIRF_DOOMED     = 0x0001; // This vnode is being recycled
    uint16 constant VIRF_PGREAD     = 0x0002; // Direct reads from the page cache are permitted, never cleared once set
    uint16 constant VIRF_MOUNTPOINT = 0x0004; // This vnode is mounted on
    uint16 constant VI_TEXT_REF     = 0x0001; // Text ref grabbed use ref
    uint16 constant VI_MOUNT        = 0x0002; // Mount in progress
    uint16 constant VI_DOINGINACT   = 0x0004; // VOP_INACTIVE is in progress
    uint16 constant VI_OWEINACT     = 0x0008; // Need to call inactive
    uint16 constant VI_DEFINACT     = 0x0010; // deferred inactive
    uint16 constant VV_ROOT         = 0x0001; // root of its filesystem
    uint16 constant VV_ISTTY        = 0x0002; // vnode represents a tty
    uint16 constant VV_NOSYNC       = 0x0004; // unlinked, stop syncing
    uint16 constant VV_ETERNALDEV   = 0x0008; // device that is never destroyed
    uint16 constant VV_CACHEDLABEL  = 0x0010; // Vnode has valid cached MAC label
    uint16 constant VV_VMSIZEVNLOCK = 0x0020; // object size check requires vnode lock
    uint16 constant VV_COPYONWRITE  = 0x0040; // vnode is doing copy-on-write
    uint16 constant VV_SYSTEM       = 0x0080; // vnode being used by kernel
    uint16 constant VV_PROCDEP      = 0x0100; // vnode is process dependent
    uint16 constant VV_NOKNOTE      = 0x0200; // don't activate knotes on this vnode
    uint16 constant VV_DELETED      = 0x0400; // should be removed
    uint16 constant VV_MD           = 0x0800; // vnode backs the md device
    uint16 constant VV_FORCEINSMQ   = 0x1000; // force the insmntque to succeed
    uint16 constant VV_READLINK     = 0x2000; // fdescfs linux vnode
    uint16 constant VV_UNREF        = 0x4000; // vunref, do not drop lock in inactive()
    uint16 constant VMP_LAZYLIST    = 0x0001; // Vnode is on mnt's lazy list
    // Flags for va_vaflags.
    uint8 constant VA_UTIMES_NULL = 0x01; // utimes argument was NULL
    uint8 constant VA_EXCLUSIVE   = 0x02; // exclusive create request
    uint8 constant VA_SYNC        = 0x04; // O_SYNC truncation
    // Flags for ioflag. (high 16 bits used to ask for read-ahead and help with write clustering)
    // NB: IO_NDELAY and IO_DIRECT are linked to fcntl.h
    uint16 constant IO_UNIT        = 0x0001; // do I/O as atomic unit
    uint16 constant IO_APPEND      = 0x0002; // append write to end
    uint16 constant IO_NDELAY      = 0x0004; // FNDELAY flag set in file table
    uint16 constant IO_NODELOCKED  = 0x0008; // underlying node already locked
    uint16 constant IO_ASYNC       = 0x0010; // bawrite rather then bdwrite
    uint16 constant IO_VMIO        = 0x0020; // data already in VMIO space
    uint16 constant IO_INVAL       = 0x0040; // invalidate after I/O
    uint16 constant IO_SYNC        = 0x0080; // do I/O synchronously
    uint16 constant IO_DIRECT      = 0x0100; // attempt to bypass buffer cache
    uint16 constant IO_NOREUSE     = 0x0200; // VMIO data won't be reused
    uint16 constant IO_EXT         = 0x0400; // operate on external attributes
    uint16 constant IO_NORMAL      = 0x0800; // operate on regular data
    uint16 constant IO_NOMACCHECK  = 0x1000; // MAC checks unnecessary
    uint16 constant IO_BUFLOCKED   = 0x2000; // ffs flag; indir buf is locked
    uint16 constant IO_RANGELOCKED = 0x4000; // range locked
    uint16 constant IO_DATASYNC    = 0x8000; // do only data I/O synchronously

    uint8 constant IO_SEQMAX       = 0x7F;  // seq heuristic max value
    uint8 constant IO_SEQSHIFT     = 16;  // seq heuristic in upper 16 bits

    // Flags for accmode_t.
    uint32 constant VEXEC              = 0x00000040; // 000000000100; // execute/search permission
    uint32 constant VWRITE             = 0x00000080; // 000000000200; // write permission
    uint32 constant VREAD              = 0x00000100; // 000000000400; // read permission
    uint32 constant VADMIN             = 0x00001000; // 000000010000; // being the file owner
    uint32 constant VAPPEND            = 0x00004000; // 000000040000; // permission to write/append
    uint32 constant VEXPLICIT_DENY     = 0x00008000; // 000000100000; // VEXPLICIT_DENY makes VOP_ACCESSX(9) return EPERM or EACCES only if permission was denied explicitly, by a "deny" rule in NFSv4 ACL, and 0 otherwise.  This never happens with ordinary unix access rights or POSIX.1e ACLs.  Obviously, VEXPLICIT_DENY must be OR-ed with some other V* constant.
    uint32 constant VREAD_NAMED_ATTRS  = 0x00010000; // 000000200000; // not used
    uint32 constant VWRITE_NAMED_ATTRS = 0x00020000; // 000000400000; // not used
    uint32 constant VDELETE_CHILD      = 0x00040000; // 000001000000;
    uint32 constant VREAD_ATTRIBUTES   = 0x00080000; // 000002000000; // permission to stat(2)
    uint32 constant VWRITE_ATTRIBUTES  = 0x00100000; // 000004000000; // change {m,c,a}time
    uint32 constant VDELETE            = 0x00200000; // 000010000000;
    uint32 constant VREAD_ACL          = 0x00400000; // 000020000000; // read ACL and file mode
    uint32 constant VWRITE_ACL         = 0x00800000; // 000040000000; // change ACL and/or file mode
    uint32 constant VWRITE_OWNER       = 0x01000000; // 000100000000; // change file owner
    uint32 constant VSYNCHRONIZE       = 0x02000000; // 000200000000; // not used
    uint32 constant VCREAT             = 0x04000000; // 000400000000; // creating new file
    uint32 constant VVERIFY            = 0x08000000; // 001000000000; // verification required
    uint32 constant VADMIN_PERMS       = VADMIN | VWRITE_ATTRIBUTES | VWRITE_ACL | VWRITE_OWNER; // Permissions that were traditionally granted only to the file owner.
    uint32 constant VSTAT_PERMS        = VREAD_ATTRIBUTES | VREAD_ACL; // Permissions that were traditionally granted to everyone.
    uint32 constant VMODIFY_PERMS      = VWRITE | VAPPEND | VADMIN_PERMS | VDELETE_CHILD | VDELETE; // Permissions that allow to change the state of the file in any way.

    uint32 constant VNOVAL = 0xFFFFFFFF; // Token indicating no attribute value yet assigned.
    //#define VLKTIMEOUT      (hz / 20 + 1) // LK_TIMELOCK timeout for vnode locks (used mainly by the pageout daemon)
    // Convert between vnode types and inode formats (since POSIX.1 defines mode word of stat structure in terms of inode formats).
    /*function IFTOVT(uint16[] iftovt_tab, uint16 mode) internal returns (uint16) {
        return (iftovt_tab[((mode) & S_IFMT) >> 12]);
    }
    function VTTOIF(uint16[] vttoif_tab, uint16 indx) internal returns (uint16) {
        return vttoif_tab[indx];
    }
    function MAKEIMODE(uint16 indx, uint16 mode) internal returns (uint16) {
        return  VTTOIF(indx) | mode;
    }*/
// Flags to various vnode functions.
    uint8 constant SKIPSYSTEM = 0x01;  // vflush: skip vnodes marked VSYSTEM
    uint8 constant FORCECLOSE = 0x02;  // vflush: force file closure
    uint8 constant WRITECLOSE = 0x04;  // vflush: only close writable files
    uint8 constant EARLYFLUSH = 0x08;  // vflush: early call for ffs_flushfiles
    uint8 constant V_SAVE       = 0x01;  // vinvalbuf: sync file first
    uint8 constant V_ALT        = 0x02;  // vinvalbuf: invalidate only alternate bufs
    uint8 constant V_NORMAL     = 0x04;  // vinvalbuf: invalidate only regular bufs
    uint8 constant V_CLEANONLY  = 0x08;  // vinvalbuf: invalidate only clean bufs
    uint8 constant V_VMIO       = 0x10;  // vinvalbuf: called during pageout
    uint8 constant V_ALLOWCLEAN = 0x20;  // vinvalbuf: allow clean buffers after flush
    uint8 constant REVOKEALL = 0x01;  // vop_revoke: revoke all aliases
    uint8 constant V_WAIT   = 0x01;  // vn_start_write: sleep for suspend
    uint8 constant V_NOWAIT = 0x02;  // vn_start_write: don't sleep for suspend
    uint8 constant V_XSLEEP = 0x04;  // vn_start_write: just return after sleep
    uint8 constant V_MNTREF = 0x10;  // vn_start_write: mp is already ref-ed
    uint8 constant VR_START_WRITE  = 0x01;  // vfs_write_resume: start write atomically
    uint8 constant VR_NO_SUSPCLR   = 0x02;  // vfs_write_resume: do not clear suspension
    uint8 constant VS_SKIP_UNMOUNT = 0x01;  // vfs_write_suspend: fail if the filesystem is being unmounted */
    // VDESC_NO_OFFSET is used to identify the end of the offset list and in places where no such field exists.
    int8 constant VDESC_NO_OFFSET = -1;
    // vn_open_flags
    uint8 constant VN_OPEN_NOAUDIT    = 0x01;
    uint8 constant VN_OPEN_NOCAPCHECK = 0x02;
    uint8 constant VN_OPEN_NAMECACHE  = 0x04;
    uint8 constant VN_OPEN_INVFS      = 0x08;

    uint16 constant S_IXOTH = 1 << 0;
    uint16 constant S_IWOTH = 1 << 1;
    uint16 constant S_IROTH = 1 << 2;
    uint16 constant S_IRWXO = S_IROTH + S_IWOTH + S_IXOTH;
    uint16 constant S_IXGRP = 1 << 3;
    uint16 constant S_IWGRP = 1 << 4;
    uint16 constant S_IRGRP = 1 << 5;
    uint16 constant S_IRWXG = S_IRGRP + S_IWGRP + S_IXGRP;
    uint16 constant S_IXUSR = 1 << 6;
    uint16 constant S_IWUSR = 1 << 7;
    uint16 constant S_IRUSR = 1 << 8;
    uint16 constant S_IRWXU = S_IRUSR + S_IWUSR + S_IXUSR;
    uint16 constant S_ISVTX = 1 << 9;  // sticky bit
    uint16 constant S_ISGID = 1 << 10; // set-group-ID bit
    uint16 constant S_ISUID = 1 << 11; // set-user-ID bit
    uint16 constant S_IFIFO = 1 << 12;
    uint16 constant S_IFCHR = 1 << 13;
    uint16 constant S_IFDIR = 1 << 14;
    uint16 constant S_IFBLK = S_IFDIR + S_IFCHR;
    uint16 constant S_IFREG = 1 << 15;
    uint16 constant S_IFLNK = S_IFREG + S_IFCHR;
    uint16 constant S_IFSOCK = S_IFREG + S_IFDIR;
    uint16 constant S_IFMT  = 0xF000;   //   bit mask for the file type bit field

/*struct s_namecache {
    uint16 nc_dvp;    // vnode of parent of name
    uint32 nc_dvpid;  // capability number of nc_dvp
    uint16 nc_vp;     // vnode the name refers to
    uint32 nc_vpid;   // capability number of nc_vp
    uint8 nc_nlen;    // length of name
    string nc_name;	  // segment name
}*/
/*struct s_componentname {
    nameiop cn_nameiop;	// namei operation
    uint32 cn_flags;    // flags to namei
    s_proc cn_proc;	    // process requesting lookup
    s_ucred cn_cred;    // credentials
    string cn_pnbuf;    // pathname buffer
    string cn_nameptr;  // pointer to looked up name
    uint8 cn_namelen;   // length of looked up component
    uint32 cn_hash;	    // hash value of looked up name
//  long cn_consume;    // chars to consume in lookup()
}
struct s_nameidata {
    string ni_dirp;     // pathname pointer
    uio_seg ni_segflg;  // location of pathname
    uint16 ni_startdir; // starting directory
    uint16 ni_rootdir;  // logical root directory
    uint16 ni_topdir;   // logical top directory
    uint16 dir_fd;      // starting directory for *at functions
    uint16 ni_vp;       // vnode of result
    uint16 ni_dvp;      // vnode of intermediate directory
    uint16 ni_pathlen;  // remaining chars in path
    string ni_next;	    // next location in pathname
    uint8 ni_loopcnt;   // count of symlinks encountered
    s_componentname ni_cnd;
}
struct s_vnode {
    vtype v_type;        // vnode type
    uint16 v_irflag;     // frequently read flags
    uint16 v_seqc;       // modification count
    uint32 v_nchash;     // namecache hash
    s_vattr v_attrs;     // attrs
    bytes v_data;        // private data for fs
    s_namecache[] v_cache_src; // Cache entries from us
    s_namecache[] v_cache_dst; // Cache entries to us
    s_namecache v_cache_dd; // Cache entry for .. vnode
    uint16 v_iflag;         // vnode flags (see below)
    uint16 v_vflag;         // vnode flags
    uint16 v_mflag;         // mnt-specific vnode flags
}
*/

    function VOP_READ(s_vnode vp, s_uio , uint32 ioflag, s_ucred cred) internal returns (uint8 rc, string buf) {
        rc = vn.vaccess(vp.v_type, vp.v_attrs.va_mode, vp.v_attrs.va_uid, vp.v_attrs.va_gid, vn.VREAD, cred);
        if (rc > 0)
            return (rc, buf);
        if ((ioflag & IO_APPEND) > 0)
            buf.append(vp.v_data);
    }
    function VOP_WRITE(s_vnode vp, s_uio , uint32 ioflag, s_ucred cred) internal returns (uint8 rc) {
        rc = vn.vaccess(vp.v_type, vp.v_attrs.va_mode, vp.v_attrs.va_uid, vp.v_attrs.va_gid, vn.VWRITE, cred);
        if (rc > 0)
            return rc;
        if ((ioflag & IO_APPEND) > 0) {}
//          buf.append(vp.v_data);
    }
    function VOP_CREATE(s_vnode dvp, s_componentname cnp, s_vattr vap) internal returns (uint8 rc, s_vnode vpp) {
//	    (nameiop cn_nameiop, uint32 cn_flags, s_proc cn_proc, s_ucred cn_cred, string cn_pnbuf,
	    (, , , s_ucred cn_cred, ,
            string cn_nameptr,  , uint32 cn_hash) = cnp.unpack();
        rc = vn.vaccess(dvp.v_type, dvp.v_attrs.va_mode, dvp.v_attrs.va_uid, dvp.v_attrs.va_gid, vn.VWRITE, cn_cred);
        if (rc > 0)
            return (rc, vpp);
        s_namecache[] empty;
        s_namecache nc;
        s_bufobj bo;
        vpp = s_vnode(vtype.VREG, 0, 0, cn_hash, vap, cn_nameptr, empty, empty, nc, bo, 0, 0, 0);
    }
    function VOP_VPTOCNP(s_vnode , s_vnode dvp, s_ucred cred) internal returns (uint8 rc, string , uint16 ) {
        rc = vn.vaccess(dvp.v_type, dvp.v_attrs.va_mode, dvp.v_attrs.va_uid, dvp.v_attrs.va_gid, vn.VREAD, cred);
    }
    function VOP_ADVISE(s_vnode vp, uint32 start, uint32 end, uint8 advice) internal returns (uint8 rc) {}
    function VOP_ALLOCATE(s_vnode vp, uint32 offset, uint32 len) internal returns (uint8 rc, uint32 noffset, uint32 nlen) {}
    function VOP_GETATTR(s_vnode vp, s_ucred ) internal returns (uint8 rc, s_vattr vap) {
        vap = vp.v_attrs;
        rc = 0;
    }
    function VOP_SETATTR(s_vnode vp, s_vattr vap, s_ucred ) internal returns (uint8 ) {
        vp.v_attrs = vap;
    }
    function VOP_STAT(s_vnode vp, s_ucred , s_ucred , s_thread) internal returns (uint8 rc, s_stat sb) {
        (, uint16 va_mode, uint16 va_uid, uint16 va_gid, uint16 va_nlink, uint16 va_fsid, uint16 va_fileid,
            uint32 va_size, uint16 va_blocksize, , uint32 va_mtime, uint32 va_ctime, ,
            , , uint16 va_rdev, , , ) = vp.v_attrs.unpack();
        sb = s_stat(va_fsid, va_fileid, va_mode, va_nlink, va_uid, va_gid, va_rdev, va_size, va_blocksize, 1, va_mtime, va_ctime);
        rc = 0;
    }
    function VOP_BWRITE(s_vnode vp, s_buf bp) internal returns (uint8 ) {
//        vp.v_bufobj.bo_dirty.push(bp);

    }
    function VOP_FDATASYNC(s_vnode vp, s_thread td) internal returns (uint8 rc) {}
    function VOP_INACTIVE(s_vnode vp, s_thread td) internal returns (uint8 rc) {}
    function VOP_RECLAIM(s_vnode vp, s_thread td) internal returns (uint8 rc) {}
    function VOP_FSYNC(s_vnode vp, uint16 waitfor, s_thread td) internal returns (uint8 rc) {}
    function VOP_IOCTL(s_vnode vp, uint32 command, uint32 data, uint32 fflag, s_ucred cred, s_thread td) internal returns (uint8) {}
    function VOP_LINK(s_vnode dvp, s_vnode vp, s_componentname cnp) internal returns (uint8) {}
    function VOP_OPEN(s_vnode vp, uint16 mode, s_ucred cred, s_thread td) internal returns (uint8, s_of fp) {}
    function VOP_CLOSE(s_vnode vp, uint16 mode, s_ucred	cred, s_thread td) internal returns (uint8) {}
    function VOP_LOOKUP(s_vnode dvp, s_vnode vpp, s_componentname cnp) internal returns (uint8) {}
    function VOP_MKNOD(s_vnode dvp, s_vnode vpp, s_componentname cnp, s_vattr vap) internal returns (uint8) {}
    function VOP_MKDIR(s_vnode dvp, s_vnode vpp, s_componentname cnp, s_vattr vap) internal returns (uint8) {}
    function VOP_SYMLINK(s_vnode dvp, s_vnode vpp, s_componentname cnp, s_vattr vap, string target) internal returns (uint8) {}
    function VOP_RENAME(s_vnode fdvp, s_vnode fvp, s_componentname fcnp, s_vnode tdvp, s_vnode tvp, s_componentname tcnp) internal returns (uint8) {}
    function VOP_PATHCONF(s_vnode , uint8	name) internal returns (uint8 e, uint32 retval) {
        if (name == conf._PC_LINK_MAX)//	   The maximum number of links to a file.
            retval = 10;
        else if (name == conf._PC_NAME_MAX) //	   The maximum number of bytes in a file name.
            retval = 32;
        else if (name == conf._PC_PATH_MAX)	  // The maximum number of bytes in a pathname.
            retval = 200;
        else if (name == conf._PC_PIPE_BUF)	  // The maximum number of bytes which will be written atomically to a pipe.
            retval = 10000;
        else if (name == conf._PC_CHOWN_RESTRICTED) // Return 1 if appropriate privileges are required for the chown(2) system call, otherwise 0.
            retval = 0;
        else if (name == conf._PC_NO_TRUNC)	  // Return 1 if file names longer than KERN_NAME_MAX are truncated.
            retval = 0;
        else
            e = err.EINVAL;
    }
    function VOP_PRINT(s_vnode vp) internal returns (uint8, string) {

    }
    function VOP_READDIR(s_vnode vp, s_uio uio, s_ucred cred) internal returns (uint8, s_uio nuio) {}
    function VOP_READLINK(s_vnode vp, s_uio uio, s_ucred cred) internal returns (uint8) {}
    function VOP_REALLOCBLKS(s_vnode vp, s_buf[] buflist) internal returns (uint8) {}
    function VOP_REMOVE(s_vnode dvp, s_vnode vp, s_componentname cnp) internal returns (uint8) {}
    function VOP_RMDIR(s_vnode dvp, s_vnode vp, s_componentname cnp) internal returns (uint8) {}
    function VOP_REVOKE(s_vnode vp, uint32 flags) internal returns (uint8) {}
    function VOP_STRATEGY(s_vnode vp, s_buf bp) internal returns (uint8) {
        /*(uint32 b_bcount, uint32 b_data, uint8 b_error, uint16 b_iocmd, uint16 b_ioflags, uint32 b_iooffset,
            uint32 b_resid, uint64 b_ckhash, uint32 b_blkno, uint32 b_offset, uint32 b_vflags, uint8 b_qindex,
            uint8 b_domain, uint32 b_flags, uint16 b_xflags, uint32 b_bufsize, uint32 b_runningbufspace,
            uint32 b_kvasize, uint32 b_dirtyoff, uint32 b_dirtyend, uint32 b_kvabase, uint32 b_lblkno, uint16 b_vp,
            s_ucred b_rcred, s_ucred b_wcred, uint32 b_npages) = bp.unpack();
        if (b_iocmd == bio.BIO_READ) {}
        else if (b_iocmd == bio.BIO_WRITE) {}*/
    }
    function VOP_VPTOFH(s_vnode vp) internal returns (uint8, string fhp) {}
    function VOP_ACCESS(s_vnode vp, uint32 accmode, s_ucred cred, s_thread ) internal returns (uint8) {
        return vaccess(vp.v_type, vp.v_attrs.va_mode, vp.v_attrs.va_uid, vp.v_attrs.va_gid, accmode, cred);
    }

    function vget(s_vnode vp, s_of f) internal {
        (uint attr, uint16 flags, , , , s_sbuf buf) = f.unpack();
        s_vattr sv = set_stats(vp, attr);
        vp.v_attrs = sv;
        vp.v_irflag = flags;
        vp.v_data = buf.buf;
        vp.v_nchash = sv.va_fileid;
    }

    /*function lookup(s_proc p, string path) internal returns (k_nameidata ndp) {
        k_componentname cnp = k_componentname(LOOKUP, cn_flags, p, p.p_ucred, cn_pnbuf, cn_pnlen, cn_nameptr, cn_namelen)
    }*/
    function relookup(s_vnode dvp, s_vnode vpp, s_componentname cnp) internal returns (uint16) {}
    function cache_lookup(s_vnode dvp, s_vnode vpp, s_componentname cnp) internal returns (uint16) {}
    function cache_enter(s_vnode dvp, s_vnode vpp, s_componentname cnp) internal {

    }
    function cache_purge(s_vnode vp) internal {}
    function cache_purgevfs(s_mount mp) internal {}

    function cache_vnode_init(s_vnode vp) internal {}
    function cache_purge_vgone(s_vnode vp) internal {}
    function cache_purge_negative(s_vnode vp) internal {}
    function cache_symlink_alloc(uint16 size, uint16 flags) internal returns (string) {}
    function cache_symlink_free(string s, uint16 size) internal {}
//    function cache_symlink_resolve(struct cache_fpl *fpl, string s, uint16 len) internal returns (uint16) {}
    function cache_vop_rename(s_vnode fdvp, s_vnode fvp, s_vnode tdvp, s_vnode tvp, s_componentname fcnp, s_componentname tcnp) internal {}
    function cache_vop_rmdir(s_vnode dvp, s_vnode vp) internal {}
    function cache_validate(s_vnode dvp, s_vnode vp, s_componentname cnp) internal {}
    function change_dir(s_vnode vp, s_thread td) internal returns (uint16) {}
    function getnewvnode(string tag, s_mount mp, uint16 vops, s_vnode vpp) internal returns (uint16) {}
    function insmntque(s_vnode vp, s_mount mp) internal returns (uint16) {}
    function insmntque1(s_vnode vp, s_mount mp) internal returns (uint16) {}
    function vn_vptocnp(s_vnode vp, string buf, uint16 buflen) internal returns (uint16) {}
    function vn_getcwd(string buf, string retbuf, uint16 buflen) internal returns (uint16) {}
    function vn_fullpath(s_vnode vp, string retbuf, string freebuf) internal returns (uint16) {}
    function vn_fullpath_global(s_vnode vp, string retbuf, string freebuf) internal returns (uint16) {}
    function vn_fullpath_hardlink(s_vnode vp, s_vnode dvp, string hdrl_name, uint16 hrdl_name_length, string retbuf, string freebuf, uint16 buflen) internal returns (uint16) {}
    function vn_dir_dd_ino(s_vnode vp) internal returns (s_vnode) {}
    function vn_commname(s_vnode vp, string buf, uint16 buflen) internal returns (uint16) {}
    function vn_path_to_global_path(s_thread td, s_vnode vp, string path, uint16 pathlen) internal returns (uint16) {}
    function vaccess_vexec_smr(uint16 file_mode, uint16 file_uid, uint16 file_gid, s_ucred cred) internal returns (uint16) {}
    function vattr_null(s_vattr vap) internal {}
    function vtruncbuf(s_vnode vp, uint16 length, uint16 blksize) internal returns (uint16) {}
/*struct s_vnode {
    vtype v_type;		 // vnode type
    uint16 v_irflag;	 // frequently read flags
    uint16 v_seqc;		 // modification count
    uint32 v_nchash;	 // namecache hash
    s_vattr v_attrs;     // attrs
    bytes v_data;		 // private data for fs
    s_namecache[] v_cache_src; // Cache entries from us
    s_namecache[] v_cache_dst; // Cache entries to us
    s_namecache v_cache_dd;    // Cache entry for .. vnode
    uint16 v_iflag;          // vnode flags (see below)
    uint16 v_vflag;         // vnode flags
    uint16 v_mflag;         // mnt-specific vnode flags
}*/
//        (uint16 imode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
//        (uint attr, uint16 flags, uint16 file, string path, uint32 offset, s_sbuf buf) = f.unpack();
//        s_vattr sv = set_stats(vp, ino, i);
//        vp.v_attrs = sv;
//        vp.v_irflag = flags;
//        vp.v_data = f.buf.buf;
//        vp.v_nchash = sv.va_fileid;
    function vget_ino(s_vnode vp, Inode ino, uint16 i) internal {
        s_vattr sv = vp.v_attrs;
        (uint16 imode, uint16 owner_id, uint16 group_id, uint16 n_links, , , uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        ( , sv.va_type, , , , ) = libstat.mode(imode);
        sv.va_mode = imode;
        sv.va_uid = owner_id;
        sv.va_gid = group_id;
        sv.va_nlink = n_links;
        sv.va_fileid = i;
        sv.va_size = file_size;
//        sv.va_blocksize = st_blksize;
        sv.va_atime = now;
        sv.va_mtime = modified_at;
        sv.va_ctime = last_modified;
        sv.va_birthtime = now;
//        sv.va_rdev = st_rdev;
        vp.v_attrs = sv;
    }

    function set_stats(s_vnode vp, uint attrs) internal returns (s_vattr sv) {
        sv = vp.v_attrs;
        s_stat st;
        st.stt(attrs);
        (, uint16 st_ino, uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_size,
            uint16 st_blksize, , uint32 st_mtim, uint32 st_ctim) = st.unpack();
        sv.va_type = vtype.VREG;//libstat.vnode_type(st);
        sv.va_mode = st_mode;
        sv.va_uid = st_uid;
        sv.va_gid = st_gid;
        sv.va_nlink = st_nlink;
        sv.va_fileid = st_ino;
        sv.va_size = st_size;
        sv.va_blocksize = st_blksize;
        sv.va_atime = now;
        sv.va_mtime = st_mtim;
        sv.va_ctime = st_ctim;
        sv.va_birthtime = now;
        sv.va_rdev = st_rdev;
        vp.v_attrs = sv;
    }

    function vaccess(vtype ntype, uint16 file_mode,	uint16 file_uid, uint16 file_gid, uint32 accmode, s_ucred cred) internal returns (uint8) {
        uint16 cr_uid = cred.cr_uid;
        uint32 ag;
        uint32 pg;
        if (file_uid == cr_uid) {
            ag |= VADMIN;
            if ((file_mode & S_IXUSR) > 0)
                ag |= VEXEC;
            if ((file_mode & S_IRUSR) > 0)
                ag |= VREAD;
            if ((file_mode & S_IWUSR) > 0)
                ag |= (VWRITE | VAPPEND);
            if ((accmode & ag) == accmode)
                return 0;
        }
        if (groupmember(cred, file_gid)) {
            if ((file_mode & S_IXGRP) > 0)
                ag |= VEXEC;
            if ((file_mode & S_IRGRP) > 0)
                ag |= VREAD;
            if ((file_mode & S_IWGRP) > 0)
                ag |= (VWRITE | VAPPEND);
            if ((accmode & ag) == accmode)
                return 0;
        }
        if ((file_mode & S_IXOTH) > 0)
            ag |= VEXEC;
        if ((file_mode & S_IROTH) > 0)
            ag |= VREAD;
        if ((file_mode & S_IWOTH) > 0)
            ag |= (VWRITE | VAPPEND);
        if ((accmode & ag) == accmode)
            return 0;
        if (ntype == vtype.VDIR) {
            if (((accmode & VEXEC) > 0) && ((ag & VEXEC) == 0) && priv.priv_check_cred(cred, priv.PRIV_VFS_LOOKUP) == 0)
                pg |= VEXEC;
        } else {
            if ((accmode & VEXEC) > 0 && ((ag & VEXEC) == 0) &&
                (file_mode & (S_IXUSR | S_IXGRP | S_IXOTH)) != 0 &&
                priv.priv_check_cred(cred, priv.PRIV_VFS_EXEC) == 0)
            pg |= VEXEC;
        }
        if (((accmode & VREAD) > 0) && ((ag & VREAD) == 0) && priv.priv_check_cred(cred, priv.PRIV_VFS_READ) == 0)
            pg |= VREAD;
        if (((accmode & VWRITE) > 0) && ((ag & VWRITE) == 0) && priv.priv_check_cred(cred, priv.PRIV_VFS_WRITE) == 0)
            pg |= (VWRITE | VAPPEND);
        if (((accmode & VADMIN) > 0) && ((ag & VADMIN) == 0) && priv.priv_check_cred(cred, priv.PRIV_VFS_ADMIN) == 0)
            pg |= VADMIN;
        if ((accmode & (pg | ag)) == accmode)
            return 0;
        return (accmode & VADMIN) > 0 ? err.EPERM : err.EACCES;
    }

//    function vn_rdwr(s_vnode vp, uio_rw rw, bytes base, uint32 len, uint32 offset, uio_seg segflg, uint16 ioflg, s_ucred active_cred, s_ucred file_cred, uint32 aresid, s_thread td) internal returns (uint8 rc, bytes buf) {
    function vn_rdwr(s_vnode vp, uio_rwo rw, bytes base, uint32 len, uint32 offset, uio_seg , uint16 , s_ucred active_cred, s_ucred , uint32 aresid, s_thread ) internal returns (uint8 rc, bytes buf) {
        uint32 flags = rw == uio_rwo.UIO_READ ? VREAD : VWRITE;
        rc = vn.vaccess(vp.v_type, vp.v_attrs.va_mode, vp.v_attrs.va_uid, vp.v_attrs.va_gid, flags, active_cred);
        if (rc > 0)
            return (rc, buf);
        bytes vdata = vp.v_data;
        uint32 cap = math.min(len, aresid);
        if (rw == uio_rwo.UIO_READ) {
            buf = string(vdata).substr(offset, cap);
        } else if (rw == uio_rwo.UIO_WRITE) {
            buf = string(base).substr(offset, cap);
        }
    }
//    function vn_rdwr_inchunks(uio_rw rw, k_vnode vp, bytes base, uint32 len, uint32 offset, uio_seg segflg, uint16 ioflg, s_ucred active_cred, s_ucred file_cred, uint32 aresid, s_thread td) internal returns (uint16) {}

    function groupmember(s_ucred cred, uint16 gid) internal returns (bool) {
        for (uint16 g: cred.cr_groups)
            if (g == gid)
                return true;
        return false;
    }
}