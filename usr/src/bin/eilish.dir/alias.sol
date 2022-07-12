pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract alias_ is pbuiltin_special {

    function _retrieve_pages(shell_env) internal pure override returns (uint8[]) {
        return [sh.ALIAS];
    }

    function _attr_set(shell_env) internal pure override returns (string sattrs) {
        return "";
    }

    function _print_record(string record) internal pure override returns (string) {
        (, string name, string value) = vars.split_var_record(record);
        return "alias " + name + "=\'" + value + "\'";
    }

    function _name() internal pure override returns (string) {
        return "alias";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"alias",
"[-p] [name[=value] ... ]",
"Define or display aliases.",
"Without arguments, `alias' prints the list of aliases in the reusable form `alias NAME=VALUE' on standard output.\n\
Otherwise, an alias is defined for each NAME whose VALUE is given. A trailing space in VALUE causes the next word\n\
to be checked for alias substitution when the alias is expanded.",
"-p        print all defined aliases in a reusable format",
"",
"alias returns true unless a NAME is supplied for which no alias has been defined.");
    }
}
