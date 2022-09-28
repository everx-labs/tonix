pragma ton-solidity >= 0.62.0;
import "proc_h.sol";
import "uio_h.sol";
import "bufobj_h.sol";
enum nameiop { LOOKUP, CREATE, DELETE, RENAME }

struct s_componentname {
    nameiop cn_nameiop;	// namei operation
    uint32 cn_flags;    // flags to namei
    s_proc cn_proc;     // process requesting lookup
    s_ucred cn_cred;    // credentials
    string cn_pnbuf;    // pathname buffer
    string cn_nameptr;  // pointer to looked up name
    uint8 cn_namelen;   // length of looked up component
    uint32 cn_hash;     // hash value of looked up name
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
    string ni_next;     // next location in pathname
    uint8 ni_loopcnt;   // count of symlinks encountered
    s_componentname ni_cnd;
}
struct s_namecache {
    uint16 nc_dvp;   // vnode of parent of name
    uint32 nc_dvpid; // capability number of nc_dvp
    uint16 nc_vp;    // vnode the name refers to
    uint32 nc_vpid;  // capability number of nc_vp
    uint8 nc_nlen;   // length of name
    string nc_name;  // segment name
}
