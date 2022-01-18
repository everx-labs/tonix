pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract enable is Shell {

    function run_builtin(string args, string pool) external pure returns (uint8 ec, string out, string res) {
        (string[] params, string flags, ) = _get_args(args);

//    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
//        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
//        uint16 page_index = IS_BUILTIN;
        string page = pool;

        (bool load, bool disable, bool unload, bool print_reusable, bool print_all, bool posix_only, , ) = _flag_values("fndpas", flags);
        /*bool load = _flag_set("f", flags);
        bool disable = _flag_set("n", flags);
        bool unload = _flag_set("d", flags);

        bool print_reusable = params.empty() || _flag_set("p", flags);
        bool print_all = _flag_set("a", flags);
        bool posix_only = _flag_set("s", flags);*/
        bool print = print_all || print_reusable || posix_only || params.empty();

        string s_attrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (_flag_set(attr, flags))
                s_attrs.append(attr);

        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);
        ec = EXECUTE_SUCCESS;
        if (print) {
            (string[] lines, ) = _split(page, "\n");
            for (string line: lines) {
                (string attrs, string stmt) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs)) {
                    (string name, ) = _strsplit(stmt, "=");
                    out.append("enable " + _unwrap(name) + "\n");
                }
            }
        } else {
//            string s_attrs = disable ? "-n" : load ? "-f" : unload ? "+f" : "";
//            string s_new_attrs = s_attrs.empty() ? "--" : s_attrs;
//            string s_exists_attrs = s_attrs.empty() ? "+n" : s_attrs;
            for (string arg: params)
                page = _set_var(s_attrs, arg, page);
            res = page;
        }
                /*_parse_var(item);
                if (_strchr(attrs, "n") == 0 && !(posix_only && _strchr(attrs, "s") == 0))
                    res.append("enable " + name + "\n");
                else if (print_all)
                    res.append("enable " + item + "\n");
            }
            env[IS_STDOUT] = res;
        } else if (params.empty()) {
            (string[] items, ) = _split_line(page, "\n", "\n");
            for (string item: items) {
                (string attrs, string name, ) = _parse_var(item);
                if (_strchr(attrs, "n") == 0)
                    res.append("enable " + name + "\n");
            }
            env[IS_STDOUT] = res;
        } else {
//            (string[] args, ) = _split(s_args, " ");
            string s_attrs = disable ? "-n" : load ? "-f" : unload ? "+f" : "";
            string s_new_attrs = s_attrs.empty() ? "--" : s_attrs;
            string s_exists_attrs = s_attrs.empty() ? "+n" : s_attrs;
            for (string arg: params) {
                (, , string line) = _fetch_var(arg, page);
//                page = _assign(line.empty() ? s_new_attrs : s_exists_attrs, arg, page);
            }
            env[page_index] = page;
        }*/
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
