pragma ton-solidity >= 0.61.2;

import "stypes.sol";
import "io.sol";
import "libfdt.sol";
struct shell_env {
    s_of[] ofiles;    // Open files inherited upon invocation of the shell, plus open files controlled by exec
    s_of cwd;         // Working directory as set by cd
    uint16 umask;     // File creation mask set by umask
    string params;    // Shell parameters that are set by variable assignment (see the set special built-in)
    string exports;   // Environment inherited by the shell when it begins (see the export special built-in)
    string traps;
    string vars;
    string functions; // Shell functions
    string options;   // Options turned on at invocation or by set
    uint16 apid;      // Process IDs of the last commands in asynchronous lists known to this shell environment
    string aliases;   // Shell aliases
    string dirstack;
}

library libshellenv {
    using xio for s_of;
    using sbuf for s_sbuf;
    using libfdt for s_of[];

    function perror(shell_env e, string reason) internal {
        s_of f = e.ofiles[libfdt.STDERR_FILENO];
        uint8 ec = f.buf.error;
        string err_msg = err.strerror(ec);
//        string err_msg = p.p_comm + ": ";
        if (!reason.empty())
            err_msg.append(reason + " ");
        f.fputs(err_msg);
        e.ofiles[libfdt.STDERR_FILENO] = f;
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
        (s_of[] e_ofiles, s_of e_cwd, uint16 e_umask, string e_params, string e_exports, string e_traps, string e_vars, string e_functions, string e_options, uint16 e_apid, string e_aliases, string e_dirstack) = e.unpack();
        string s_ofiles;
        for (s_of f: e_ofiles)
            s_ofiles.append(f.path + " ");
        return format("open files {} cwd {} umask {} params {} exports {} traps {} vars {} functions {} options {} last {} aliases {} dir_stack{} \n",
            s_ofiles, e_cwd.path, e_umask, e_params, e_exports, e_traps, e_vars, e_functions, e_options, e_apid, e_aliases, e_dirstack);
    }

    function set_shell_env(shell_env e, svm sv) internal {
        s_proc p = sv.cur_proc;
        s_vmem vmm = sv.vmem[1];
        string e_params;
        string e_exports;
        string e_traps;
        string e_vars = vmem.vmem_fetch_page(vmm, 8);
        string e_functions = vmem.vmem_fetch_page(vmm, 9);
        string e_options;
        uint16 e_apid;
        string e_aliases = vmem.vmem_fetch_page(vmm, 0);
        string e_dirstack = vmem.vmem_fetch_page(vmm, 12);
        e = shell_env(p.p_fd.fdt_ofiles, p.p_pd.pwd_cdir, p.p_pd.pd_cmask, e_params, e_exports, e_traps, e_vars, e_functions, e_options, e_apid, e_aliases, e_dirstack);
    }
    function get(shell_env e, svm sv_in) internal returns (svm sv) {
        sv = sv_in;
        (s_of[] e_ofiles, s_of e_cwd, uint16 e_umask, /*string e_params*/, /*string e_exports*/, /*string e_traps*/, /*string e_vars*/, /*string e_functions*/, /*string e_options*/, /*uint16 e_apid*/, /*string e_aliases*/, /*string e_dirstack*/) = e.unpack();
        s_proc p = sv.cur_proc;
        p.p_pd.pwd_cdir = e_cwd;
        p.p_pd.pd_cmask = e_umask;
        p.p_fd.fdt_ofiles = e_ofiles;
        p.p_fd.fdt_nfiles = uint16(e_ofiles.length);
//        p.environ =
    }
}