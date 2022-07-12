pragma ton-solidity >= 0.62.0;

import "stypes.sol";
import "io.sol";
import "libfdt.sol";
import "sh.sol";
import "vars.sol";
//import "libarg.sol";

struct shell_env {
    s_of[] ofiles;    // Open files inherited upon invocation of the shell, plus open files controlled by exec
    s_of cwd;         // Working directory as set by cd
    uint16 umask;     // File creation mask set by umask
    string[][] environ;
    /*string params;    // Shell parameters that are set by variable assignment (see the set special built-in)
    string exports;   // Environment inherited by the shell when it begins (see the export special built-in)
    string traps;
    string vars;
    string functions; // Shell functions
    string options;   // Options turned on at invocation or by set
    uint16 apid;      // Process IDs of the last commands in asynchronous lists known to this shell environment
    string aliases;   // Shell aliases
    string dirstack;*/
}

library libshellenv {
    using xio for s_of;
    using sbuf for s_sbuf;
    using libfdt for s_of[];
    using vars for string[];
//    using libarg for string[][];

    function flag_set(shell_env e, byte b) internal returns (bool) {
        bytes flags = vars.val("FLAGS", e.environ[sh.SPECVARS]);
        return flags.empty() ? false : str.strchr(flags, b) > 0;
    }
    function flag_values(shell_env e, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        string flags_set = vars.val("FLAGS", e.environ[sh.SPECVARS]);
        bool[] tmp;
        uint i;
        for (byte b: bytes(flags_query)) {
            tmp.push(str.strchr(flags_set, b) > 0);
            i++;
        }
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }
    function flags_set(shell_env e, bytes flags_query) internal returns (bool, bool, bool, bool) {
        uint len = flags_query.length;
        string flags = vars.val("FLAGS", e.environ[sh.SPECVARS]);
        bool[] tmp;
        uint i;
        for (byte b: flags_query) {
            tmp.push(str.strchr(flags, b) > 0);
            i++;
        }
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false);
    }
    function get_args(shell_env e) internal returns (string[] args, string flags, string argv) {
        string[] esv = e.environ[sh.SPECVARS];
        (args, ) = libstring.split(vars.val("PARAMS", esv), ' ');
        flags = vars.val("FLAGS", esv);
        argv = vars.val("ARGV", esv);
    }
    function params(shell_env e) internal returns (string[] args) {
        (args, ) = libstring.split(vars.val("PARAMS", e.environ[sh.SPECVARS]), ' ');
    }
    function get_cwd(shell_env e) internal returns (uint16) {
        return vars.int_val("WD", e.environ[sh.VARIABLE]);
    }
    function get_cmd(shell_env e) internal returns (string) {
        return vars.val("COMMAND", e.environ[sh.SPECVARS]);
    }
    function opt_value(shell_env e, string opt_name) internal returns (string) {
        return vars.val(opt_name, e.environ[sh.OPTARGS]);
    }
    function opt_value_int(shell_env e, string opt_name) internal returns (uint16) {
        return vars.int_val(opt_name, e.environ[sh.OPTARGS]);
    }
    function flags_empty(shell_env e) internal returns (bool) {
        return vars.val("FLAGS", e.environ[sh.SPECVARS]).empty();
    }
    function env_value(shell_env e, string name) internal returns (string) {
        return vars.val(name, e.environ[sh.VARIABLE]);
    }
    function env_vars(shell_env e) internal returns (string[]) {
        return e.environ[sh.VARIABLE];
    }
    function get_users_groups(shell_env e) internal returns (mapping (uint16 => string) users, mapping (uint16 => string) groups) {
        for (string rec: e.environ[sh.USER]) {
            (, string name, string value) = vars.split_var_record(rec);
            users[str.toi(name)] = value;
        }
        for (string rec: e.environ[sh.GROUP]) {
            (, string name, string value) = vars.split_var_record(rec);
            groups[str.toi(name)] = value;
        }
        /*users[0] = "root";
        groups[0] = "wheel";*/
    }
    function exit(shell_env e, uint status) internal {
//        e.environ[sh.ERRNO] = vars.set_var("", "ERRNO=" + str.toa(status), e.environ[sh.ERRNO]);
        e.environ[sh.ERRNO].set_int_val("EXIT_STATUS", status);
    }
    function retur(shell_env e, uint status) internal {
        e.environ[sh.ERRNO].set_int_val("RETURN_CODE", status);
//        e.environ[sh.ERRNO] = vars.set_var("", "EXITSTATUS=" + str.toa(status), e.environ[sh.ERRNO]);
    }

    function perror(shell_env e, string reason) internal {
        e.environ[sh.ERRNO].set_val("REASON", reason);
//        s_of f = e.ofiles[libfdt.STDERR_FILENO];
//        string[] page = e.environ[sh.ERRNO];
//        e.environ[sh.ERRNO] = vars.set_var("", "REASON=" + reason, e.environ[sh.ERRNO]);
//        uint8 ec = f.buf.error;
//        string err_msg = err.strerror(ec);
//        string err_msg = p.p_comm + ": ";
//        if (!reason.empty())
//            err_msg.append(reason + " ");
//        f.fputs(err_msg);
//        e.ofiles[libfdt.STDERR_FILENO] = f;
    }
    function puts(shell_env e, string str) internal {
        s_of f = e.ofiles[libfdt.STDOUT_FILENO];
        f.fputs(str);
        e.ofiles[libfdt.STDOUT_FILENO] = f;
    }
    function fputs(shell_env e, string str, s_of f) internal {
        uint16 idx = f.fileno();
        if (idx >= 0 && idx < e.ofiles.length) {
            f.fputs(str);
            e.ofiles[idx] = f;
        }
    }
    function putchar(shell_env e, byte c) internal {
        s_sbuf s = e.ofiles[libfdt.STDOUT_FILENO].buf;
        s.sbuf_putc(c);
        e.ofiles[libfdt.STDOUT_FILENO].buf = s;
    }
    function stdin(shell_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDIN_FILENO];
    }
    function stdout(shell_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDOUT_FILENO];
    }
    function stderr(shell_env e) internal returns (s_of) {
        return e.ofiles[libfdt.STDERR_FILENO];
    }

    function fopen(shell_env e, string path, string mode) internal returns (s_of f) {
        uint16 flags = io.mode_to_flags(mode);
        uint q = e.ofiles.fdfetch(path);
        if (q > 0) {
            f = e.ofiles[q - 1];
            f.flags |= flags;
        } else
            f.flags |= io.SERR;
    }

    function shopen(shell_env e, string path, string mode) internal returns (s_of f) {
        uint16 flags = io.mode_to_flags(mode);
        uint q = io.fetch_fdt(e.ofiles, path);
        if (q > 0) {
            f = e.ofiles[q - 1];
            f.flags |= flags;
        } else
            f.flags |= io.SERR;
    }

    function map_file(shell_env e, string name) internal returns (string[]) {
        string all_lines = read_file(e, name);
        if (!all_lines.empty()) {
            (string[] lines, ) = libstring.split(all_lines, "\n");
            return lines;
        }
    }
    function read_file(shell_env e, string name) internal returns (string) {
        s_of f = shopen(e, name, "r");
        if (!f.ferror()) {
            string all_lines = f.gets_s(0);
            if (!f.ferror())
                return all_lines;
        }
    }
    function print_shell_env(shell_env e) internal returns (string) {
        (s_of[] e_ofiles, s_of e_cwd, uint16 e_umask, string[][] e_environ) = e.unpack();
        string s_ofiles;
        for (s_of f: e_ofiles)
            s_ofiles.append(f.path + " ");
        string s_environ;
        for (string[] a_env: e_environ)
            s_environ.append(libstring.join_fields(a_env, '\n') + '\n');

        return format("open files {} cwd {} umask {} environ {}\n",
            s_ofiles, e_cwd.path, e_umask, s_environ);
    }

}