pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract enable is Shell {

    function run_builtin(string args, string pool) external pure returns (uint8 ec, string out, string res) {
        (string[] params, string flags, ) = arg.get_args(args);

        string page = pool;

        (bool load, bool disable, bool unload, bool print_reusable, bool print_all, bool posix_only, , ) = arg.flag_values("fndpas", flags);
        bool print = print_all || print_reusable || posix_only || params.empty();

        string s_attrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                s_attrs.append(attr);

        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);
        ec = EXECUTE_SUCCESS;
        if (print) {
            (string[] lines, ) = stdio.split(page, "\n");
            for (string line: lines) {
                (string attrs, string stmt) = stdio.strsplit(line, " ");
                if (vars.match_attr_set(s_attrs, attrs)) {
                    (string name, ) = stdio.strsplit(stmt, "=");
                    out.append("enable " + vars.unwrap(name) + "\n");
                }
            }
        } else {
            for (string arg: params)
                page = _set_var(s_attrs, arg, page);
            res = page;
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
