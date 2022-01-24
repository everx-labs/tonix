pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract declare is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool function_names_only = arg.flag_set("F", flags);

        string s_attrs;
        string[] a_attrs = ["a", "A", "x", "i", "r", "t", "n", "f"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                s_attrs.append(attr);
        if (function_names_only)
            s_attrs.append("-f");
        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);

        if (params.empty()) {
            (string[] lines, ) = stdio.split(pool, "\n");
            for (string line: lines) {
                (string attrs, string name, string value) = vars.split_var_record(line);
                if (vars.match_attr_set(s_attrs, attrs))
                    out.append(flags.empty() ?
                        (name + "=" + value + "\n") :
                        vars.print_reusable(line));
            }
        }
        for (string p: params) {
            string cur_record = vars.get_pool_record(p, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = stdio.strsplit(cur_record, " ");
                if (vars.match_attr_set(s_attrs, cur_attrs))
                    out.append(vars.print_reusable(cur_record));
            } else {
                ec = EXECUTE_FAILURE;
                out.append("declare: " + p + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        string page = pool;
        string s_attrs;
        string[] a_attrs = ["a", "A", "x", "i", "r", "t", "n", "f"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                s_attrs.append(attr);
        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);
        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = _set_var(s_attrs, p, page);
        res = page;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"declare",
"[-aAfFgilnrtux] [-p] [name[=value] ...]",
"Set variable values and attributes.",
"Declare variables and give them attributes.  If no NAMEs are given, display the attributes and values of all variables.",
"-f        restrict action or display to function names and definitions\n\
-F        restrict display to function names only (plus line number and source file when debugging)\n\
-g        create global variables when used in a shell function; otherwise ignored\n\
-p        display the attributes and value of each NAME\n\n\
Options which set attributes:\n\
-a        to make NAMEs indexed arrays (if supported)\n\
-A        to make NAMEs associative arrays (if supported)\n\
-i        to make NAMEs have the `integer' attribute\n\
-l        to convert the value of each NAME to lower case on assignment\n\
-n        make NAME a reference to the variable named by its value\n\
-r        to make NAMEs readonly\n\
-t        to make NAMEs have the `trace' attribute\n\
-u        to convert the value of each NAME to upper case on assignment\n\
-x        to make NAMEs export\n\n\
Using `+' instead of `-' turns off the given attribute.",
"Variables with the integer attribute have arithmetic evaluation (see the `let' command) performed when the variable is assigned a value.\n\
When used in a function, `declare' makes NAMEs local, as with the `local' command.  The `-g' option suppresses this behavior.",
"Returns success unless an invalid option is supplied or a variable assignment error occurs.");
    }
}
