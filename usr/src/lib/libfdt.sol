pragma ton-solidity >= 0.62.0;

import "sbuf.sol";
import "xio.sol";
import "liberr.sol";
import "filedesc_h.sol";

library libfdt {
    using xio for s_of;
    using sbuf for s_sbuf;
    uint8 constant STDIN_FILENO  = 0;
    uint8 constant STDOUT_FILENO = 1;
    uint8 constant STDERR_FILENO = 2;
    uint8 constant ERRNO_FILENO  = 3;


    function fdfetch(s_of[] t, string path) internal returns (uint) {
        for (uint i = 0; i < t.length; i++)
            if (t[i].path == path)
                return i + 1;
    }

//    function fderror(s_of[] t, string err_msg, string reason) internal {
    function fderror(s_of[] t, uint8 ec, string reason) internal {
        s_of f = t[STDERR_FILENO];
        string err_msg = err.strerror(ec);
        f.buf.error = ec;
        if (!reason.empty())
            err_msg.append(reason + " ");
        f.fputs(err_msg);
        t[STDERR_FILENO] = f;
    }

    function fdflush(s_of[] t) internal {
        t[STDOUT_FILENO].fflush();
        t[STDERR_FILENO].fflush();
        t[3].fflush();
    }

    function fderrno(s_of[] t) internal returns (uint8) {
        s_of f = t[STDERR_FILENO];
        return f.buf.error;
    }

    function fdputs(s_of[] t, string str) internal {
        s_of f = t[STDOUT_FILENO];
        f.fputs(str);
        t[STDOUT_FILENO] = f;
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
}
