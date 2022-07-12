pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "libcompspec.sol";
import "vars.sol";

contract enable is pbuiltin_base {

    using sbuf for s_sbuf;

    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = e.params();
        uint8[] pages;
        (bool f_load, bool f_disable, bool f_unload, bool f_posix_only, bool f_print, bool f_print_all, , ) = p.flag_values("fndspa");
        bool do_print = e.flags_empty() || f_print || f_print_all;
        bool do_modify = f_disable || f_posix_only;
        bool print_all = f_print_all;
        bool do_load = f_load || f_unload;
        string sattrs;
        bytes battrs = bytes("fnds");
        for (byte b: battrs)
            if (p.flag_set(b))
                sattrs.append(bytes(b));
        sattrs = print_all ? "" : ("-" + (sattrs.empty() ? "-" : sattrs));
        if (do_print) {
            for (uint8 n: pages) {
                string[] page_in = e.environ[n];
                if (params.empty()) {
                    for (string line: page_in) {
                        (string attrs, string name, ) = vars.split_var_record(line);
                        if (vars.match_attr_set(sattrs, attrs))
                            res.fputs("enable " + name);
                    }
                }
                for (string param: params) {
                    string cur_record = vars.val(param, page_in);
                    if (!cur_record.empty()) {
                        (string cur_attrs, ) = cur_record.csplit(" ");
                        if (vars.match_attr_set(sattrs, cur_attrs))
                            res.fputs("enable " + param);
                    } else
                        res.fputs(param + " not found");
                }
            }
//                res = _print(p, res, params, e.environ[n], print_all);
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        }

        if (do_modify) {
            for (string param: params)
                e.environ[sh.BUILTIN] = vars.set_var_attr(sattrs, param, e.environ[sh.BUILTIN]);
        }
        if (do_load) {
            e.puts("Loading...");
            string m = e.opt_value("f");
            if (!m.empty()) {
                uint idx;/* = m == "alias" ? 1 : m == "opt_string" ? 2 : m == "index" ? 3 : m == "pool" ? 4 : m == "hash" ? 5 :
                m == "builtin" ? 6 : m == "command" ? 12 : m == "dirname" ? 13 : m == "disabled" ? 13 : m == "enabled" ? 5 : m == "export" ? libcompspec.CI_EXPORT :
                m == "filename" ? libcompspec.CI_FILE : m == "function" ? libcompspec.CI_FUNCTION : m == "group" ? libcompspec.CI_GROUP :
                m == "user" ? libcompspec.CI_USER : m == "variable" ? libcompspec.CI_VARIABLE :
                m == "dir_stack" ? libcompspec.CI_DIRECTORY : m == "hostname" ? libcompspec.CI_HOSTNAME : m == "job" ? libcompspec.CI_JOB :
                m == "keyword" ? libcompspec.CI_KEYWORD : m == "running" ? libcompspec.CI_RUNNING : m == "service" ? libcompspec.CI_SERVICE :
                m == "setopt" ? libcompspec.CI_SETOPT : m == "shopt" ? libcompspec.CI_SHOPT : m == "signal" ? libcompspec.CI_SIGNAL : m == "stopped" ? libcompspec.CI_STOPPED : 0;*/
                (uint8 index, ) = (0, 0);//libcompspec.option_map_index(m);
                if (index > 0) {
                    s_sbuf s;
                    string text = sv.vmem[1].vm_pages[idx - 1];
                    s.sbuf_new(text, text.byteLength(), 0);
                    s.sbuf_finish();
                    s_of f = s_of(0, io.SRD, 0, m, 0, s);
                    p.p_fd.fdt_ofiles.push(f);
                    p.p_fd.fdt_nfiles++;
                    if (index + sh.HELPTOPIC >= e.ofiles.length)
                        e.ofiles.push(f);
                    else
                        e.ofiles[index + sh.HELPTOPIC] = f;
                } else
                    e.perror(m + " not found");
            }
            e.puts("Updated env: " + e.print_shell_env());
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
