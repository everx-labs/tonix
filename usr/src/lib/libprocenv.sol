pragma ton-solidity >= 0.61.2;

import "stypes.sol";
import "io.sol";
import "libfdt.sol";

struct p_env {
    s_of[] ofiles; // Open files inherited on invocation of the shell, open files controlled by the exec special built-in plus any modifications, and additions specified by any redirections to the utility
    s_of cwd;      // Current working directory
    uint16 umask;  // File creation mask
    string[] environ; // Variables with the export attribute, along with those explicitly exported for the duration of the command, shall be passed to the utility environment variables
}

library libprocenv {
    using xio for s_of;
    using sbuf for s_sbuf;
    using libfdt for s_of[];

    function fdt(p_env e) internal returns (s_of[]) {
        return e.ofiles;
    }
    function cwd(p_env e) internal returns (s_of) {
        return e.cwd;
    }
    function umask(p_env e) internal returns (uint16) {
        return e.umask;
    }
    function env(p_env e) internal returns (string[]) {
        return e.environ;
    }

    function exit(p_env e, uint8 ec) internal {
        s_of f = e.ofiles[libfdt.ERRNO_FILENO];
        f.buf.error = ec;
        if (ec > 0) {
            f.fputs*
        }
    }
    function perror(p_env e, string reason) internal {
        s_of f = e.ofiles[libfdt.STDERR_FILENO];
        uint8 ec = f.buf.error;
        string err_msg = err.strerror(ec);
//        string err_msg = p.p_comm + ": ";
        if (!reason.empty())
            err_msg.append(reason + " ");
        f.fputs(err_msg);
        e.ofiles[libfdt.STDERR_FILENO] = f;
    }
    function puts(p_env e, string str) internal {
        s_of f = e.ofiles[libfdt.STDOUT_FILENO];
        f.fputs(str);
        e.ofiles[libfdt.STDOUT_FILENO] = f;
    }
    function fputs(p_env e, string str, s_of f) internal {
        uint16 idx = f.fileno();
        if (idx >= 0 && idx < e.ofiles.length) {
            f.fputs(str);
            e.ofiles[idx] = f;
        }
    }
    function putchar(p_env e, byte c) internal {
        s_sbuf s = e.ofiles[libfdt.STDOUT_FILENO].buf;
        s.sbuf_putc(c);
        e.ofiles[libfdt.STDOUT_FILENO].buf = s;
    }
    function stdin(p_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDIN_FILENO];
    }
    function stdout(p_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDOUT_FILENO];
    }
    function stderr(p_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDERR_FILENO];
    }

    function fopen(p_env e, string path, string mode) internal returns (s_of f) {
        uint16 flags = io.mode_to_flags(mode);
        uint q = e.ofiles.fdfetch(path);
        if (q > 0) {
            f = e.ofiles[q - 1];
            f.flags |= flags;
        } else
            f.flags |= io.SERR;
    }

}