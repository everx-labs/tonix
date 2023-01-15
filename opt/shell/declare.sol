pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract declare is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        (bool funcs, bool func_names, bool print_reusable, , , , , ) = cc.flag_values("fFp");
        uint8 pg = funcs ? sh.FUNCTION : sh.VARIABLE;
        string[] params = cc.params();
        bool no_args = params.empty();
        string[] page = e.environ[pg];
        string[] res;
        bool print = no_args || print_reusable;
        bytes battrs = "aAxirtnf";
        byte ba;
        for (byte b: battrs)
            if (cc.flag_set(b)) {
                ba = b;
                break;
            }
        string sattrs = uint8(ba) == 0 ? "-" : bytes(ba);
        if (params.empty()) {
            res = vars.gen_records(page, ba, "");
            e.puts(_print_line(res, print_reusable));
        } else {
            for (string p: params) {
                if (print) {
                    res = vars.gen_records(page, ba, p);
                    if (!res.empty())
                        e.puts(_print_line(res, print_reusable));
                    else
                        e.perror(p);
                } else
                    page.set_var(sattrs, p);
            }
            if (!print)
                e.environ[pg] = page;
        }
    }

    function _print_line(string[] lines, bool print_reusable) internal pure returns (string res) {
        for (string line: lines) {
            if (print_reusable)
                res.append("declare " + line + "\n");
            else {
                (string attrs, string name, string value) = vars.split_var_record(line);
                res.append(name + "=" + value + "\n");
            }
        }
    }

    function _name() internal pure override returns (string) {
        return "declare";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
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
