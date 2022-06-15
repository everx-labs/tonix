pragma ton-solidity >= 0.61.1;

import "pbuiltin_dict.sol";
import "compspec.sol";

contract enable is pbuiltin_dict {

    using sbuf for s_sbuf;

    function _select(svm sv, shell_env e) internal pure override returns (mapping (uint8 => string) pages, bool do_print, bool do_modify, bool do_load, bool print_all, bool reverse) {
        s_proc p = sv.cur_proc;
        (bool f_load, bool f_disable, bool f_unload, bool f_posix_only, bool f_print, bool f_print_all, , ) = p.flag_values("fndspa");
        do_print = p.flags_empty() || f_print || f_print_all;
        do_modify = f_disable || f_posix_only;
        reverse = f_disable;
        print_all = f_print_all;
        do_load = f_load || f_unload;
        string m = p.opt_value("f");
        string[] vp = sv.vmem[1].vm_pages;
        if (!m.empty()) {
            if (m == "alias") pages[libcompspec.CI_ALIAS] = e.e_aliases;
            if (m == "opt_string") pages[1] = vp[1];
            if (m == "index") pages[2] = vp[2];
            if (m == "builtin") pages[libcompspec.CI_BUILTIN] = vp[5];
            if (m == "command") pages[libcompspec.CI_COMMAND] = vp[11];
            if (m == "dirname") pages[libcompspec.CI_DIRECTORY] = vp[12];
            if (m == "disabled") pages[libcompspec.CI_DISABLED] = "";
            if (m == "enabled") pages[libcompspec.CI_ENABLED] = vp[5];
            if (m == "export") pages[libcompspec.CI_EXPORT] = e.e_exports;
            if (m == "filename") pages[libcompspec.CI_FILE]= "";
            if (m == "function") pages[libcompspec.CI_FUNCTION] = e.e_functions;
            if (m == "group") pages[libcompspec.CI_GROUP] = vp[7];
            if (m == "keyword") pages[libcompspec.CI_KEYWORD] = vp[10];
            if (m == "user") pages[libcompspec.CI_USER] = vp[6];
            if (m == "variable") pages[libcompspec.CI_VARIABLE] = e.e_vars;
            if (m == "dir_stack") pages[libcompspec.CI_DIRECTORY] = e.e_dirstack;
            if (m == "") pages[13] = e.e_exports;
        } else
            pages[5] = vp[5];

    }
    function _update_shell_env(shell_env e_in, svm sv, uint8 n, string page) internal pure override returns (shell_env e) {
        e = e_in;
        s_sbuf s;
        s.sbuf_new(page, page.byteLength(), 0);
        s.sbuf_finish();
        s_of f = s_of(0, io.SRD, 0, libcompspec.option_map_name(n, ""), 0, s);
        if (n >= e.e_ofiles.length)
            e.e_ofiles.push(f);
        else
            e.e_ofiles[n + libcompspec.CI_HELPTOPIC] = f;
    }

    function _print(svm sv_in, string[] params, string page_in, bool print_all, bool reverse) internal pure override returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string sattrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (p.flag_set(attr))
                sattrs.append(attr);

        sattrs = print_all ? "" : ("-" + (sattrs.empty() ? "-" : sattrs));
        string pool = page_in;
        if (params.empty()) {
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    p.puts("enable " + name);
            }
        }
        for (string param: params) {
            (string name, ) = param.csplit("=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    p.puts("enable " + name);
            } else
                p.perror(name + " not found");
        }
        sv.cur_proc = p;
    }

    function _modify(svm sv_in, string[] params, string page_in) internal pure override returns (svm sv, string page) {
        sv = sv_in;
        page = page_in;
        s_proc p = sv.cur_proc;
        string sattrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (p.flag_set(attr))
                sattrs.append(attr);

        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);

        for (string param: params)
            page = vars.set_var_attr(sattrs, param, page);
    }

    function _load(svm sv_in, shell_env e_in, string page_in) internal pure override returns (svm sv, shell_env e, string page) {
        sv = sv_in;
        page = page_in;
        e = e_in;
        s_proc p = sv.cur_proc;
        string m = p.opt_value("f");

        if (!m.empty()) {
            uint idx = m == "alias" ? 1 : m == "opt_string" ? 2 : m == "index" ? 3 : m == "pool" ? 4 : m == "hash" ? 5 :
                m == "builtin" ? 6 : m == "command" ? 12 : m == "dirname" ? 13 : m == "disabled" ? 13 : m == "enabled" ? 5 : m == "export" ? libcompspec.CI_EXPORT :
                m == "filename" ? libcompspec.CI_FILE : m == "function" ? libcompspec.CI_FUNCTION : m == "group" ? libcompspec.CI_GROUP :
                m == "user" ? libcompspec.CI_USER : m == "variable" ? libcompspec.CI_VARIABLE :
                m == "dir_stack" ? libcompspec.CI_DIRECTORY : m == "hostname" ? libcompspec.CI_HOSTNAME : m == "job" ? libcompspec.CI_JOB :
                m == "keyword" ? libcompspec.CI_KEYWORD : m == "running" ? libcompspec.CI_RUNNING : m == "service" ? libcompspec.CI_SERVICE :
                m == "setopt" ? libcompspec.CI_SETOPT : m == "shopt" ? libcompspec.CI_SHOPT : m == "signal" ? libcompspec.CI_SIGNAL : m == "stopped" ? libcompspec.CI_STOPPED : 0;

            (uint8 index, ) = libcompspec.option_map_index(m);
            if (index > 0) {
                s_sbuf s;
                page = sv.vmem[1].vm_pages[idx - 1];
                s.sbuf_new(page, page.byteLength(), 0);
                s.sbuf_finish();
                s_of f = s_of(0, io.SRD, 0, m, 0, s);
                p.p_fd.fdt_ofiles.push(f);
                p.p_fd.fdt_nfiles++;
                if (index + libcompspec.CI_HELPTOPIC >= e.e_ofiles.length)
                    e.e_ofiles.push(f);
                else
                    e.e_ofiles[index + libcompspec.CI_HELPTOPIC] = f;
            } else
                p.perror(m + " not found");
        }
        sv.cur_proc = p;
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"enable",
"[-a] [-dnps] [-f filename] [name ...]",
"Enable and disable shell builtins.",
"Enables and disables builtin shell commands.  Disabling allows you to execute a disk command which has the same\n\
name as a shell builtin without using a full pathname.",
"-a        print a list of builtins showing whether or not each is enabled\n\
-n        disable each NAME or display a list of disabled builtins\n\
-p        print the list of builtins in a reusable format\n\
-s        print only the names of Posix `special' builtins\n\n\
Options controlling dynamic loading:\n\
-f        Load builtin NAME from shared object FILENAME\n\
-d        Remove a builtin loaded with -f\n\n\
Without options, each NAME is enabled.",
"To use the `test' found in $PATH instead of the shell builtin version, type `enable -n test'.",
"Returns success unless NAME is not a shell builtin or an error occurs.");
    }
}
