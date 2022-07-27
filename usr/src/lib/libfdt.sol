pragma ton-solidity >= 0.62.0;

import "sbuf.sol";
import "xio.sol";
import "liberr.sol";
import "filedesc_h.sol";
import "proc_h.sol";
import "libstat.sol";
import "dirent.sol";
import "path.sol";
library libfdt {

    using xio for s_of;
    using sbuf for s_sbuf;
    uint8 constant STDIN_FILENO  = 0;
    uint8 constant STDOUT_FILENO = 1;
    uint8 constant STDERR_FILENO = 2;
    uint8 constant ERRNO_FILENO  = 3;

    uint16 constant SYS_open   = 5;
    uint16 constant SYS_close  = 6;
    uint16 constant SYS_chdir  = 12;
    uint16 constant SYS_fchdir = 13;
    uint16 constant SYS_access = 33;
    uint16 constant SYS_dup    = 41;
    uint16 constant SYS_umask  = 60;
    uint16 constant SYS_getdtablesize = 89;
    uint16 constant SYS_dup2   = 90;
    uint16 constant SYS_freebsd11_getdents  = 272;
    uint16 constant SYS___getcwd    = 326;
    uint16 constant SYS_openat             = 499;
    uint16 constant SYS_freebsd12_closefrom = 509;
    uint16 constant SYS_getdirentries      = 554;
    uint16 constant SYS_close_range        = 575;

    using libfdt for s_thread;
    using libfdt for s_of[];
    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS___getcwd) return 0;
        else if (n == SYS_chdir || n == SYS_fchdir || n == SYS_close || n == SYS_freebsd11_getdents || n == SYS_getdirentries || n == SYS_dup || n == SYS_freebsd12_closefrom || n == SYS_umask)
            return 1;
        else if (n == SYS_open || n == SYS_access || n == SYS_close_range)
            return 2;
    }

    function syscall_ids() internal returns (uint16[]) {
        return [SYS_open, SYS_chdir, SYS_fchdir, SYS___getcwd, SYS_close, SYS_access, SYS_freebsd11_getdents, SYS_getdirentries, SYS_dup, SYS_freebsd12_closefrom, SYS_close_range, SYS_umask];
    }

    function syscall_name(uint16 number) internal returns (string) {
        if (number == SYS_open) return "open";
        if (number == SYS_chdir) return "chdir";
        if (number == SYS_fchdir) return "fchdir";
        if (number == SYS___getcwd) return "__getcwd";
        if (number == SYS_close) return "close";
        if (number == SYS_access) return "access";
        if (number == SYS_freebsd11_getdents) return "getdents";
        if (number == SYS_getdirentries) return "getdirentries";
        if (number == SYS_dup) return "dup";
        if (number == SYS_freebsd12_closefrom) return "closefrom";
        if (number == SYS_close_range) return "close_range";
        if (number == SYS_umask) return "umask";
    }
    function _get_dirent(s_dirent[] des, string sp) internal returns (s_dirent) {
        for (s_dirent de: des) {
            if (de.d_name == sp)
                return de;
        }
    }
    function chdir(s_thread t) internal returns (s_of cdir) {
        return t.td_proc.p_pd.pwd_cdir;
    }
    function open(s_thread t, string sp, uint16 mode) internal returns (uint8 ec, uint16 rv) {
        bool abspath = sp.substr(0, 1) == "/";
        if (abspath) {
            uint fd = fdfetch(t.td_proc.p_fd.fdt_ofiles, sp);
            if (fd > 0) {
                rv = t.td_proc.p_fd.fdt_ofiles[fd - 1].file;
                return (ec, rv);
            }
            (string sdir, string snotdir) = path.dir(sp);
//            (ec, idx) = access(t, sdir, mode | O_DIRECTORY);
            uint16 didx;
            uint16 fidx;
            (ec, didx) = access(t, sdir, mode | O_DIRECTORY);
            (ec, rv) = access(t, snotdir, mode);
            if (ec == 0)
                rv = fidx;
        }

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

    function lookup_dir(s_of[] t, string s) internal returns (uint8 ec, s_of df) {
        uint n = fdfetch(t, s);
        if (n > 0) {
            df = t[n - 1];
            if (!libstat.is_dir(libstat.st_mode(df.attr)))
                ec = err.ENOTDIR;
        } else
            ec = err.ENOENT;
    }

    function lookup(s_of[] t, uint16 dfd, string s) internal returns (uint8 ec, s_dirent de) {
        s_of dd;
        (ec, dd) = fdopen(t, dfd);
        if (ec == 0) {
            uint16 mode = libstat.st_mode(dd.attr);
            if (libstat.is_dir(mode)) {
                (string[] lines, ) = libstring.split(dd.buf.buf, "\n");
                for (string line: lines) {
                    s_dirent d0 = dirent.parse_dirent(line);
                    if (d0.d_name == s)
                        return (ec, d0);
                }
                ec = err.ENOENT;
            } else
                ec = err.EINVAL;
        }
    }
    function getdents(s_thread t, uint16 fd) internal returns (uint8 ec, s_dirent[] dirents) {
//        ec = 0;
        s_of[] fdt = t.td_proc.p_fd.fdt_ofiles;
//        if (fd < fdt.length) {
//            s_of dd = fdt[fd];
        s_of dd;
        (ec, dd) = fdopen(fdt, fd);
        if (ec == 0) {
            uint16 mode = libstat.st_mode(dd.attr);
            if (libstat.is_dir(mode)) {
                string bf = dd.buf.buf;
                (string[] lines, ) = libstring.split(bf, "\n");
                for (string line: lines)
                    dirents.push(dirent.parse_dirent(line));
            } else
                ec = err.EINVAL;
        }
    }

    function fdt_syscall(s_thread td, uint16 number, string[] args) internal {
        td.do_syscall(number, args);
    }
    function do_syscall(s_thread td, uint16 number, string[] args) internal {
        uint16 rv;
        uint8 ec;
        s_dirent[] dirents;
        s_of[] fdt_in = td.td_proc.p_fd.fdt_ofiles;
        s_of[] fdt;
//        uint len = fdt_in.length;
        uint n_args = args.length;
        string sarg1 = n_args > 0 ? args[0] : "";
        string sarg2 = n_args > 1 ? args[1] : "";
        uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
        uint16 arg2 = n_args > 1 ? str.toi(sarg2) : 0;
        if (number == SYS___getcwd) {
            rv = libstat.st_ino(td.td_proc.p_pd.pwd_cdir.attr);
            if (rv > 0)
                ec == 0;
        } else if (number == SYS_chdir || number == SYS_fchdir) {
            fdt = fdt_in;
            s_proc p = td.td_proc;
            s_xpwddesc pd = p.p_pd;
            s_of nd;
            if (number == SYS_fchdir) {
                (ec, nd) = fdopen(fdt_in, arg1);
                if (ec == 0) {
                    if (!libstat.is_dir(libstat.st_mode(nd.attr)))
                        ec = err.ENOTDIR;
                    else
                        td.td_proc.p_pd.pwd_cdir = nd;
                }
            } else if (number == SYS_chdir) {
                bool abspath = sarg1.substr(0, 1) == "/";
                s_of dd = abspath ? pd.pwd_rdir : pd.pwd_cdir;
                s_of fpd;
                (ec, fpd) = lookup_dir(fdt, abspath ? sarg1 : dd.path + sarg1);
                if (ec == 0)
                    td.td_proc.p_pd.pwd_cdir = fpd;
            }
        } else if (number == SYS_dup) {
            s_of f;
            (ec, f) = fdopen(fdt, arg1);
            if (ec == 0)
                td.td_proc.p_fd.fdt_ofiles.fddup(arg1);
        } else if (number == SYS_open) {
            fdt = fdt_in;
            s_xpwddesc pd = td.td_proc.p_pd;
//            uint16 mode = mode_to_flags(sarg2);
            bool abspath = sarg1.substr(0, 1) == "/";
            s_of dd = abspath ? pd.pwd_rdir : pd.pwd_cdir;
            (ec, dirents) = getdents(td, dd.file);
            s_dirent de;
            if (abspath) {
                uint n = fdfetch(fdt, sarg1);
                if (n > 0) {
                    td.td_retval = uint32(n - 1);
                    return;
                }
                (string sdir, string snotdir) = path.dir(sarg1);
                s_of fpd;
                (ec, fpd) = lookup_dir(fdt, sdir);
                if (ec == 0)
                    (ec, de) = lookup(fdt, fpd.file, snotdir);
            } else
                (ec, de) = lookup(fdt, dd.file, sarg1);
            if (ec == 0) {
                uint16 dem = dirent.DTTOIF(de.d_type);
                uint attr = (uint(de.d_fileno) << 208) + (uint(dem) << 192);
                s_sbuf buf;
                fdt.push(s_of(attr, 0, uint16(fdt.length), sarg1, 0, buf));
            }
            if (ec == 0) {
                td.td_proc.p_fd.fdt_ofiles = fdt;
                td.td_proc.p_fd.fdt_nfiles = uint16(fdt.length);
            }
        }  else if (number == SYS_close || number == SYS_freebsd12_closefrom || number == SYS_close_range) {
            if (number == SYS_close) {
                fdt = fdt_in;
                if (arg1 < fdt.length)
                    delete fdt[arg1];
                else
                    ec = err.EBADF;
            } else if (number == SYS_freebsd12_closefrom) {
                for (s_of f: fdt_in) {
                    if (f.file < arg1)
                        fdt.push(f);
                }
            } else if (number == SYS_close_range) {
                for (s_of f: fdt_in) {
                    if (f.file < arg1 || f.file > arg2)
                        fdt.push(f);
                }
            }
            if (ec == 0) {
                td.td_proc.p_fd.fdt_ofiles = fdt;
                td.td_proc.p_fd.fdt_nfiles = uint16(fdt.length);
            }
        } else if (number == SYS_access) {
            (ec, rv) = access(td, sarg1, mode_to_flags(sarg2));
        } else if (number == SYS_freebsd11_getdents || number == SYS_getdirentries) {
            if (number == SYS_freebsd11_getdents)
                (ec, dirents) = getdents(td, arg1);
        } else if (number == SYS_umask) {
            rv = arg1;
        } else
            ec = err.ENOSYS;
        td.td_errno = ec;
        td.td_retval = rv;
    }
    uint16 constant O_RDONLY    = 0;
    uint16 constant O_WRONLY    = 1;
    uint16 constant O_RDWR      = 2;
    uint16 constant O_ACCMODE   = 3;
    uint16 constant O_LARGEFILE = 16;
    uint16 constant O_DIRECTORY = 32;
    uint16 constant O_NOFOLLOW  = 64;
    uint16 constant O_CLOEXEC   = 128;
    uint16 constant O_CREAT     = 256;
    uint16 constant O_EXCL      = 512;
    uint16 constant O_NOCTTY    = 1024;
    uint16 constant O_TRUNC     = 2048;
    uint16 constant O_APPEND    = 4096;
    uint16 constant O_NONBLOCK  = 8192;
    uint16 constant O_DSYNC     = 16384;
    uint16 constant FASYNC      = 32768;
    function mode_to_flags(string mode) internal returns (uint16 flags) {
        if (mode == "r" || mode == "rb")
            flags |= O_RDONLY;
        if (mode == "w" || mode == "wb")
            flags |= O_WRONLY;
        if (mode == "a" || mode == "ab")
            flags |= O_APPEND;
        if (mode == "r+" || mode == "rb+" || mode == "r+b")
            flags |= O_RDWR;
        if (mode == "w+" || mode == "wb+" || mode == "w+b")
            //Truncate to zero length or create file for update.
            flags |= O_TRUNC | O_CREAT;
        if (mode == "a+" || mode == "ab+" || mode == "a+b")
            // Append; open or create file for update, writing at end-of-file.
            flags |= O_APPEND | O_CREAT;
    }

    function fdfetch(s_of[] t, string path) internal returns (uint) {
        for (uint i = 0; i < t.length; i++)
            if (t[i].path == path)
                return i + 1;
    }

    function fderror(s_of[] t, uint8 ec, string reason) internal {
        s_of f = t[STDERR_FILENO];
        string err_msg = err.strerror(ec);
        f.buf.error = ec;
        if (!reason.empty())
            err_msg.append(reason + " ");
        f.fputs(err_msg);
        t[STDERR_FILENO] = f;
    }

    function fdflush(s_of[] t) internal returns (string out, string err) {
        out = t[STDOUT_FILENO].fflush();
        err = t[STDERR_FILENO].fflush();
//        t[3].fflush();
    }

    function fderrno(s_of[] t) internal returns (uint8) {
        s_of f = t[STDERR_FILENO];
        return f.buf.error;
    }

    function fdputs(s_of[] t, string str) internal {
        t[STDOUT_FILENO].fputs(str + "\n");
//        f.fputs(str);
//        t[STDOUT_FILENO] = f;
    }
    function fdfputs(s_of[] t, string str, s_of f) internal {
        uint16 idx = f.fileno();
        if (idx >= 0 && idx < t.length) {
            f.fputs(str);
            t[idx] = f;
        }
    }
    function fdputchar(s_of[] t, byte c) internal {
        s_sbuf s = t[STDOUT_FILENO].buf;
        s.sbuf_putc(c);
        t[STDOUT_FILENO].buf = s;
    }
    function fdstdin(s_of[] t) internal returns (s_of) {
        return t[STDIN_FILENO];
    }
    function fdstdout(s_of[] t) internal returns (s_of) {
        return t[STDOUT_FILENO];
    }
    function fdstderr(s_of[] t) internal returns (s_of) {
        return t[STDERR_FILENO];
    }

    function getdirdesc(s_of[] t, uint16 fd) internal returns (s_dirdesc) {
        (uint8 ec, s_of f) = fdopen(t, fd);
        if (ec == 0)
            return s_dirdesc(f.file, 0, uint16(f.buf.size), f.buf.buf, uint16(f.buf.size), 0, 0, 0);
    }

    function opendir(s_of[] t, string filename) internal returns (s_dirdesc) {
        uint n = fdfetch(t, filename);
        if (n > 0)
            return getdirdesc(t, uint16(n - 1));
    }

    function fdopendir(s_of[] t, uint16 fd) internal returns (s_dirdesc) {
        return getdirdesc(t, fd);
    }
    function fdopen(s_of[] t, uint16 fd) internal returns (uint8 ec, s_of) {
        for (s_of f: t)
            if (f.file == fd)
                return (ec, f);
        ec = err.EBADF;
    }
    function fddup(s_of[] t, uint16 fd) internal {
        (, s_of f) = fdopen(t, fd);
        f.file = uint16(t.length);
        t.push(f);
    }
}
