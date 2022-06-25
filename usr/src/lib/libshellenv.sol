pragma ton-solidity >= 0.61.1;

import "stypes.sol";
import "io.sol";
struct shell_env {
    s_of[] e_ofiles;    // Open files inherited upon invocation of the shell, plus open files controlled by exec
    s_of e_cwd;         // Working directory as set by cd
    uint16 e_umask;     // File creation mask set by umask
    string e_params;    // Shell parameters that are set by variable assignment (see the set special built-in)
    string e_exports;   // Environment inherited by the shell when it begins (see the export special built-in)
    string e_traps;
    string e_vars;
    string e_functions; // Shell functions
    string e_options;   // Options turned on at invocation or by set
    uint16 e_apid;      // Process IDs of the last commands in asynchronous lists known to this shell environment
    string e_aliases;   // Shell aliases
    string e_dirstack;
}

struct proc_env {
    s_of[] e_ofiles; // Open files inherited on invocation of the shell, open files controlled by the exec special built-in plus any modifications, and additions specified by any redirections to the utility
    s_of e_cwd; // Current working directory
    uint16 e_umask; // File creation mask
    string[] e_environ; // Variables with the export attribute, along with those explicitly exported for the duration of the command, shall be passed to the utility environment variables
}

// regular: alias bg cd command false fc fg getopts hash jobs kill newgrp pwd read true type ulimit umask unalias wait
// special: break : continue . eval exec exit export readonly return set shift times trap unset

library libshellenv {
    using xio for s_of;

    function fdt(proc_env e) internal returns (s_of[]) {
        return e.e_ofiles;
    }
    function cwd(proc_env e) internal returns (s_of) {
        return e.e_cwd;
    }
    function umask(proc_env e) internal returns (uint16) {
        return e.e_umask;
    }
    function env(proc_env e) internal returns (string[]) {
        return e.e_environ;
    }
    function params(shell_env e) internal returns (string) {
        return e.e_params;
    }
    function exports(shell_env e) internal returns (string) {
        return e.e_exports;
    }
    function vars(shell_env e) internal returns (string) {
        return e.e_vars;
    }
    function functions(shell_env e) internal returns (string) {
        return e.e_functions;
    }
    function options(shell_env e) internal returns (string) {
        return e.e_options;
    }
    function last(shell_env e) internal returns (uint16) {
        return e.e_apid;
    }
    function aliases(shell_env e) internal returns (string) {
        return e.e_aliases;
    }
    function traps(shell_env e) internal returns (string) {
        return e.e_traps;
    }

    function shopen(shell_env e, string path, string mode) internal returns (s_of f) {
        uint16 flags = io.mode_to_flags(mode);
        uint q = io.fetch_fdt(e.e_ofiles, path);
        if (q > 0)
            f = e.e_ofiles[q - 1];
        else
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

    function print_proc_env(proc_env e) internal returns (string) {
        (s_of[] e_ofiles, s_of e_cwd, uint16 e_umask, string[] e_environ) = e.unpack();
        string s_ofiles;
        for (s_of f: e_ofiles)
            s_ofiles.append(f.path + " ");
        string s_env;
        for (string s: e_environ)
            s_env.append(s + " ");
        return format("open files {} cwd {} umask {} environ {}\n",
            s_ofiles, e_cwd.path, e_umask, s_env);
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
    function set(proc_env e, shell_env es) internal {
        e = proc_env(es.e_ofiles, es.e_cwd, es.e_umask, [es.e_exports]);
    }
    function inherit(proc_env e, s_proc p) internal {
        e = proc_env(p.p_fd.fdt_ofiles, p.p_pd.pwd_cdir, p.p_pd.pd_cmask, p.environ);
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