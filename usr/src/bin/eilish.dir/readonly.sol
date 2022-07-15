pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract readonly is pbuiltin_special {

    function _retrieve_pages(shell_env e) internal pure override returns (uint8) {
        return e.flag_set("f") ? sh.FUNCTION : sh.VARIABLE;
    }

    function _attr_set(shell_env e) internal pure override returns (string sattrs) {
        sattrs = "-r";
        if (e.flag_set("f"))
            sattrs.append("f");
    }
    function _print_record(string record) internal pure override returns (string) {
        return vars.print_reusable(record);
    }
    function _name() internal pure override returns (string) {
        return "readonly";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"readonly",
"[-aAf] [name[=value] ...] or readonly -p",
"Mark shell variables as unchangeable.",
"Mark each NAME as read-only; the values of these NAMEs may not be changed by subsequent assignment.\n\
If VALUE is supplied, assign VALUE before marking as read-only.",
"-a        refer to indexed array variables\n\
-A        refer to associative array variables\n\
-f        refer to shell functions\n\
-p        display a list of all readonly variables or functions, depending on whether or not the -f option is given",
"An argument of `--' disables further option processing.",
"Returns success unless an invalid option is given or NAME is invalid.");
    }
}
