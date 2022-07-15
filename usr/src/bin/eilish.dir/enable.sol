pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "libcompspec.sol";
import "vars.sol";

contract enable is pbuiltin_base {

    using sbuf for s_sbuf;
    using vars for string[];

    function main(shell_env e_in) external pure returns (shell_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = e.params();
        (bool f_load, bool f_disable, bool f_unload, bool f_posix_only, bool f_print, bool f_print_all, , ) = e.flag_values("fndspa");
        bool do_print = (e.flags_empty() && params.empty()) || f_print || f_print_all;
        bool do_modify = e.flags_empty() && !params.empty();
        bool print_all = f_print_all;
        bool do_load = f_load || f_unload;
        string sattrs = f_disable ? "n" : "-";
        if (f_posix_only)
            sattrs.append('s');
//        bytes battrs = bytes("ns");
        /*for (byte b: battrs)
            if (e.flag_set(b))
                sattrs.append(bytes(b));*/
        sattrs = "-" + sattrs;
//        string a_name = print_all ? "builtin" : f_disable ? "disabled" : "enabled";
        if (do_print) {
            string[] page = e.environ[sh.BUILTIN];
            for (string line: page) {
                (string attrs, string name, string value) = vars.split_var_record(line);
                if (print_all)
                    res.fputs("enable " + (str.strchr(attrs, 'n') > 0 ? "-n " : "") + name);
                else {
                    if (vars.match_attr_set(sattrs, attrs))
                        res.fputs("enable " + name);
                }
            }
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        }
        if (do_modify) {
            for (string param: params) {
                if (f_disable) {
                    e.environ[sh.ARRAYVAR].array_remove("enabled", param);
                    e.environ[sh.ARRAYVAR].array_add("disabled", param);
                } else {
                    e.environ[sh.ARRAYVAR].array_remove("disabled", param);
                    e.environ[sh.ARRAYVAR].array_add("enabled", param);
                }
            }
        }
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
