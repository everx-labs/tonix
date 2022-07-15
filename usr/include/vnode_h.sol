pragma ton-solidity >= 0.62.0;

struct s_vnode {
    vtype v_type;		 // vnode type
    uint16 v_irflag;	 // frequently read flags
    uint16 v_seqc;		 // modification count
    uint32 v_nchash;	 // namecache hash
    s_vattr v_attrs;     // attrs
    bytes v_data;		 // private data for fs
    s_namecache[] v_cache_src; // Cache entries from us
    s_namecache[] v_cache_dst; // Cache entries to us
    s_namecache v_cache_dd;    // Cache entry for .. vnode
    s_bufobj v_bufobj;   // Buffer cache object
    uint16 v_iflag;      // vnode flags (see below)
    uint16 v_vflag;      // vnode flags
    uint16 v_mflag;      // mnt-specific vnode flags
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