pragma ton-solidity >= 0.64.0;

import "namei_h.sol";
enum vtype { VNON, VREG, VDIR, VBLK, VCHR, VLNK, VSOCK, VFIFO, VBAD, VMARKER }

/*struct vpollinfo {
    selinfo vpi_selinfo;  // identity of poller(s)
    uint8 vpi_events;     // what they are looking for
    uint8 vpi_revents;    // what has happened
}

struct vnode {
    vtype v_type;       // vnode type
    uint16 v_irflag;    // frequently read flags
    seqc_t v_seqc;	    // modification count
    uint32 v_nchash;    // namecache hash
    uint v_hash;
    vop_vector v_op;    // vnode operations vector
    uint32 v_data;      // private data for fs
    s_mount v_mount;    // ptr to vfs we are in
//  TAILQ_ENTRY(vnode) v_nmntvnodes; // vnodes for mount point
    s_mount	v_mountedhere; // ptr to mountpoint (VDIR)
    // vfs_hash: (mount + inode) -> vnode hash.  The hash value itself is grouped with other int fields, to avoid padding.
    LIST_ENTRY(vnode)   v_hashlist;
    LIST_HEAD(, namecache) v_cache_src;	 // Cache entries from us
    TAILQ_HEAD(, namecache) v_cache_dst; Cache entries to us
    s_namecache v_cache_dd;	// Cache entry for .. vnode
    TAILQ_ENTRY(vnode) v_vnodelist;	// vnode lists
    TAILQ_ENTRY(vnode) v_lazylist;	// vnode lazy list
    s_bufobj v_bufobj;      // Buffer cache object
    vpollinfo v_pollinfo;   // Poll events, p for *v_pi
    uint8 v_label;          // MAC label for vnode
    uint8 v_holdcnt;        // prevents recycling.
    uint8 v_usecount;       // ref count of users
    uint16 v_iflag;	        // vnode flags (see below)
    uint16 v_vflag;	        // vnode flags
    uint16 v_mflag;	        // mnt-specific vnode flags
    uint8 v_dbatchcpu;      // LRU requeue deferral batch
    int8 v_writecount;      // ref count of writers or (negative) text users
    int8 v_seqc_users;      // modifications pending
}

fo_rdwr_t vn_read;
fo_rdwr_t vn_write;
fo_rdwr_t vn_io_fault;
fo_truncate_t vn_truncate;
fo_ioctl_t vn_ioctl;
fo_poll_t vn_poll;
fo_kqfilter_t vn_kqfilter;
fo_close_t vn_closefile;
fo_mmap_t vn_mmap;
fo_fallocate_t vn_fallocate;
fo_fspacectl_t vn_fspacectl;

struct fileops vnops = {
    .fo_read = vn_io_fault,
    .fo_write = vn_io_fault,
    .fo_truncate = vn_truncate,
    .fo_ioctl = vn_ioctl,
    .fo_poll = vn_poll,
    .fo_kqfilter = vn_kqfilter,
    .fo_stat = vn_statfile,
    .fo_close = vn_closefile,
    .fo_chmod = vn_chmod,
    .fo_chown = vn_chown,
    .fo_sendfile = vn_sendfile,
    .fo_seek = vn_seek,
    .fo_fill_kinfo = vn_fill_kinfo,
    .fo_mmap = vn_mmap,
    .fo_fallocate = vn_fallocate,
    .fo_fspacectl = vn_fspacectl,
    .fo_flags = DFLAG_PASSABLE | DFLAG_SEEKABLE
}*/

struct s_vnode {
    vtype v_type;    // vnode type
    uint16 v_irflag; // frequently read flags
    uint16 v_seqc;   // modification count
    uint32 v_nchash; // namecache hash
    s_vattr v_attrs; // attrs
    bytes v_data;    // private data for fs
    s_namecache[] v_cache_src; // Cache entries from us
    s_namecache[] v_cache_dst; // Cache entries to us
    s_namecache v_cache_dd;    // Cache entry for .. vnode
    s_bufobj v_bufobj;   // Buffer cache object
    uint16 v_iflag;  // vnode flags (see below)
    uint16 v_vflag;  // vnode flags
    uint16 v_mflag;  // mnt-specific vnode flags
}

struct s_vattr { // Vnode attributes.  A field value of VNOVAL represents a field whose value is unavailable (getattr) or which is not to be changed (setattr)
    vtype va_type;       // vnode type (for create)
    uint16 va_mode;      // files access mode and type
    uint16 va_uid;       // owner user id
    uint16 va_gid;       // owner group id
    uint16 va_nlink;     // number of references to file
    uint16 va_fsid;      // filesystem id
    uint16 va_fileid;    // file id
    uint32 va_size;      // file size in bytes
    uint16 va_blocksize; // blocksize preferred for i/o
    uint32 va_atime;     // time of last access
    uint32 va_mtime;     // time of last modification
    uint32 va_ctime;     // time file changed
    uint32 va_birthtime; // time file created
    uint16 va_gen;       // generation number of file
    uint16 va_flags;     // flags defined for file
    uint16 va_rdev;      // device the special file represents
    uint32 va_bytes;     // bytes of disk space held by file
    uint16 va_filerev;   // file modification number
    uint32 va_vaflags;   // operations flags, see below
}
struct k_vnodeop_desc { // This structure describes the vnode operation taking place
    string vdesc_name;          // a readable name for debugging
    uint16 vdesc_flags;         // VDESC_* flags
    uint16 vdesc_vop_offset;
    uint32 vdesc_call;          // Function to call
    uint16 vdesc_vpp_offset;    // return vpp location
    uint16 vdesc_cred_offset;   // cred location, if any
    uint16 vdesc_thread_offset; // thread location, if any
    uint16 vdesc_componentname_offset;  // if any
}