pragma ton-solidity >= 0.62.0;

import "io.sol";
//import "liberr.sol";
import "path.sol";
import "priv.sol";
import "dirent.sol";
struct timeval {
    uint32 mtime;
    uint32 ctime;
}

library libfattr {

    uint8 constant EBADF    = 9; // Bad file descriptor
    uint8 constant EINVAL   = 22; // Invalid argument
    uint8 constant ENOSYS       = 78; // Function not implemented

    using libfattr for s_thread;

//    priv.priv_check(t, )
    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS_fstat)
            return 1;
        else if (n == SYS_chmod || n == SYS_chown || n == SYS_chflags || n == SYS_fchflags || n == SYS_symlink || n == SYS_readlink || n == SYS_fchown || n == SYS_fchmod || n == SYS_rename || n == SYS_mkdir || n == SYS_rmdir || n == SYS_utimes || n == SYS_futimes || n == SYS_lchown || n == SYS_lchmod || n == SYS_lutimes || n == SYS_eaccess || n == SYS_faccessat || n == SYS_fchmodat || n == SYS_fchownat || n == SYS_futimesat || n == SYS_linkat || n == SYS_mkdirat || n == SYS_mkfifoat || n == SYS_readlinkat || n == SYS_renameat || n == SYS_symlinkat || n == SYS_unlinkat || n == SYS_fstatat || n == SYS_statfs || n == SYS_fstatfs || n == SYS_getfsstat || n == SYS_mknodat)
            return 2;
    }

    function syscall_ids() internal returns (uint16[]) {
//        return [SYS_chmod, SYS_chown, SYS_chflags, SYS_fchflags, SYS_symlink, SYS_readlink, SYS_fchown, SYS_fchmod, SYS_rename, SYS_mkdir, SYS_rmdir, SYS_utimes, SYS_futimes, SYS_lchown, SYS_lchmod, SYS_lutimes, SYS_eaccess, SYS_faccessat, SYS_fchmodat, SYS_fchownat, SYS_futimesat, SYS_linkat, SYS_mkdirat, SYS_mkfifoat, SYS_readlinkat, SYS_renameat, SYS_symlinkat, SYS_unlinkat, SYS_fstat, SYS_fstatat, SYS_statfs, SYS_fstatfs, SYS_getfsstat, SYS_mknodat];
        return [SYS_chmod, SYS_chown, SYS_chflags, SYS_fchflags, SYS_symlink, SYS_readlink, SYS_fchown, SYS_fchmod, SYS_rename, SYS_mkdir, SYS_rmdir, SYS_utimes, SYS_futimes, SYS_lchown, SYS_lchmod, SYS_lutimes, SYS_eaccess, SYS_fstat];
    }
    function access(s_thread t, string sp, uint16 mode) internal returns (uint8 ec, uint16 idx) {
        bool abspath = sp.substr(0, 1) == "/";
        s_of dd = abspath ? t.td_proc.p_pd.pwd_rdir : t.td_proc.p_pd.pwd_cdir;
        uint16 dfd;
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
            (ec, des) = getdents(t, dd.file);
            if (ec == 0)
                res = _get_dirent(des, sp);
        }
	    idx = res.d_fileno;
    }

    function getdents(s_thread t, uint16 fd) internal returns (uint8 ec, s_dirent[] dirents) {
        ec = 0;
        s_of[] fdt = t.td_proc.p_fd.fdt_ofiles;
        if (fd < fdt.length) {
            s_of dd = fdt[fd];
            uint16 mode = libstat.st_mode(dd.attr);
            if (libstat.is_dir(mode)) {
                string bf = dd.buf.buf;
                (string[] lines, ) = libstring.split(bf, "\n");
                for (string line: lines)
                    dirents.push(dirent.parse_dirent(line));
            } else
                ec = EINVAL;
        } else
            ec = EBADF;
    }

    function _get_dirent(s_dirent[] des, string sp) internal returns (s_dirent) {
        for (s_dirent de: des) {
            if (de.d_name == sp)
                return de;
        }
    }
    uint16 constant SYS_freebsd11_mknod = 14;
    uint16 constant SYS_chmod      = 15;
    uint16 constant SYS_chown      = 16;
    uint16 constant SYS_chflags    = 34;
    uint16 constant SYS_fchflags   = 35;
    uint16 constant SYS_symlink    = 57;
    uint16 constant SYS_readlink   = 58;
    uint16 constant SYS_fchown     = 123;
    uint16 constant SYS_fchmod     = 124;
    uint16 constant SYS_rename     = 128;
    uint16 constant SYS_mkfifo     = 132;
    uint16 constant SYS_mkdir      = 136;
    uint16 constant SYS_rmdir      = 137;
    uint16 constant SYS_utimes     = 138;
    uint16 constant SYS_freebsd11_stat  = 188;
    uint16 constant SYS_freebsd11_fstat = 189;
    uint16 constant SYS_freebsd11_lstat = 190;
    uint16 constant SYS_futimes    = 206;
    uint16 constant SYS_lchown     = 254;
    uint16 constant SYS_lchmod     = 274;
    uint16 constant SYS_lutimes    = 276;
    uint16 constant SYS_eaccess    = 376;
    uint16 constant SYS_faccessat  = 489;
    uint16 constant SYS_fchmodat   = 490;
    uint16 constant SYS_fchownat   = 491;
    uint16 constant SYS_futimesat  = 494;
    uint16 constant SYS_linkat     = 495;
    uint16 constant SYS_mkdirat    = 496;
    uint16 constant SYS_mkfifoat   = 497;
    uint16 constant SYS_readlinkat = 500;
    uint16 constant SYS_renameat   = 501;
    uint16 constant SYS_symlinkat  = 502;
    uint16 constant SYS_unlinkat   = 503;
    uint16 constant SYS_fstat      = 551;
    uint16 constant SYS_fstatat    = 552;
    uint16 constant SYS_statfs     = 555;
    uint16 constant SYS_fstatfs    = 556;
    uint16 constant SYS_getfsstat  = 557;
    uint16 constant SYS_mknodat    = 559;

    function syscall_name(uint16 number) internal returns (string) {
        mapping (uint16 => string) d;
        d[SYS_chmod] = "chmod";
        d[SYS_chown] = "chown";
        d[SYS_chflags] = "chflags";
        d[SYS_fchflags] = "fchflags";
        d[SYS_symlink] = "symlink";
        d[SYS_readlink] = "readlink";
        d[SYS_fchown] = "fchown";
        d[SYS_fchmod] = "fchmod";
        d[SYS_rename] = "rename";
        d[SYS_mkdir] = "mkdir";
        d[SYS_rmdir] = "rmdir";
        d[SYS_utimes] = "utimes";
        d[SYS_futimes] = "futimes";
        d[SYS_lchown] = "lchown";
        d[SYS_lchmod] = "lchmod";
        d[SYS_lutimes] = "lutimes";
        d[SYS_eaccess] = "eaccess";
        d[SYS_faccessat] = "faccessat";
        d[SYS_fchmodat] = "fchmodat";
        d[SYS_fchownat] = "fchownat";
        d[SYS_futimesat] = "futimesat";
        d[SYS_linkat] = "linkat";
        d[SYS_mkdirat] = "mkdirat";
        d[SYS_mkfifoat] = "mkfifoat";
        d[SYS_readlinkat] = "readlinkat";
        d[SYS_renameat] = "renameat";
        d[SYS_symlinkat] = "symlinkat";
        d[SYS_unlinkat] = "unlinkat";
        d[SYS_fstat] = "fstat";
        d[SYS_fstatat] = "fstatat";
        d[SYS_statfs] = "statfs";
        d[SYS_fstatfs] = "fstatfs";
        d[SYS_getfsstat] = "getfsstat";
        d[SYS_mknodat] = "mknodat";
        return d[number];
    }

    function fattr_syscall(s_thread td, uint16 number, string[] args, uint[] attrs_in) internal returns (uint[] attrs) {
        return td.do_syscall(number, args, attrs_in);
    }
    function do_syscall(s_thread td, uint16 number, string[] args, uint[] attrs_in) internal returns (uint[] attrs) {
        uint8 ec;
        uint16 rv;
        attrs = attrs_in;
//        s_of[] fdt = td.td_proc.p_fd.fdt_ofiles;
//        uint len = fdt.length;
        uint n_args = args.length;
        string sarg1 = n_args > 0 ? args[0] : "";
//        string sarg2 = n_args > 1 ? args[1] : "";
//        uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
//        uint16 arg2 = n_args > 1 ? str.toi(sarg2) : 0;
        uint16 idx;
        uint atin;
//        uint atout;
        uint16 mode;
//        s_stat stt;
        if (number == SYS_freebsd11_stat || number == SYS_freebsd11_lstat || number == SYS_freebsd11_fstat || number == SYS_fstatat) {
            if (number == SYS_freebsd11_stat || number == SYS_freebsd11_lstat) {
                (ec, idx) = access(td, sarg1, mode);
                if (ec > 0)
                    atin = attrs[idx];
            } else if (number == SYS_freebsd11_fstat) {
                (ec, idx) = access(td, sarg1, mode);
            }
        } else if (number == SYS_utimes || number == SYS_lutimes || number == SYS_futimes || number == SYS_futimesat) {
            if (number == SYS_utimes || number == SYS_lutimes) {
                (ec, idx) = access(td, sarg1, mode);
                if (ec > 0)
                    atin = attrs[idx];
//                if (libstat.is_symlink())
            } else if (number == SYS_futimes) {

            }
        } else
            ec = ENOSYS;
//        if (number == SYS_mkdir)
        td.td_errno = ec;
        td.td_retval = rv;
    }

}