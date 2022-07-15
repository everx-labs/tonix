pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract declare is pbuiltin_special {

    function _retrieve_pages(shell_env e) internal pure override returns (uint8) {
        return e.flag_set("f") ? sh.FUNCTION : sh.VARIABLE;
    }

    function _attr_set(shell_env e) internal pure override returns (string sattrs) {
        bytes battrs = "aAxirtnf";
        for (byte b: battrs)
            if (e.flag_set(b))
                sattrs.append(bytes(b));
    }
    function _print_record(string record) internal pure override returns (string) {
        return vars.print_reusable(record);
    }

    function _name() internal pure override returns (string) {
        return "declare";
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
