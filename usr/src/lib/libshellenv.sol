pragma ton-solidity >= 0.62.0;

import "io.sol";
import "libfdt.sol";
import "sh.sol";
import "vars.sol";
import "libsyscall.sol";

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
    */
}

library libshellenv {
    using xio for s_of;
    using sbuf for s_sbuf;
    using libfdt for s_of[];
    using vars for string[];

    function flag_set(shell_env e, byte b) internal returns (bool) {
        bytes flags = vars.val("FLAGS", e.environ[sh.VARIABLE]);
        return flags.empty() ? false : str.strchr(flags, b) > 0;
    }

    function flag_values(shell_env e, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        return _flag_values(vars.val("FLAGS", e.environ[sh.VARIABLE]), flags_query);
    }

    function shell_option_values(shell_env e, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        return _flag_values(vars.val("-", e.environ[sh.VARIABLE]), flags_query);
    }

    function _flag_values(string flags_actual, bytes flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        bool[] tmp;
        uint len = flags_query.length;
        for (byte b: flags_query)
            tmp.push(str.strchr(flags_actual, b) > 0);
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
        string flags = vars.val("FLAGS", e.environ[sh.VARIABLE]);
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
        string[] esv = e.environ[sh.VARIABLE];
        (args, ) = libstring.split(vars.val("PARAMS", esv), ' ');
        flags = vars.val("FLAGS", esv);
        argv = vars.val("ARGV", esv);
    }
    function params(shell_env e) internal returns (string[] args) {
        (args, ) = libstring.split(vars.val("PARAMS", e.environ[sh.VARIABLE]), ' ');
    }
    function get_cwd(shell_env e) internal returns (uint16) {
        return vars.int_val("WD", e.environ[sh.VARIABLE]);
    }
    function get_cmd(shell_env e) internal returns (string) {
        return vars.val("COMMAND", e.environ[sh.VARIABLE]);
    }
    function opt_value(shell_env e, string opt_name) internal returns (string) {
        return vars.val(opt_name, e.environ[sh.OPTARGS]);
    }
    function opt_value_int(shell_env e, string opt_name) internal returns (uint16) {
        return vars.int_val(opt_name, e.environ[sh.OPTARGS]);
    }
    function flags_empty(shell_env e) internal returns (bool) {
        return vars.val("FLAGS", e.environ[sh.VARIABLE]).empty();
    }
    function env_value(shell_env e, string name) internal returns (string) {
        return vars.val(name, e.environ[sh.VARIABLE]);
    }
    function env_var_values(shell_env e, string[] names) internal returns (string s1, string s2, string s3, string s4) {
        string[] evv = e.environ[sh.VARIABLE];
        uint len = names.length;
        if (len > 0) s1 = vars.val(names[0], evv);
        if (len > 1) s2 = vars.val(names[1], evv);
        if (len > 2) s3 = vars.val(names[2], evv);
        if (len > 3) s4 = vars.val(names[3], evv);
    }
    function set_env_vars(shell_env e, string[] names, string[] values) internal {
        string[] evv = e.environ[sh.VARIABLE];
        uint vlen = values.length;
        for (uint i = 0; i < names.length; i++)
            evv.set_val(names[i], i < vlen ? values[i] : "");
        e.environ[sh.VARIABLE] = evv;
    }
    function env_var_int_values(shell_env e, string[] names) internal returns (uint16 i1, uint16 i2, uint16 i3, uint16 i4) {
        string[] evv = e.environ[sh.VARIABLE];
        uint len = names.length;
        if (len > 0) i1 = vars.int_val(names[0], evv);
        if (len > 1) i2 = vars.int_val(names[1], evv);
        if (len > 2) i3 = vars.int_val(names[2], evv);
        if (len > 3) i4 = vars.int_val(names[3], evv);
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
    }
    function exit(shell_env e, uint status) internal {
        e.environ[sh.ERRNO].set_int_val("EXIT_STATUS", status);
    }
    function retur(shell_env e, uint status) internal {
        e.environ[sh.ERRNO].set_int_val("RETURN_CODE", status);
    }

    function syscall(shell_env e, uint16 number, string[] args) internal {
        e.environ[sh.SIGNAL].push("-" + str.toa(args.length) + " " + str.toa(number) + "=" + libstring.join_fields(args, ' '));
    }

    function signal(shell_env e, uint8 number, uint8 jid, uint16 pid) internal {
        e.environ[sh.SIGNAL].push("-d " + str.toa(jid > 0 ? jid : pid) + "=" + str.toa(number));
    }

    function set_err(shell_env e, uint8 errno, string s) internal {
        e.environ[sh.ERRNO].set_int_val("ERRNO", errno);
        if (!s.empty())
            e.environ[sh.ERRNO].set_val("REASON", s);
    }
    function perror(shell_env e, string reason) internal {
        e.environ[sh.ERRNO].set_val("REASON", reason);
    }

    function notfound(shell_env e, string arg) internal {
        if (!arg.empty())
            e.environ[sh.ERRNO].set_val("REASON", arg);
        e.environ[sh.ERRNO].set_int_val("ERRNO", 1);
    }
    function gets(shell_env e) internal returns (string res) {
        res = e.ofiles[libfdt.STDIN_FILENO].fflush();
    }
    function puts(shell_env e, string str) internal {
        e.ofiles[libfdt.STDOUT_FILENO].fputs(str + "\n");
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

    function flush_std(shell_env e) internal {
        e.ofiles.fdflush();
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
