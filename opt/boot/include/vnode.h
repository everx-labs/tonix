pragma ton-solidity >= 0.66.0;

enum vtype	{ VNON, VREG, VDIR, VBLK, VCHR, VLNK, VSOCK, VFIFO, VBAD, VMARKER }
enum vgetstate	{ VGET_NONE, VGET_HOLDCNT, VGET_USECOUNT }
struct vnode {
	vtype v_type;			// vnode type
	uint8 v_irflag;		    // frequently read flags
	uint16 v_seqc;			// modification count
	uint32 v_nchash;		// namecache hash
	uint16 v_op;		    // vnode operations vector // vop_vector
	uint32 v_data;			// private data for fs
	uint16 v_mount;			// ptr to vfs we are in // mount
	uint16 v_mountedhere;	// ptr to mountpoint (VDIR) // mount
	uint16 v_hashlist;      // vfs_hash: (mount + inode) -> vnode hash // vnode
	namecache[] v_cache_src;// Cache entries from us
	namecache[] v_cache_dst;// Cache entries to us
	namecache v_cache_dd;	// Cache entry for .. vnode
	uint16 v_bufobj;		// Buffer cache object // bufobj
	uint16 v_iflag;			// vnode flags (see below)
	uint16 v_vflag;			// vnode flags
	uint16 v_mflag;			// mnt-specific vnode flags
	uint8 v_writecount;		// ref count of writers or (negative) text users
	uint8 v_seqc_users;		// modifications pending
}

struct vattr {
	vtype va_type;	    // vnode type (for create)
	uint16 va_mode;	    // files access mode and type
	uint16 va_uid;		// owner user id
	uint16 va_gid;		// owner group id
	uint16 va_nlink;	// number of references to file
	uint16 va_fsid;	    // filesystem id
	uint16 va_fileid;	// file id
	uint32 va_size;	    // file size in bytes
	uint16 va_blocksize;// blocksize preferred for i/o
	uint32 va_atime;	// time of last access
	uint32 va_mtime;	// time of last modification
	uint32 va_ctime;	// time file changed
	uint32 va_birthtime;// time file created
	uint16 va_gen;		// generation number of file
	uint16 va_flags;	// flags defined for file
	uint16 va_rdev;	    // device the special file represents
}