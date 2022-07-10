pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract unalias is pbuiltin_special {

    function _retrieve_pages(s_proc) internal pure override returns (uint8[]) {
        return [sh.ALIAS];
    }

    function _print(s_proc, s_of f, string[]) internal pure override returns (s_of res) {
        res = f;
    }

    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        if (!p.flag_set("a")) {
            page = page_in;
            for (string param: p.params())
                page = vars.unset_var(param, page);
        }
    }

function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"unalias",
"[-a] name [name ...]",
"Remove each NAME from the list of defined aliases.",
"",
"-a        remove all alias definitions",
"",
"Return success unless a NAME is not an existing alias.");
    }
}
