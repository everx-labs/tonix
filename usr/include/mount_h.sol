pragma ton-solidity >= 0.62.0;

import "vnode_h.sol";
struct s_fsid {
    uint32[2] val;
}
struct s_vfsops {
    uint32 vfs_mount;
    uint32 vfs_cmount;
    uint32 vfs_unmount;
    uint32 vfs_root;
    uint32 vfs_cachedroot;
    uint32 vfs_quotactl;
    uint32 vfs_statfs;
    uint32 vfs_sync;
    uint32 vfs_vget;
    uint32 vfs_fhtovp;
    uint32 vfs_checkexp;
    uint32 vfs_init;
    uint32 vfs_uninit;
    uint32 vfs_extattrctl;
    uint32 vfs_sysctl;
    uint32 vfs_susp_clean;
    uint32 vfs_reclaim_lowervp;
    uint32 vfs_unlink_lowervp;
    uint32 vfs_purge;
}

// Userland version of the struct vfsconf.
struct s_xvfsconf {
    s_vfsops vfc_vfsops; // filesystem operations vector
    string vfc_name;     // filesystem type name
    uint16 vfc_typenum;  // historic filesystem type number
    uint16 vfc_refcount; // number mounted of this type
    uint16 vfc_flags;    // permanent flags
}


struct s_statfs {
    uint16 f_version;     // structure version number
    uint16 f_type;        // type of filesystem
    uint32 f_flags;       // copy of mount exported flags
    uint16 f_bsize;       // filesystem fragment size
    uint16 f_iosize;      // optimal transfer block size
    uint16 f_blocks;      // total data blocks in filesystem
    uint16 f_bfree;       // free blocks in filesystem
    uint16 f_bavail;      // free blocks avail to non-superuser
    uint16 f_files;       // total file nodes in filesystem
    uint16 f_ffree;       // free nodes avail to non-superuser
    uint16 f_syncwrites;  // count of sync writes since mount
    uint16 f_asyncwrites; // count of async writes since mount
    uint16 f_syncreads;   // count of sync reads since mount
    uint16 f_asyncreads;  // count of async reads since mount
    uint16 f_namemax;     // maximum filename length
    uint16 f_owner;       // user that mounted the filesystem
    uint16 f_fsid;        // filesystem id
    string f_fstypename;  // filesystem type name
    string f_mntfromname; // mounted filesystem
    string f_mntonname;   // directory on which mounted
}
struct s_fid {
    uint32 fid_len;   // length of data in bytes
    string fid_data;  // data (variable length)
}

struct s_vfsopt { // Mount options list
    string name;
    bytes value;
    uint16 len;
    uint16 pos;
    uint16 seen;
}
struct s_mount_pcpu {
    uint16 mntp_thread_in_ops;
    uint16 mntp_ref;
    uint16 mntp_lockref;
    uint16 mntp_writeopcount;
}
struct s_mntarg {
    uint16[] mnt_args;
}
struct s_mntoptnames {
    uint64 o_opt;
    string o_name;
}

struct nfs_public {  // Structure holding information for a publicly exported filesystem (WebNFS). Currently the specs allow just for one such filesystem
    bool np_valid;    // Do we hold valid information
    uint16 np_handle; // Filehandle for pub fs (internal)
    s_mount np_mount; // Mountpoint of exported fs
    string np_index;  // Index file
}

enum pfstype { pfstype_none, pfstype_root, pfstype_dir, pfstype_this, pfstype_parent, pfstype_file, pfstype_symlink, pfstype_procdir }
struct s_pfs_vdata {
    s_pfs_node pvd_pn;
    uint16 pvd_pid;
    s_vnode pvd_vnode;
    uint32 pvd_hash;
}
struct s_pfs_info {
    string pi_name; //[PFS_FSNAMELEN];
    s_pfs_node[] pi_root;
    s_unrhdr pi_unrhdr;
}
struct s_pfs_node {
    string pn_name; //[PFS_NAMELEN];
    uint16 pn_type;
    uint16 pn_flags;
    bytes pn_data;
    uint16 pn_fileno;
}

// Filesystem configuration information. One of these exists for each type of filesystem supported by the kernel.
// These are searched at mount time to identify the requested filesystem
 struct s_vfsconf {
    uint16 vfc_version;     // ABI version number
    string vfc_name;        // filesystem type name
    s_vfsops vfc_vfsops;    // filesystem operations vector
    s_vfsops vfc_vfsops_sd; // ... signal-deferred
    uint16 vfc_typenum;     // historic filesystem type number
    uint16 vfc_refcount;    // number mounted of this type
    uint16 vfc_flags;       // permanent flags
    s_vfsopt[] vfc_opts;    // mount options
}
struct s_mount {
    uint16 mnt_vfs_ops;         // pending vfs ops
    uint16 mnt_kern_flag;       // kernel only flags
    uint64 mnt_flag;            // flags shared with user
    s_vnode mnt_rootvnode;
    s_vnode mnt_vnodecovered;   // vnode we mounted on
    s_vfsops mnt_op;            // operations on fs
    s_vfsconf mnt_vfc;          // configuration info
    uint16 mnt_gen;             // struct mount generation
    s_vnode mnt_syncer;         // syncer vnode
    uint16 mnt_ref;             // Reference count
    s_vnode[] mnt_nvnodelist;   // list of vnodes
    uint16 mnt_nvnodelistsize;  // # of vnodes
    uint16 mnt_writeopcount;    // write syscalls pending
    s_vfsopt[] mnt_opt;         // current mount options
    s_vfsopt[] mnt_optnew;      // new options passed to fs
    uint16 mnt_maxsymlinklen;   // max size of short symlink
    s_statfs mnt_stat;          // cache of filesystem stats
    s_ucred mnt_cred;           // credentials of mounter
    bytes mnt_data;             // private data
    uint32 mnt_time;            // last time writte
    uint16 mnt_iosize_max;      // max size for clusters, etc
//    struct netexport *mnt_export; // export list
    string mnt_label;                // MAC label for the fs
}