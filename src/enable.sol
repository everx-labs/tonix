pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract enable is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        (bool print_reusable, bool print_all, bool posix_only, , , , , ) = arg.flag_values("pas", flags);

        string s_attrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                s_attrs.append(attr);

        s_attrs = print_all ? "" : ("-" + (s_attrs.empty() ? "-" : s_attrs));

        if (params.empty()) {
            (string[] lines, ) = stdio.split(pool, "\n");
            for (string line: lines) {
                (string attrs, string name, string value) = vars.split_var_record(line);
//                (string attrs, ) = str.split(line, " ");
                if (vars.match_attr_set(s_attrs, attrs))
                    out.append("enable " + name + "\n");
            }
        }
        for (string p: params) {
            (string name, ) = str.split(p, "=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = str.split(cur_record, " ");
                if (vars.match_attr_set(s_attrs, cur_attrs))
                    out.append("enable " + name + "\n");
            } else {
                ec = EXECUTE_FAILURE;
                out.append("enable: " + name + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
//        (bool load, bool disable, bool unload, bool posix_only, , , , ) = arg.flag_values("fnds", flags);

        string page = pool;
        string s_attrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                s_attrs.append(attr);

        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);
        ec = EXECUTE_SUCCESS;

        for (string p: params)
            page = vars.set_var_attr(s_attrs, p, page);
        res = page;
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
