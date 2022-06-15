pragma ton-solidity >= 0.61.1;

import "pbuiltin_special.sol";

contract declare is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc p) internal pure override returns (mapping (uint8 => string) pages) {
        if (p.flag_set("f"))
            pages[9] = e.e_functions;
        else
            pages[8] = e.e_vars;
    }

    function _update_shell_env(shell_env e_in, uint8 n, string page) internal pure override returns (shell_env e) {
        e = e_in;
        if (n == 8)
            e.e_vars = page;
        else if (n == 9)
            e.e_functions = page;
//        e.e_exports.append(page);
    }

    function _print(s_proc p_in, string[] params, string page) internal pure override returns (s_proc p) {
        p = p_in;

        bool function_names_only = p.flag_set("F");

        string sattrs;
        string[] a_attrs = ["a", "A", "x", "i", "r", "t", "n", "f"];
        for (string attr: a_attrs)
            if (p.flag_set(attr))
                sattrs.append(attr);
        if (function_names_only)
            sattrs.append("-f");
        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);

        if (params.empty()) {
            (string[] lines, ) = page.split("\n");
            for (string line: lines) {
                (string attrs, string name, string value) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    p.puts(p.flags_empty() ?
                        (name + "=" + value) :
                        vars.print_reusable(line));
            }
        }
        for (string param: params) {
            string cur_record = vars.get_pool_record(param, page);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    p.puts(vars.print_reusable(cur_record));
            } else
                p.perror(param + ": not found");
        }
    }

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        page = page_in;
        string sattrs;
        string[] a_attrs = ["a", "A", "x", "i", "r", "t", "n", "f"];
        for (string attr: a_attrs)
            if (p.flag_set(attr))
                sattrs.append(attr);
        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);
        for (string param: params)
            page = vars.set_var(sattrs, param, page);
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
