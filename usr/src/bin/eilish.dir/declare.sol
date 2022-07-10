pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract declare is pbuiltin_special {

    function _retrieve_pages(s_proc p) internal pure override returns (uint8[]) {
        return [p.flag_set("f") ? sh.FUNCTION : sh.VARIABLE];
    }

    function _print(s_proc p, s_of f, string[] page) internal pure override returns (s_of res) {
        res = f;
        bool function_names_only = p.flag_set("F");

        string sattrs;
        bytes battrs = bytes("aAxirtnf");
        for (byte b: battrs)
            if (p.flag_set(b))
                sattrs.append(bytes(b));
        if (function_names_only)
            sattrs.append("-f");
        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);

        if (p.params().empty()) {
            for (string line: page) {
                (string attrs, string name, string value) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    res.fputs(p.flags_empty() ?
                        (name + "=" + value) :
                        vars.print_reusable(line));
            }
        }
        for (string param: p.params()) {
            string cur_record = vars.get_pool_record(param, page);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    res.fputs(vars.print_reusable(cur_record));
            } else
                res.fputs(param + ": not found");
        }
    }

    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        page = page_in;
        string sattrs;
        bytes battrs = bytes("aAxirtnf");
        for (byte b: battrs)
            if (p.flag_set(b))
                sattrs.append(bytes(b));
        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);
        for (string param: p.params())
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
