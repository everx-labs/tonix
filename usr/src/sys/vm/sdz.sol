pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "sys/vn.sol";
import "sys/priv.sol";

/* Generic block device hosting a generic file system */
contract sdz is Utility {

    using libstat for s_stat;
    using vn for s_vnode;
    // Vnode attributes.  A field value of VNOVAL represents a field whose value is unavailable (getattr) or which is not to be changed (setattr).
    /*struct s_vattr {
        uint8 va_type;      // vnode type (for create)
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
    }*/
    /*struct s_of {
        uint attr;
        uint16 flags;
        uint16 file;
        string path;
        uint32 offset;
        s_sbuf buf;
    }*/
//    s_of[] _fdt;
    s_vnode[] _vns;
    bytes[][] _data;

    function getnewvnode() internal returns (s_vnode) {
        s_vattr v_attrs;
        bytes empty;
//        return s_vnode(vtype.VREG, 0, 0, 0, v_attrs, empty);
    }

    function _mmu(uint32 kaddr) internal pure returns (uint8 buck, uint8 chunk, uint16 offset) {
        return (uint8(kaddr >> 24), uint8(kaddr >> 16 & 0xFF), uint16(kaddr & 0xFFFF));
    }
    function copyin(bytes uaddr, uint32 kaddr, uint16 len) external returns (uint16) {
        (uint8 buck, uint8 chunk, uint16 offset) = _mmu(kaddr);
        bytes tgt = _data[buck][chunk];
        if (offset == 0)
            _data[buck][chunk] = uaddr;
        else {
            bytes hd = string(tgt).substr(0, offset);
            hd.append(uaddr);
            _data[buck][chunk] = hd;
        }
    }

    function copyout(uint32 kaddr, uint16 len) external view returns (bytes uaddr) {
        (uint8 buck, uint8 chunk, uint16 offset) = _mmu(kaddr);
        bytes tgt = _data[buck][chunk];
        uaddr = offset > 0 ? string(tgt).substr(offset, len) : tgt;
    }

    function open(s_proc p_in, string path, uint16 flags) external returns (s_proc p, uint16 count) {
        p = p_in;
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        s_of f;
        for (uint i = 0; i < n_files; i++) {
            f = fdt[i];
            if (f.path == path) {
                s_stat st;
                st.stt(f.attr);
                if (st.st_uid == p.p_ucred.cr_uid || st.st_gid == p.p_ucred.cr_groups[0])
                    break;
            }
        }
        s_vnode v = getnewvnode();
        s_vattr sv = v.set_stats(f.attr);
        v.v_attrs = sv;
        _vns.push(v);
    }
    /*function openat(s_proc p_in, uint8 fd, string path, int flags) external view returns (s_proc p, uint16 count) {
        tvm.accept();
        s_of f = _fdt[fd];
        p = p_in;
    }*/

    function lseek(s_proc p_in, uint8 fd, uint32 offset, uint8 whence) external view returns (s_proc p, uint16 count) {
        tvm.accept();
//        s_of f = _fdt[fd];
        p = p_in;
    }

    function write(s_proc p_in, uint8 fd, bytes buf, uint16 nbytes) external view returns (s_proc p, uint16 count) {
        tvm.accept();
//        s_of f = _fdt[fd];
        p = p_in;

    }
    function pwrite(uint8 fd, bytes buf, uint16 nbytes, uint32 offset) external returns (uint16 count) {

    }


    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"sdz",
"[OPTION]... FILE...",
"test file system",
"Used for file system operations testing.",
"-c      do not create any files\n\
-m      change only the modification time",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
