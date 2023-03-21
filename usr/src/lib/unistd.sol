pragma ton-solidity >= 0.61.2;

import "proc_h.sol";
import "libpgroup.sol";
import "libsyscall.sol";
import "conf.sol";

struct s_crypt_data {
    bool initialized;  // For compatibility with glibc.
    string __buf;     // Buffer returned by crypt_r().
}

library unistd {

    using libstat for s_stat;
    using io for s_thread;
    using sbuf for s_sbuf;
    using libucred for s_ucred;
    using libsyscall for s_thread;

    uint8 constant F_ULOCK = 0; // unlock locked section
    uint8 constant F_LOCK  = 1; // lock a section for exclusive use
    uint8 constant F_TLOCK = 2; // test and lock a section for exclusive use
    uint8 constant F_TEST  = 3; // test a section for locks by other procs

    uint16 constant SLBF  = 0x0001; // line buffered
    uint16 constant SNBF  = 0x0002; // unbuffered
    uint16 constant SRD   = 0x0004; // OK to read
    uint16 constant SWR   = 0x0008; // OK to write. RD and WR are never simultaneously asserted
    uint16 constant SRW   = 0x0010; // open for reading & writing
    uint16 constant SEOF  = 0x0020; // found EOF
    uint16 constant SERR  = 0x0040; // found error
    uint16 constant SMBF  = 0x0080; // _bf._base is from malloc
    uint16 constant SAPP  = 0x0100; // fdopen()ed in append mode
    uint16 constant SSTR  = 0x0200; // this is an sprintf/snprintf string
    uint16 constant SOPT  = 0x0400; // do fseek() optimization
    uint16 constant SNPT  = 0x0800; // do not do fseek() optimization
    uint16 constant SOFF  = 0x1000; // set iff _offset is in fact correct
    uint16 constant SMOD  = 0x2000; // true => fgetln modified _p text
    uint16 constant SALC  = 0x4000; // allocate string space dynamically
    uint16 constant SIGN  = 0x8000; // ignore this file in _fwalk

    function lookup_dir(s_proc p, uint16 fd, string path) internal returns (uint16) {

    }

    function _exit(s_proc p, uint16) internal {}
    function access(s_proc p, string path, uint16 mode) internal returns (uint16) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.path == path) {
//                uint32 offset = f.offset;
                s_stat st;
                st.stt(f.attr);
                if (st.st_uid == p.p_ucred.cr_uid || st.st_uid == p.p_ucred.cr_groups[0] && mode >= 0)
                    return f.file;
                else
                    return liberr.EPERM;
            }
        }
        p.p_xexit = liberr.ENOENT;
    }

    function alarm(s_proc p, uint32) internal returns (uint16) {}
    function chdir(s_proc p, string path) internal returns (uint16) {
        p.p_pd.pwd_cdir.path = path;
    }
    function chown(s_proc p, string , uint16, uint16) internal returns (uint16) {}
    function close(s_proc p, uint16 fd) internal returns (uint16) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file == fd) {
                for (uint j = i; j < n_files - 1; j++)
                    fdt[j] = fdt[j + 1];
                fdt.pop();
                p.p_fd.fdt_ofiles = fdt;
                p.p_fd.fdt_nfiles--;
                return liberr.ESUCCESS;
            }
        }
        p.p_xexit = liberr.EBADF;
    }

    function closefrom(s_proc p, uint16 fd) internal {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        s_of[] fdt_res;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file < fd)
                fdt_res.push(f);
        }
        p.p_fd.fdt_ofiles = fdt_res;
        p.p_fd.fdt_nfiles = uint16(fdt_res.length);
    }

    function dup(s_proc p, uint16) internal returns (uint16) {}
    function dup2(s_proc p, uint16, uint16) internal returns (uint16) {}
    function execl(s_proc p, string , string ) internal returns (uint16) {}
    function execle(s_proc p, string , string ) internal returns (uint16) {}
    function execlp(s_proc p, string , string ) internal returns (uint16) {}
    function execv(s_proc p, string , string ) internal returns (uint16) {}
    function execve(s_proc p, string , string , string ) internal returns (uint16) {}
    function execvp(s_proc p, string , string ) internal returns (uint16) {}
    function fork(s_proc p) internal returns (uint16) {
    }
    function fpathconf(s_proc p, uint16, uint16) internal returns (uint32) {}
    function getcwd(s_proc p, uint16 size) internal returns (string buf) {
        if (size == 0)
            p.p_xexit = liberr.EINVAL;
        return p.p_pd.pwd_cdir.path;
    }
    function getegid(s_proc p) internal returns (uint16) {
//        return p.p_ucred.cr_groups[0];
        return p.p_ucred.getegid();
    }
    function geteuid(s_proc p) internal returns (uint16) {
        return p.p_ucred.geteuid();
    }
    function getgid(s_proc p) internal returns (uint16) {
   }
    function getgroups(s_proc p, uint16) internal returns (uint16[]) {
    }
    function getlogin(s_xsession ses) internal returns (string) {
        return ses.s_login;
    }
    function getpgrp(s_proc p) internal returns (uint16) {
        return p.p_oppid;
    }
    function getpid(s_proc p) internal returns (uint16) {
        return p.p_pid;
    }
    function getppid(s_proc p) internal returns (uint16) {
        return p.p_oppid;
    }
    function getuid(s_proc p) internal returns (uint16) {
        s_thread t = __syscall0(p, libsyscall.SYS_getuid);
        return uint16(t.td_retval);
    }
    function isatty(s_proc p, uint16) internal returns (uint16) {}
    function link(s_proc p, string , string ) internal returns (uint16) {}
    function lseek(s_proc p, uint16, uint32, uint16) internal returns (uint32) {}
    function pathconf(s_proc p, string , uint16) internal returns (uint32) {}
    function pause(s_proc p) internal returns (uint16) {}
    function pipe(s_proc p, uint16[2]) internal returns (uint16) {}
    function read(s_proc p, uint16 fd, uint16 nbytes) internal returns (bytes , uint32) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file == fd) {
                uint32 offset = f.offset;
                s_stat st;
                st.stt(f.attr);
                uint32 file_len = st.st_size;
                uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
                f.offset += cap;
                if (f.offset >= file_len)
                    f.flags |= SEOF;
                p.p_fd.fdt_ofiles[i] = f;
                return (f.buf.buf[offset : offset + cap], cap);
            }
        }
        p.p_xexit = liberr.EBADF;
    }
    function rmdir(s_proc p, string ) internal returns (uint16) {}
    function setgid(s_proc p, uint16 gid) internal returns (uint16) {
        p.p_ucred.setgid(gid);
    }
    function setpgid(s_proc p, uint16, uint16) internal returns (uint16) {}
    function setsid(s_proc p) internal returns (s_xsession) {
        uint16 pid = p.p_pid;
        uint16 k_ttyp;
        string s_login;
        uint16 s_sid;
        if (pid == p.p_oppid || pid == p.p_leader)
            p.p_xexit = liberr.EPERM;
        else
            return s_xsession(1, p, k_ttyp, s_sid, s_login);
    }
    function setuid(s_proc p, uint16 uid) internal returns (uint16) {
        p.p_ucred.setuid(uid);
    }
    function sleep(s_proc p, uint32) internal returns (uint16) {}
    function sysconf(s_proc p, uint16) internal returns (uint32) {

    }
    function tcgetpgrp(s_proc p, uint16) internal returns (uint16) {}
    function tcsetpgrp(s_proc p, uint16, uint16) internal returns (uint16) {}
    function ttyname(s_proc p, uint16) internal returns (string) {}
    function ttyname_r(s_proc p, uint16, string , uint16) internal returns (uint16) {}
    function unlink(s_proc p, string ) internal returns (uint16) {}
    function write(s_proc p, uint16 fd, bytes buf, uint16 nbytes) internal returns (uint32) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file == fd) {
                uint32 offset = f.offset;
                s_stat st;
                st.stt(f.attr);
                uint32 file_len = st.st_size;
                uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
                f.offset += cap;
                f.buf.buf.append(buf[ : nbytes]);
                p.p_fd.fdt_ofiles[i] = f;
                return cap;
            }
        }
        p.p_xexit = liberr.EBADF;
    }
    function confstr(s_proc p, string[122] sconf, uint16 name, uint16 len) internal returns (string buf) {
        if (name > conf._SC_CPUSET_SIZE)
            p.p_xexit = liberr.EINVAL;
        buf = sconf[name];
        return buf.byteLength() < len ? buf : buf.substr(0, len);
    }
    function getopt(s_proc p, uint16, string[], string ) internal returns (uint16) {}
    function fsync(s_proc p, uint16) internal returns (uint16) {}
    function fdatasync(s_proc p, uint16) internal returns (uint16) {}
    function ftruncate(s_proc p, uint16, uint32) internal returns (uint16) {}
    function getlogin_r(s_proc p, string , uint16) internal returns (uint16) {

    }
    function fchown(s_proc p, uint16, uint16, uint16) internal returns (uint16) {}
    function readlink(s_proc p, string , string , uint16) internal returns (uint32) {}
    function gethostname(s_proc p, uint16 namelen) internal returns (uint16, string) {
    }
    function setegid(s_proc p, uint16 gid) internal returns (uint16) {
        p.p_ucred.cr_groups[0] = gid;
    }
    function seteuid(s_proc p, uint16 euid) internal returns (uint16) {
        p.p_ucred.cr_uid = euid;
    }
    function getsid(s_proc p, s_proc[] pt, uint16 pid) internal returns (uint16) {
        if (pid == 0)
            return p.p_leader;
        for (s_proc pp: pt)
            if (pp.p_pid == pid)
                return pp.p_leader;
        p.p_xexit = liberr.ESRCH;
    }

    function fchdir(s_proc p, uint16 fd) internal returns (uint16) {

    }
    function getpgid(s_proc p, s_proc[] pt, uint16 pid) internal returns (uint16) {
        if (pid == 0)
            return p.p_oppid;
        for (s_proc pp: pt)
            if (pp.p_pid == pid)
                return pp.p_oppid;
        p.p_xexit = liberr.ESRCH;
    }
    function lchown(s_proc p, string , uint16, uint16) internal returns (uint16) {}
    function pread(s_proc p, uint16 fd, uint16 nbytes, uint32 offset) internal returns (bytes buf, uint32) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file == fd) {
                s_stat st;
                st.stt(f.attr);
                uint32 file_len = st.st_size;
                uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
                return (f.buf.buf[offset : offset + cap], cap);
            }
        }
        p.p_xexit = liberr.EBADF;
    }
    function pwrite(s_proc p, uint16 fd, bytes buf, uint16 nbytes, uint32 offset) internal returns (uint32) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.file == fd) {
                s_stat st;
                st.stt(f.attr);
                uint32 file_len = st.st_size;
                uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
                f.offset += cap;
                f.buf.buf.append(buf[ : nbytes]);
                p.p_fd.fdt_ofiles[i] = f;
                return cap;
            }
        }
        p.p_xexit = liberr.EBADF;
    }

    function truncate(s_proc p, string , uint32) internal returns (uint16) {}
    function faccessat(s_proc p, uint16, string , uint16, uint16) internal returns (uint16) {}
    function fchownat(s_proc p, uint16, string , uint16, uint16, uint16) internal returns (uint16) {}
    function fexecve(s_proc p, uint16, string[], string[]) internal returns (uint16) {}
    function linkat(s_proc p, uint16, string , uint16, string , uint16) internal returns (uint16) {}
    function readlinkat(s_proc p, uint16, string , string , uint16) internal returns (uint32) {}
    function symlinkat(s_proc p, string , uint16, string ) internal returns (uint16) {}
    function unlinkat(s_proc p, uint16, string , uint16) internal returns (uint16) {}
    function symlink(s_proc p, string  , string  ) internal returns (uint16) {}
    function crypt(s_proc p, string , string ) internal returns (string) {}
    function gethostid(s_proc p) internal returns (uint32) {}
    function lockf(s_proc p, uint16, uint16, uint32) internal returns (uint16) {}
    function nice(s_proc p, uint16) internal returns (uint16) {}
    function setregid(s_proc p, uint16 rgid, uint16 egid) internal returns (uint16) {
        p.p_ucred.cr_svgid = p.p_ucred.cr_rgid;
        p.p_ucred.cr_rgid = rgid;
        p.p_ucred.cr_groups[0] = egid;
    }
    function setreuid(s_proc p, uint16 ruid, uint16 euid) internal returns (uint16) {
        p.p_ucred.cr_svuid = p.p_ucred.cr_uid;
        p.p_ucred.cr_ruid = ruid;
        p.p_ucred.cr_uid = euid;
    }
    function swab(s_proc p, bytes , bytes , uint32) internal {}
    function sync(s_proc p) internal {}
    function brk(s_proc p, bytes) internal returns (uint16) {}
    function chroot(s_proc p, string ) internal returns (uint16) {}
    function getdtablesize(s_proc p) internal returns (uint16) {}
    function getpagesize(s_proc p) internal returns (uint16) {}
    function getpass(s_proc p, string ) internal returns (string) {}
    function sbrk(s_proc p, uint32) internal {}
    function getwd(s_proc p) internal returns (string) {
        return p.p_pd.pwd_cdir.path;
    }
    function ualarm(s_proc p, uint32, uint32) internal returns (uint32) {}
    function usleep(s_proc p, uint32) internal returns (uint16) {}
    function vfork(s_proc p) internal returns (uint16) {}
    function acct(s_proc p, string ) internal returns (uint16) {}
    function async_daemon(s_proc p) internal returns (uint16) {}
    function check_utility_compat(s_proc p, string ) internal returns (uint16) {}
    function close_range(s_proc p, uint16, uint16, uint16) internal returns (uint16) {}
    function copy_file_range(s_proc p, uint16, uint32, uint16, uint32, uint16, uint16) internal returns (uint32) {}
    function crypt_get_format(s_proc p) internal returns (string) {}
    function crypt_r(s_proc p, string , string , s_crypt_data ) internal returns (string) {}
    function crypt_set_format(s_proc p, string ) internal returns (uint16) {}
    function dup3(s_proc p, uint16, uint16, uint16) internal returns (uint16) {}
    function eaccess(s_proc p, string , uint16) internal returns (uint16) {}
    function endusershell(s_proc p) internal {}
    function exect(s_proc p, string , string , string ) internal returns (uint16) {}
    function execvP(s_proc p, string , string , string ) internal returns (uint16) {}
    function feature_present(s_proc p, string ) internal returns (uint16) {}
    function fflagstostr(s_proc p, uint32) internal returns (string) {}
    function getdomainname(s_proc p, string , uint16) internal returns (uint16) {}
    function getentropy(s_proc p, bytes, uint16) internal returns (uint16) {}
    function getgrouplist(s_proc p, string name, uint16 basegid) internal returns (uint16[] groups, uint8 ngroups) {

/*        s_of f = p.fopen("/etc/group", "r");
//        f.s

        if (!f.ferror()) {
            while (!f.feof()) {
                string l = f.readline();
  //              if (l.name)
            }
        }

        // name = user name
        // basegid => groups*/
    }
    function getloginclass(s_proc p, string , uint16) internal returns (uint16) {}
    function getmode(s_proc p, bytes, uint16) internal returns (uint16) {}
    function getosreldate(s_proc p) internal returns (uint16) {}
    function getpeereid(s_proc p, uint16, uint16, uint16) internal returns (uint16) {}
    function getresgid(s_proc p) internal returns (uint16 rgid, uint16 egid, uint16 sgid) {
        (, , , , , uint16 cr_rgid, uint16 cr_svgid, , , uint16[] cr_groups) = p.p_ucred.unpack();
        return (cr_rgid, cr_groups[0], cr_svgid);
    }
    function getresuid(s_proc p, uint16, uint16, uint16) internal returns (uint16 rgid, uint16 egid, uint16 sgid) {
        (, uint16 cr_uid, uint16 cr_ruid, uint16 cr_svuid, , , , , , ) = p.p_ucred.unpack();
        return (cr_ruid, cr_uid, cr_svuid);
    }
    function getusershell(s_proc p) internal returns (string) {}
    function initgroups(s_proc p, string name, uint16 basegid) internal returns (uint16) {
//        getgrouplist
    }
    function iruserok(s_proc p, uint32, uint16, string , string ) internal returns (uint16) {}
    function iruserok_sa(s_proc p, bytes, uint16, uint16, string , string ) internal returns (uint16) {}
    function issetugid(s_proc p) internal returns (bool) {
        (, uint16 cr_uid, , uint16 cr_svuid, , , uint16 cr_svgid, , , uint16[] cr_groups) = p.p_ucred.unpack();
        return cr_svuid != cr_uid || cr_svgid != cr_groups[0];
    }
    function __FreeBSD_libc_enter_restricted_mode(s_proc p) internal {}
    function lpathconf(s_proc p, string , uint16) internal returns (uint32) {}
    function mkdtemp(s_proc p, string ) internal returns (string) {}
    function mknod(s_proc p, string , uint16, uint16) internal returns (uint16) {}
    function mkstemp(s_proc p, string ) internal returns (uint16) {}
    function mkstemps(s_proc p, string , uint16) internal returns (uint16) {}
    function mktemp(s_proc p, string ) internal returns (string) {}
    function nfssvc(s_proc p, uint16 flag, bytes) internal returns (uint16) {}
//    function nlm_syscall(s_proc p, uint16, uint16, uint16, string ) internal returns (uint16) {}
    function pipe2(s_proc p, uint16[2], uint16) internal returns (uint16) {}
    function profil(s_proc p, string , uint16, uint16, uint16) internal returns (uint16) {}
    function rcmd(s_proc p, string , uint16, string , string , string , uint16) internal returns (uint16) {}
    function rcmd_af(s_proc p, string , uint16, string , string , string , uint16, uint16) internal returns (uint16) {}
    function rcmdsh(s_proc p, string , uint16, string , string , string , string ) internal returns (uint16) {}
    function re_comp(s_proc p, string ) internal returns (string) {}
    function re_exec(s_proc p, string ) internal returns (uint16) {}
    function reboot(s_proc p, uint16) internal returns (uint16) {}
    function revoke(s_proc p, string ) internal returns (uint16) {}
    function rfork(s_proc p, uint16 flags) internal returns (uint16 pid) {
    }
    function rfork_thread(s_proc p, uint16 flags, bytes stack, uint32 sf, bytes arg) internal returns (uint16 pid) {
//        s_proc pc = p;
    }
    function rresvport(s_proc p, uint16) internal returns (uint16) {}
    function rresvport_af(s_proc p, uint16, uint16) internal returns (uint16) {}
    function ruserok(s_proc p, string, uint16, string , string ) internal returns (uint16) {}
    function setdomainname(s_proc p, string , uint16) internal returns (uint16) {}
    function setgroups(s_proc p, uint8 ngroups, uint16[] gidset) internal returns (uint16) {

        p.p_ucred.cr_groups = gidset;
        p.p_ucred.cr_ngroups = ngroups;
    }
    function sethostid(s_proc p, uint32) internal {}
    function sethostname(s_proc p, string , uint16) internal returns (uint16) {}
    function setlogin(s_xsession ses, string name) internal returns (uint16) {
        ses.s_login = name;
    }
    function setloginclass(s_proc p, string name) internal returns (uint16) {
        p.p_ucred.cr_loginclass = name;
    }
    function setmode(s_proc p, string ) internal {}
    function setpgrp(s_proc p, uint16, uint16) internal returns (uint16) {}
    function setproctitle(s_proc p, string _fmt) internal {
        string s = _fmt.substr(0, 1) == "-" ? _fmt : p.p_comm + " " + _fmt;
        p.p_comm = s;
    }
    function setproctitle_fast(s_proc p, string _fmt) internal {
        setproctitle(p, _fmt);
    }
    function setresgid(s_proc p, uint16 rgid, uint16 egid, uint16 sgid) internal returns (uint16) {
        s_ucred u = p.p_ucred;
        u.cr_svgid = sgid;
        u.cr_rgid = rgid;
        u.cr_groups[0] = egid;
        p.p_ucred = u;
    }
    function setresuid(s_proc p, uint16 ruid, uint16 euid, uint16 suid) internal returns (uint16) {
        s_ucred u = p.p_ucred;
        u.cr_svuid = suid;
        u.cr_ruid = ruid;
        u.cr_uid = euid;
        p.p_ucred = u;
    }
    function setrgid(s_proc p, uint16 rgid) internal returns (uint16) {
        p.p_ucred.cr_rgid = rgid;
    }
    function setruid(s_proc p, uint16 ruid) internal returns (uint16) {
        p.p_ucred.cr_ruid = ruid;
    }
    function setusershell(s_proc p) internal {}
    function swapon(s_proc p, string) internal returns (uint16) {}
    function swapoff(s_proc p, string) internal returns (uint16) {}
    function syscall(s_proc p, uint16, uint16) internal returns (uint16) {}
    function __syscall0(s_proc p, uint16 number) internal returns (s_thread) {
        uint16[] scargs;
        return __syscall(p, number, scargs);
    }
    function __syscall(s_proc p, uint16 number, uint16[] scargs) internal returns (s_thread) {
        s_ucred td_realucred = p.p_ucred;   // Reference to credentials.
        s_ucred td_ucred = p.p_ucred;       // Used credentials, temporarily switchable.
        s_plimit td_limit = p.p_limit;      // Resource limits.
        string td_name = libsyscall.syscall_name(number);         // Thread name.
//        s_xfile xfile;
        uint8 td_errno;        // Error from last syscall.
        td_states td_state;     // thread state
        uint32 tdu_retval;
        //s_thread t = s_thread(p.p_pid, 1, 0, 0, td_realucred, td_ucred, td_limit, td_name, td_errno, td_state, tdu_retval);
        //if (!td_name.empty())
        //    t.do_syscall(number, scargs);
        //return t;
    }
    function undelete(s_proc p, string) internal returns (uint16) {}
    function unwhiteout(s_proc p, string) internal returns (uint16) {}
    function valloc(s_proc p, uint16) internal returns (bytes) {}
    function funlinkat(s_proc p, uint16, string, uint16, uint16) internal returns (uint16) {}
}
