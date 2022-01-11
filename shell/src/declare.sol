pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract declare is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, string argv) = _get_args(e[IS_ARGS]);
        string dbg = argv;
        bool function_names_only = _flag_set("F", flags);

        string s_attrs;
        string[] a_attrs = ["a", "A", "x", "i", "r", "t", "n", "f"];
        for (string attr: a_attrs)
            if (_flag_set(attr, flags))
                s_attrs.append(attr);

        s_attrs = "-" + (s_attrs.empty() ? "-" : s_attrs);
        bool print_reusable = _flag_set("p", flags) || function_names_only;

        string pool = e[IS_POOL];
        if (params.empty()) {
            (string[] lines, ) = _split(pool, "\n");
            for (string line: lines) {
                (string attrs, ) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs))
                    out.append(_print_reusable(line));
            }
        }
        if (print_reusable) {
            for (string p: params) {
                (string name, ) = _strsplit(p, "=");
                string cur_record = _get_pool_record(name, pool);
                if (!cur_record.empty()) {
                    (string cur_attrs, ) = _strsplit(cur_record, " ");
                    if (_match_attr_set(s_attrs, cur_attrs))
                        out.append(_print_reusable(cur_record));
                } else {
                    ec = EXECUTE_FAILURE;
                    out.append("declare: " + name + " not found\n");
                }
            }
        } else {
            for (string p: params)
                pool = _set_var(s_attrs, p, pool);
        }
        if (pool != e[IS_POOL])
            wr.push(Write(IS_POOL, pool, O_WRONLY));

        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
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
