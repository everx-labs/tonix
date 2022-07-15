pragma ton-solidity >= 0.62.0;
import "sbuf_h.sol";
import "ucred_h.sol";
struct s_xfile {
//    uint16 xf_size;     // size of struct xfile
    uint16 xf_pid;      // owning process
    uint16 xf_uid;      // effective uid of owning process
    uint16 xf_fd;       // descriptor number
    uint8  xf_type;     // descriptor type
    uint16 xf_count;    // reference count
    uint16 xf_msgcount; // references from message queue
    uint32 xf_offset;   // file offset
    bytes xf_data;      // file descriptor specific data
    uint16 xf_vnode;    // vnode pointer
    uint16 xf_flag;     // flags (see fcntl.h)
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

struct s_of {
    uint attr;
    uint16 flags;
    uint16 file;
    string path;
    uint32 offset;
    s_sbuf buf;
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

struct s_fadvise_info {
    uint32 fa_advice; // FADV_* type
    uint32 fa_start;  // Region start
    uint32 fa_end;    // Region end
}
struct s_file {
    uint16 f_flag;    // see fcntl
    bytes f_data;     // file descriptor specific data
//  s_vnode f_vnode;  // NULL or applicable vnode
    s_ucred f_cred;   // associated credentials
    uint8 f_type;     // descriptor type
    uint32[2] f_nextoff; // next expected read/write offset
    s_fadvise_info fvn_advice;
    uint32 f_offset;
}

