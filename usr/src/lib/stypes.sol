pragma ton-solidity >= 0.58.0;
import "../lib/utypes.sol";
import "../include/errno.sol";
import "../include/param.sol";
import "../sys/sys/uma.sol";
import "../sys/sys/uma_int.sol";
import "vmem.sol";

enum nameiop { LOOKUP, CREATE, DELETE, RENAME }

struct svm {
    s_proc cur_proc;
    uma_zone[] sz;
    s_vmem[] vmem;
}


struct s_iovec {
    uint32 iov_base; // Base address.
    uint32 iov_len; // Length.
}
enum uio_rw {
    UIO_READ,
    UIO_WRITE
}
// Segment flag values.
enum uio_seg {
    UIO_USERSPACE,// from user data space
    UIO_SYSSPACE, // from system space
    UIO_NOCOPY    // don't copy, already in object
}
struct s_uio {
    s_iovec uio_iov;    // scatter/gather list
    uint16 uio_iovcnt;  // length of scatter/gather list
    uint32 uio_offset;  // offset in target object
    uint32 uio_resid;   // remaining bytes to process
    uio_seg uio_segflg; // address space
    uio_rw uio_rwo;      // operation
    s_thread uio_td;    // owner
}

struct s_sysent {       // system call table
    uint16 sy_call;     // implementing function
    uint8 sy_narg;       // number of arguments
}

struct s_loadavg {
    uint32[3] ldavg;
    uint32 fscale;
}

// Mount options list
struct s_vfsopt {
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

/*
 * Filesystem configuration information. One of these exists for each type of filesystem supported by the kernel. These are searched at
 * mount time to identify the requested filesystem. * XXX: Never change the first two arguments!
 */
 struct s_vfsconf {
    uint16 vfc_version;     // ABI version number
    string vfc_name;        // filesystem type name
    s_vfsops vfc_vfsops;    // filesystem operations vector
    s_vfsops vfc_vfsops_sd; // ... signal-deferred
    uint16 vfc_typenum;     // historic filesystem type number
    uint16 vfc_refcount;    // number mounted of this type
    uint16 vfc_flags;       // permanent flags
    uint16 vfc_prison_flag; // prison allow.mount.* flag
    s_vfsopt[] vfc_opts;    // mount options
}

struct s_mount {
    uint16 mnt_vfs_ops;         // pending vfs ops
    uint16 mnt_kern_flag;       // kernel only flags
    uint64 mnt_flag;            // flags shared with user
//    s_mount_pcpu mnt_pcpu;      // per-CPU data
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

// Vnode attributes.  A field value of VNOVAL represents a field whose value is unavailable (getattr) or which is not to be changed (setattr).
struct s_vattr {
    vtype va_type;      // vnode type (for create)
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
// This structure describes the vnode operation taking place.
struct k_vnodeop_desc {
    string vdesc_name;          // a readable name for debugging
    uint16 vdesc_flags;         // VDESC_* flags
    uint16 vdesc_vop_offset;
    uint32 vdesc_call;          // Function to call
    uint16 vdesc_vpp_offset;    // return vpp location
    uint16 vdesc_cred_offset;   // cred location, if any
    uint16 vdesc_thread_offset; // thread location, if any
    uint16 vdesc_componentname_offset;  // if any
}

struct s_fadvise_info {
    uint32 fa_advice;      // (f) FADV_* type.
    uint32 fa_start;       // (f) Region start.
    uint32 fa_end;         // (f) Region end.
}
struct s_file {
    uint16 f_flag;    // see fcntl.h
    bytes f_data;     // file descriptor specific data
//  s_vnode f_vnode;  // NULL or applicable vnode
    s_ucred f_cred;   // associated credentials.
    uint8 f_type;     // descriptor type
    uint32[2] f_nextoff; // next expected read/write offset.
    s_fadvise_info fvn_advice;
    uint32 f_offset;
}

 //Structure holding information for a publicly exported filesystem (WebNFS). Currently the specs allow just for one such filesystem.
struct nfs_public {
    bool np_valid;    // Do we hold valid information
    uint16 np_handle; // Filehandle for pub fs (internal)
    s_mount np_mount; // Mountpoint of exported fs
    string np_index;  // Index file
}

struct s_fsid {
    uint32[2] val;
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

struct s_dirent {
	uint16 d_fileno;
	uint8 d_type;
	string d_name;
}

struct s_dirdesc {
	uint16 dd_fd;	 // file descriptor associated with directory
	uint16 dd_loc;	 // offset in current buffer
	uint16 dd_size;  // amount of data returned by getdirentries
	string dd_buf;   // data buffer
	uint16 dd_len;	 // size of data buffer
	uint16 dd_seek;  // magic cookie returned by getdirentries
	uint16 dd_flags; // flags for readdir
	uint16 dd_td;	 // telldir position recording
}

struct s_componentname {
	nameiop cn_nameiop;	// namei operation
	uint32 cn_flags;	// flags to namei
	s_proc cn_proc;	    // process requesting lookup
	s_ucred cn_cred;	// credentials
	string cn_pnbuf;	// pathname buffer
	string cn_nameptr;	// pointer to looked up name
	uint8 cn_namelen;	// length of looked up component
	uint32 cn_hash;	    // hash value of looked up name
}

struct s_nameidata {
    string ni_dirp;     // pathname pointer
	uio_seg ni_segflg;	// location of pathname
	uint16 ni_startdir; // starting directory
	uint16 ni_rootdir;	// logical root directory
    uint16 ni_topdir;	// logical top directory
    uint16 dir_fd;      // starting directory for *at functions
	uint16 ni_vp;		// vnode of result
	uint16 ni_dvp;		// vnode of intermediate directory
	uint16 ni_pathlen;	// remaining chars in path
	string ni_next;		// next location in pathname
	uint8 ni_loopcnt;	// count of symlinks encountered
	s_componentname ni_cnd;
}

struct s_namecache {
	uint16 nc_dvp;	  // vnode of parent of name
	uint32 nc_dvpid;  // capability number of nc_dvp
	uint16 nc_vp;	  // vnode the name refers to
	uint32 nc_vpid;   // capability number of nc_vp
	uint8 nc_nlen;	  // length of name
	string nc_name;	  // segment name
}

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
    s_bufobj v_bufobj;      // Buffer cache object
    uint16 v_iflag;          // vnode flags (see below)
    uint16 v_vflag;         // vnode flags
    uint16 v_mflag;         // mnt-specific vnode flags
}

struct s_ucred {
    uint16 cr_users;       // (c) proc + thread using this cred
    uint16 cr_uid;         // effective user id
    uint16 cr_ruid;        // real user id
    uint16 cr_svuid;       // saved user id
    uint8 cr_ngroups;      // number of groups
    uint16 cr_rgid;        // real group id
    uint16 cr_svgid;       // saved group id
    string cr_loginclass;  // login class
    uint16 cr_flags;       // credential flags
    uint16[] cr_groups;    // groups
}

struct s_ar_misc {
    string argv;
    string flags;
    string sargs;
    uint16 n_params;
    string[] pos_params;
    uint8 ec;
    string last_param;
    string opt_err;
    string redir_in;
    string redir_out;
    s_dirent[] pos_args;
    string[][2] opt_values;
}

struct s_opt_arg {
    string opt_name;
    string opt_value;
}
struct s_pargs {
    uint16 ar_length; // Length.
    string[] ar_args; // Arguments.
    s_ar_misc ar_misc;
}

struct s_ps_strings {
    string[] ps_argvstr; // first of 0 or more argument strings
    uint16 ps_nargvstr;  // the number of argument strings
    string[] ps_envstr;  // first of 0 or more environment strings
    uint16 ps_nenvstr;   // the number of environment strings
}

struct s_proc {
    s_ucred p_ucred;     // Process owner's identity.
    s_xfiledesc p_fd;    // Open files.
    s_xpwddesc p_pd;     // Cwd, chroot, jail, umask
    s_plimit p_limit;    // Resource limits.
    uint32 p_flag;       // P_* flags.
    uint16 p_pid;        // Process identifier.
    uint16 p_oppid;      // Real parent pid.
    string p_comm;       // Process name.
    s_sysent[] p_sysent; // Syscall dispatch info.
    s_pargs p_args;      // Process arguments.
    string[] environ;
    uint16 p_xexit;      // Exit code.
    uint16 p_numthreads; // Number of threads.
    uint16 p_leader;
}

struct s_thread {
    s_proc td_proc;         // Associated process.
    uint16 td_tid;          // Thread ID.
    uint16 td_flags;        // TDF_* flags.
    uint16 td_dupfd;        // Ret value from fdopen. XXX
    s_ucred td_realucred;   // Reference to credentials.
    s_ucred td_ucred;       // Used credentials, temporarily switchable.
    s_plimit td_limit;      // Resource limits.
    string td_name;         // Thread name.
    uint16 td_errno;        // Error from last syscall.
    td_states td_state;     // thread state
    uint32 tdu_retval;
}

// Header element for a unr number space.
struct s_unrhdr {
    uint16 low;    // Lowest item
    uint16 high;   // Highest item
    uint16 busy;   // Count of allocated items
    uint16 alloc;  // Count of memory allocations
    uint16 first;  // items in allocated from start
    uint16 last;   // items free at end
}

struct s_prstatus {
    uint16 pr_version;   // Version number of struct (1)
    uint16 pr_osreldate; // Kernel version (1)
    uint16 pr_cursig;    // Current signal (1)
    uint16 pr_pid;       // LWP (Thread) ID (1)
}
struct s_prpsinfo {
    uint16 pr_version;  // Version number of struct (1)
    string pr_fname;    // Command name, null terminated (1) [PRFNAMESZ+1]
    string pr_psargs;   // Arguments, null terminated (1) [PRARGSZ+1];
    uint16 pr_pid;      // Process ID (1a)
}
struct s_thrmisc {
    string pr_tname; // Thread name, null terminated (1) [MAXCOMLEN+1];
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

struct s_xfiledesc {
    uint16 fdt_nfiles;  // number of open files allocated
    s_of[] fdt_ofiles;  // open files
//    uint64 fd_map;      // bitmap of free fds
//    uint16 fd_freefile; // approx. next free file
//    uint16 fd_refcnt;   // thread reference count
}

struct s_xpwddesc {
    s_of pwd_cdir;
    s_of pwd_rdir;
//    s_of pwd_jdir;
    uint16 pd_cmask; // mask for file creation
}

struct s_buf {
    uint32 b_bcount;  //  originally requested buffer size, can serve as a bounds check against EOF.  For most, but not all uses, b_bcount == b_bufsize.
    uint32 b_data;
    uint8  b_error;
    uint16 b_iocmd;   // BIO_* bio_cmd from bio.h
    uint16 b_ioflags; // BIO_* bio_flags from bio.h
    uint32 b_iooffset;
    uint32 b_resid;  // Number of bytes remaining in I/O.  After an I/O operation completes, b_resid is usually 0 indicating 100% success.
    uint64 b_ckhash; // B_CKHASH requested check-hash
    uint32 b_blkno;  // Underlying physical block number.
    uint32 b_offset; // Offset into file.
    uint32 b_vflags; // BV_* flags
    uint32 b_flags;  // B_* flags.
    uint16 b_xflags; // extra flags
    uint32 b_bufsize;// Allocated buffer size.
    uint32 b_kvasize;// size of kva for buffer
    // Buffers support piecemeal, unaligned ranges of dirty data that need to be written to backing store.
    // The range is typically clipped at b_bcount (not b_bufsize).
    uint32 b_dirtyoff; // Offset in buffer of dirty region.
    uint32 b_dirtyend; // Offset of end of dirty region.
    uint32 b_kvabase;  // base kva for buffer
    uint32 b_lblkno;   // Logical block number.
    uint16 b_vp;       // Device vnode.
    s_ucred b_rcred;   // Read credentials reference.
    s_ucred b_wcred;   // Write credentials reference.
    uint16 b_npages;
}

struct s_bufv {
    s_buf[] bv_hd; // Sorted blocklist
    uint16 bv_cnt; // Number of buffers
}

struct s_bufobj {
    bytes bo_private;    // private pointer
    s_buf[] bo_clean;     // Clean buffers
    s_buf[] bo_dirty;     // Dirty buffers
    uint16 bo_numoutput; // Writes in progress
    uint16 bo_flag;      // Flags
    uint16 bo_bsize;     // Block size for i/o
}

/*struct s_smr_shared {
    string sm_name;   // Name for debugging/reporting.
    uint64 sm_wr_seq; // Write sequence
    uint32 sm_rd_seq; // Minimum observed read sequence.
}

struct s_smr {
    uint32 c_seq;          // Current observed sequence.
    s_smr_shared c_shared; // Shared SMR state.
    uint32 c_deferred;     // Deferred advance counter.
    uint32 c_limit;        // Deferred advance limit.
    uint32 c_flags;        // SMR Configuration
}*/

//enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }
/*struct s_thread {
    s_proc td_proc;         // Associated process.
    uint16 td_tid;          // Thread ID.
    // Cleared during fork
    uint16 td_flags;        // TDF_* flags.
    uint16 td_dupfd;        // Ret value from fdopen. XXX
    s_ucred td_realucred;   // Reference to credentials.
    s_ucred td_ucred;       // Used credentials, temporarily switchable.
    s_plimit td_limit;      // Resource limits.
    string td_name;         // Thread name.
    s_file td_fpop;         // file referencing cdev under op
    s_xvnode td_vp_reserved; // Prealloated vnode.
    uint32 td_sleeptimo;    // Sleep timeout.
    uint16 td_errno;        // Error from last syscall.
    uint16 td_ucredref;     // references on td_realucred
    // Fields that must be manually set in fork1() or create_thread()
    // or already have been set in the allocator, constructor, etc.
    td_states td_state;     // thread state
    uint32 tdu_off;
    s_proc td_rfppwait_p;   // The vforked child
}*/