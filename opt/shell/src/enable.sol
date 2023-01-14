pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "libcompspec.sol";
import "vars.sol";

contract enable is pbuiltin_base {

    using sbuf for s_sbuf;
    using vars for string[];

    function main(shell_env e_in, job_cmd cc_in) external pure returns (shell_env e) {
        e = e_in;
        string[] params = cc_in.params();
        bool no_args = params.empty();
        (bool f_load, bool f_disable, bool f_unload, bool f_posix_only, bool f_print, bool f_print_all, , ) = cc_in.flag_values("fndspa");
        bool do_print = (cc_in.flags_empty() && no_args) || f_print || f_print_all;
        bool do_modify = cc_in.flags_empty() && !no_args;
        bool print_all = f_print_all;
        bool do_load = f_load || f_unload;
        string sattrs = f_disable ? "n" : "-";
        if (f_posix_only)
            sattrs.append('s');
        sattrs = "-" + sattrs;
        string[] page = e.environ[f_disable ? sh.DISABLED : print_all ? sh.BUILTIN : sh.ENABLED];
        if (no_args) {
            e.puts(_print_line(vars.filter(page, sattrs, "", false, false), print_all));
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
        if (do_load) {

        }
    }

    function _print_line(string[] lines, bool print_reusable) internal pure returns (string res) {
        for (string line: lines) {
            (string attrs, string name, ) = vars.split_var_record(line);
            res.append("enable " + (print_reusable && str.strchr(attrs, 'n') > 0 ? "-n " : "") + name + "\n");
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
